#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
cd "$PROJECT_DIR"

MODE=${1:-development}
EXPECTED_BUNDLE_ID='com.hinoshiba.stagepane'
RELEASE_CHECK_TEMP=''

cleanup_release_check_temp() {
    if [[ -n "$RELEASE_CHECK_TEMP" && -d "$RELEASE_CHECK_TEMP" && \
          "$RELEASE_CHECK_TEMP" == /tmp/stagepane-release-check.* ]]; then
        rm -rf -- "$RELEASE_CHECK_TEMP"
    fi
}
trap cleanup_release_check_temp EXIT

if [[ "$MODE" != "development" && "$MODE" != "--distribution" && \
      "$MODE" != "distribution" && "$MODE" != "--app-store" && \
      "$MODE" != "app-store" && "$MODE" != "--verify-release-source" ]]; then
    print -u2 "Usage: $0 [development|--distribution|--app-store|--verify-release-source]"
    exit 64
fi

if [[ "$MODE" == "--distribution" || "$MODE" == "distribution" || \
      "$MODE" == "--app-store" || "$MODE" == "app-store" || \
      "$MODE" == "--verify-release-source" ]]; then
    if [[ -z "${STAGEPANE_RELEASE_COMMIT:-}" ]]; then
        print -u2 "STAGEPANE_RELEASE_COMMIT is required for a release build"
        exit 70
    fi
    if [[ ! "$STAGEPANE_RELEASE_COMMIT" =~ '^[0-9a-f]{40}$' ]]; then
        print -u2 "STAGEPANE_RELEASE_COMMIT must be a full lowercase 40-hex Git commit SHA"
        exit 70
    fi

    HEAD_COMMIT=$(/usr/bin/git rev-parse --verify 'HEAD^{commit}')
    if [[ "$STAGEPANE_RELEASE_COMMIT" != "$HEAD_COMMIT" ]]; then
        print -u2 "Release commit does not match HEAD"
        print -u2 "Expected HEAD: $HEAD_COMMIT"
        exit 70
    fi

    WORKTREE_STATUS=$(/usr/bin/git status --porcelain=v1 --untracked-files=all \
        --ignore-submodules=none)
    if [[ -n "$WORKTREE_STATUS" ]]; then
        print -u2 "Release builds require a clean Git worktree"
        print -u2 "Commit or remove staged, tracked, and nonignored untracked changes"
        exit 70
    fi

    # SwiftPM recursively discovers source and test files. Reject ignored files
    # in build-input trees so an ignored nested file cannot enter a release.
    IGNORED_BUILD_INPUTS=$(/usr/bin/git ls-files --others --ignored \
        --exclude-standard -- Sources Tests Resources Assets Config docs)
    if [[ -n "$IGNORED_BUILD_INPUTS" ]]; then
        print -u2 "Release build-input directories contain ignored files"
        print -u2 "Remove ignored files from Sources, Tests, Resources, Assets, Config, and docs"
        exit 70
    fi
fi

if [[ "$MODE" == "--verify-release-source" ]]; then
    print "Release source state matches $STAGEPANE_RELEASE_COMMIT"
    exit 0
fi

/usr/bin/plutil -lint Info.plist StagePane.entitlements Resources/PrivacyInfo.xcprivacy
/bin/zsh -n build.sh Scripts/*.sh
EXPECTED_ENTITLEMENTS_JSON='{"com.apple.security.app-sandbox":true}'
ACTUAL_ENTITLEMENTS_JSON=$(/usr/bin/plutil -convert json -o - StagePane.entitlements)
if [[ "$ACTUAL_ENTITLEMENTS_JSON" != "$EXPECTED_ENTITLEMENTS_JSON" ]]; then
    print -u2 "StagePane.entitlements must contain only com.apple.security.app-sandbox=true"
    exit 70
fi

if [[ "$MODE" == "--distribution" || "$MODE" == "distribution" || \
      "$MODE" == "--app-store" || "$MODE" == "app-store" ]]; then
    RELEASE_CHECK_TEMP=$(mktemp -d /tmp/stagepane-release-check.XXXXXX)
    swift test --scratch-path "$RELEASE_CHECK_TEMP"
else
    swift test
fi
"$PROJECT_DIR/Scripts/check-xcodegen-drift.sh"

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' Info.plist)
if [[ "$BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
    print -u2 "Unexpected bundle identifier in Info.plist: $BUNDLE_ID"
    print -u2 "Expected: $EXPECTED_BUNDLE_ID"
    exit 70
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist)
if [[ ${#VERSION} -gt 32 || ! "$VERSION" =~ '^[0-9]+([.][0-9]+){0,2}$' ]]; then
    print -u2 "Refusing invalid CFBundleShortVersionString: $VERSION"
    exit 70
fi
if [[ ${#BUILD_NUMBER} -gt 32 || \
      ! "$BUILD_NUMBER" =~ '^[0-9]+([.][0-9]+){0,2}$' ]]; then
    print -u2 "Refusing invalid CFBundleVersion: $BUILD_NUMBER"
    exit 70
fi

for required in LICENSE NOTICE THIRD_PARTY_NOTICES.md TRADEMARKS.md \
    Assets/LICENSE.md docs/PRIVACY.md docs/LICENSE_AUDIT.md \
    docs/HELP.md docs/sbom.spdx.json Config/XcodeGen.lock SECURITY.md \
    Scripts/signing-identity.sh; do
    if [[ ! -s "$required" ]]; then
        print -u2 "Missing required release document: $required"
        exit 70
    fi
done

if grep -R -n -E 'CGVirtualDisplay|com\.apple\.security\.screen-capture' Sources StagePane.entitlements; then
    print -u2 "Private display API or invalid screen-capture entitlement detected"
    exit 70
fi

if grep -R -n -E 'URLSession|NWConnection|Network\.framework|AVAssetWriter|SCRecordingOutput' Sources; then
    print -u2 "Network or recording path detected; privacy/license review required"
    exit 70
fi

PACKAGE_COUNT=$(swift package show-dependencies --format json | grep -c '"identity"' || true)
if [[ "$PACKAGE_COUNT" -gt 1 ]]; then
    print -u2 "Package dependency graph changed; update license audit, notices, and SBOM"
    exit 70
fi

if ! grep -F -q "StagePane-$VERSION-SBOM" docs/sbom.spdx.json; then
    print -u2 "SBOM version does not match Info.plist ($VERSION)"
    exit 70
fi

if [[ "$MODE" == "--distribution" || "$MODE" == "distribution" || \
      "$MODE" == "--app-store" || "$MODE" == "app-store" ]]; then
    PLACEHOLDER_TOKENS=(
        RELEASE_REPOSITORY_URL_PLACEHOLDER
        RELEASE_TRADEMARK_OWNER_PLACEHOLDER
        RELEASE_CONTACT_PLACEHOLDER
        RELEASE_SECURITY_CONTACT_PLACEHOLDER
        RELEASE_SUPPORT_CONTACT_PLACEHOLDER
        RELEASE_CONDUCT_CONTACT_PLACEHOLDER
        RELEASE_GITHUB_OWNER_PLACEHOLDER
    )
    PLACEHOLDER_PATHS=(
        README.md TRADEMARKS.md docs SECURITY.md SUPPORT.md
        CODE_OF_CONDUCT.md .github
    )
    PLACEHOLDERS_FOUND=0
    for token in "${PLACEHOLDER_TOKENS[@]}"; do
        if grep -R -F -n "$token" "${PLACEHOLDER_PATHS[@]}"; then
            PLACEHOLDERS_FOUND=1
        fi
    done
    if [[ "$PLACEHOLDERS_FOUND" -ne 0 ]]; then
        print -u2 "Distribution blocked until legal/support contact placeholders are replaced"
        exit 70
    fi
fi

if [[ "$MODE" == "--app-store" || "$MODE" == "app-store" ]]; then
    : "${STAGEPANE_APPSTORE_BUNDLE_ID:?Set STAGEPANE_APPSTORE_BUNDLE_ID to com.hinoshiba.stagepane}"
    if [[ "$STAGEPANE_APPSTORE_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
        print -u2 "Unexpected App Store bundle identifier: $STAGEPANE_APPSTORE_BUNDLE_ID"
        print -u2 "Expected: $EXPECTED_BUNDLE_ID"
        exit 70
    fi
    for required in project.yml StagePane.xcodeproj/project.pbxproj \
        Config/StagePane-AppStore-Info.plist Scripts/archive-app-store.sh; do
        if [[ ! -s "$required" ]]; then
            print -u2 "Missing Mac App Store build input: $required"
            exit 70
        fi
    done
fi

print "Release checks passed for $MODE mode"
