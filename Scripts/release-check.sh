#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
cd "$PROJECT_DIR"

MODE=${1:-development}

if [[ "$MODE" != "development" && "$MODE" != "--distribution" && \
      "$MODE" != "distribution" && "$MODE" != "--app-store" && \
      "$MODE" != "app-store" ]]; then
    print -u2 "Usage: $0 [development|--distribution|--app-store]"
    exit 64
fi

swift test
plutil -lint Info.plist StagePane.entitlements Resources/PrivacyInfo.xcprivacy
"$PROJECT_DIR/Scripts/check-xcodegen-drift.sh"

for required in LICENSE NOTICE THIRD_PARTY_NOTICES.md TRADEMARKS.md \
    Assets/LICENSE.md docs/PRIVACY.md docs/LICENSE_AUDIT.md \
    docs/HELP.md docs/sbom.spdx.json Config/XcodeGen.lock SECURITY.md; do
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

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' StagePane.entitlements 2>/dev/null || true)" != "true" ]]; then
    print -u2 "App Sandbox entitlement is missing or false"
    exit 70
fi

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.network.client' StagePane.entitlements 2>/dev/null || true)" == "true" ]]; then
    print -u2 "Network client entitlement requires a new privacy review"
    exit 70
fi

PACKAGE_COUNT=$(swift package show-dependencies --format json | grep -c '"identity"' || true)
if [[ "$PACKAGE_COUNT" -gt 1 ]]; then
    print -u2 "Package dependency graph changed; update license audit, notices, and SBOM"
    exit 70
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
if ! grep -q "StagePane-$VERSION-SBOM" docs/sbom.spdx.json; then
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

if [[ "$MODE" == "--distribution" || "$MODE" == "distribution" ]]; then
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' Info.plist)
    if [[ "$BUNDLE_ID" == "app.stagepane.StagePane" ]]; then
        print -u2 "Distribution blocked until bundle ID uses a publisher-controlled domain"
        exit 70
    fi
fi

if [[ "$MODE" == "--app-store" || "$MODE" == "app-store" ]]; then
    : "${STAGEPANE_APPSTORE_BUNDLE_ID:?Set STAGEPANE_APPSTORE_BUNDLE_ID to a publisher-controlled App ID}"
    if [[ "$STAGEPANE_APPSTORE_BUNDLE_ID" == "app.stagepane.StagePane" ]] || \
       ! print -r -- "$STAGEPANE_APPSTORE_BUNDLE_ID" | \
           grep -qE '^[A-Za-z0-9][A-Za-z0-9-]*(\.[A-Za-z0-9][A-Za-z0-9-]*)+$'; then
        print -u2 "App Store bundle ID is unconfigured or malformed"
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
