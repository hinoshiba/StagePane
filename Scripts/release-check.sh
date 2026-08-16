#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
cd "$PROJECT_DIR"

EXPECTED_BUNDLE_ID='com.hinoshiba.stagepane'
if [[ $# -ne 0 ]]; then
    print -u2 "Usage: $0"
    exit 64
fi

/usr/bin/plutil -lint Info.plist Config/StagePane-AppStore-Info.plist \
    StagePane.entitlements Resources/PrivacyInfo.xcprivacy
/bin/zsh -n build.sh Scripts/*.sh
/bin/sh -n ci_scripts/*.sh
EXPECTED_ENTITLEMENTS_JSON='{"com.apple.security.app-sandbox":true}'
ACTUAL_ENTITLEMENTS_JSON=$(/usr/bin/plutil -convert json -o - StagePane.entitlements)
if [[ "$ACTUAL_ENTITLEMENTS_JSON" != "$EXPECTED_ENTITLEMENTS_JSON" ]]; then
    print -u2 "StagePane.entitlements must contain only com.apple.security.app-sandbox=true"
    exit 70
fi

swift test
"$PROJECT_DIR/Scripts/check-xcodegen-drift.sh"

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Config/StagePane-AppStore-Info.plist)" != '$(MARKETING_VERSION)' || \
      "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Config/StagePane-AppStore-Info.plist)" != '$(CURRENT_PROJECT_VERSION)' ]]; then
    print -u2 'Config/StagePane-AppStore-Info.plist must inherit version/build from Xcode settings'
    exit 70
fi

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' Info.plist)
if [[ "$BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
    print -u2 "Unexpected bundle identifier in Info.plist: $BUNDLE_ID"
    print -u2 "Expected: $EXPECTED_BUNDLE_ID"
    exit 70
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist)
PROJECT_VERSION=$(awk '$1 == "MARKETING_VERSION:" { gsub(/"/, "", $2); print $2; exit }' project.yml)
if [[ ${#VERSION} -gt 32 || ! "$VERSION" =~ '^[0-9]+([.][0-9]+){0,2}$' ]]; then
    print -u2 "Refusing invalid CFBundleShortVersionString: $VERSION"
    exit 70
fi
if [[ ${#BUILD_NUMBER} -gt 32 || \
      ! "$BUILD_NUMBER" =~ '^[0-9]+([.][0-9]+){0,2}$' ]]; then
    print -u2 "Refusing invalid CFBundleVersion: $BUILD_NUMBER"
    exit 70
fi
if [[ "$PROJECT_VERSION" != "$VERSION" ]] || \
   ! grep -F -q "MARKETING_VERSION = $VERSION;" StagePane.xcodeproj/project.pbxproj; then
    print -u2 "Info.plist, project.yml, and the checked-in Xcode project must use version $VERSION"
    exit 70
fi
if ! grep -F -q 'DEVELOPMENT_TEAM = 94HVVWXLK3;' StagePane.xcodeproj/project.pbxproj || \
   ! grep -F -q 'PRODUCT_BUNDLE_IDENTIFIER = com.hinoshiba.stagepane;' StagePane.xcodeproj/project.pbxproj; then
    print -u2 "Checked-in Xcode project has an unexpected Team or bundle identifier"
    exit 70
fi

for required in LICENSE NOTICE THIRD_PARTY_NOTICES.md TRADEMARKS.md \
    Assets/LICENSE.md docs/PRIVACY.md docs/LICENSE_AUDIT.md \
    docs/HELP.md docs/sbom.spdx.json Config/XcodeGen.lock SECURITY.md \
    project.yml StagePane.xcodeproj/project.pbxproj \
    Config/StagePane-AppStore-Info.plist ci_scripts/ci_pre_xcodebuild.sh; do
    if [[ ! -s "$required" ]]; then
        print -u2 "Missing required release document: $required"
        exit 70
    fi
done
if [[ ! -x ci_scripts/ci_pre_xcodebuild.sh ]]; then
    print -u2 "Xcode Cloud pre-build script must be executable"
    exit 70
fi

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
    print -u2 "App Store release blocked until legal/support contact placeholders are replaced"
    exit 70
fi

print "Project and App Store source checks passed"
