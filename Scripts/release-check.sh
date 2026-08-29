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
/bin/sh -n Scripts/app-store-archive-guard.sh
ENTITLEMENT_KEY_COUNT=$(/usr/bin/plutil -p StagePane.entitlements | /usr/bin/grep -c ' => ')
if [[ "$ENTITLEMENT_KEY_COUNT" -ne 2 ]] || \
   [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' StagePane.entitlements)" != true ]] || \
   [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.files.user-selected.read-write' StagePane.entitlements)" != true ]]; then
    print -u2 "StagePane.entitlements must contain only the sandbox and user-selected read/write grants"
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
PROJECT_BUILD_NUMBER=$(awk '$1 == "CURRENT_PROJECT_VERSION:" { gsub(/"/, "", $2); print $2; exit }' project.yml)
PREVIOUS_UPLOADED_BUILD=$(awk '$1 == "STAGEPANE_PREVIOUS_UPLOADED_BUILD:" { gsub(/"/, "", $2); print $2; exit }' project.yml)
if [[ ${#VERSION} -gt 32 || ! "$VERSION" =~ '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$' ]]; then
    print -u2 "Refusing invalid CFBundleShortVersionString: $VERSION"
    exit 70
fi
if [[ ${#BUILD_NUMBER} -gt 18 || ! "$BUILD_NUMBER" =~ '^[1-9][0-9]*$' ]]; then
    print -u2 "Refusing invalid CFBundleVersion: $BUILD_NUMBER"
    exit 70
fi
if [[ "$PROJECT_VERSION" != "$VERSION" ]] || \
   [[ "$(sed -n 's/^[[:space:]]*MARKETING_VERSION = \([^;]*\);/\1/p' StagePane.xcodeproj/project.pbxproj | sort -u)" != "$VERSION" ]]; then
    print -u2 "Info.plist, project.yml, and the checked-in Xcode project must use version $VERSION"
    exit 70
fi
if [[ "$PROJECT_BUILD_NUMBER" != "$BUILD_NUMBER" ]] || \
   [[ ${#PREVIOUS_UPLOADED_BUILD} -gt 18 || ! "$PREVIOUS_UPLOADED_BUILD" =~ '^[1-9][0-9]*$' ]] || \
   (( BUILD_NUMBER <= PREVIOUS_UPLOADED_BUILD )) || \
   [[ "$(sed -n 's/^[[:space:]]*CURRENT_PROJECT_VERSION = \([^;]*\);/\1/p' StagePane.xcodeproj/project.pbxproj | sort -u)" != "$BUILD_NUMBER" ]] || \
   [[ "$(sed -n 's/^[[:space:]]*STAGEPANE_PREVIOUS_UPLOADED_BUILD = \([^;]*\);/\1/p' StagePane.xcodeproj/project.pbxproj | sort -u)" != "$PREVIOUS_UPLOADED_BUILD" ]]; then
    print -u2 "Info.plist, project.yml, and the checked-in Xcode project must use a build greater than the recorded App Store floor"
    exit 70
fi
if ! grep -F -q 'DEVELOPMENT_TEAM = 94HVVWXLK3;' StagePane.xcodeproj/project.pbxproj || \
   ! grep -F -q 'PRODUCT_BUNDLE_IDENTIFIER = com.hinoshiba.stagepane;' StagePane.xcodeproj/project.pbxproj; then
    print -u2 "Checked-in Xcode project has an unexpected Team or bundle identifier"
    exit 70
fi

for required in LICENSE NOTICE THIRD_PARTY_NOTICES.md TRADEMARKS.md \
    Assets/LICENSE.md docs/PRIVACY.md docs/LICENSE_AUDIT.md \
    docs/HELP.md docs/APP_STORE_HELP.md docs/APP_STORE_PRIVACY.md \
    docs/MONETIZATION.md docs/sbom.spdx.json Config/XcodeGen.lock \
    Config/StagePane.storekit SECURITY.md \
    project.yml StagePane.xcodeproj/project.pbxproj \
    Config/StagePane-AppStore-Info.plist \
    Scripts/app-store-archive-guard.sh Scripts/archive-app-store.sh \
    Scripts/test-app-store-archive-guard.sh Scripts/test-app-store-release-scripts.sh \
    Scripts/verify-app-store-source.sh \
    Scripts/verify-app-store-archive.sh; do
    if [[ ! -s "$required" ]]; then
        print -u2 "Missing required release document: $required"
        exit 70
    fi
done

IAP_PRODUCT_ID='com.hinoshiba.stagepane.pro'
IAP_EN_DESCRIPTION='Hide the mark and compose up to four sources.'
IAP_JA_DESCRIPTION='ロゴ非表示と最大4ソースを買い切りで開放'
IAP_US_DISPLAY_PRICE='4.99'
if [[ ${#IAP_EN_DESCRIPTION} -gt 45 || ${#IAP_JA_DESCRIPTION} -gt 45 ]] || \
   ! grep -F -q '"type" : "NonConsumable"' Config/StagePane.storekit || \
   ! grep -F -q "\"productID\" : \"$IAP_PRODUCT_ID\"" Config/StagePane.storekit || \
   ! grep -F -q "\"displayPrice\" : \"$IAP_US_DISPLAY_PRICE\"" Config/StagePane.storekit || \
   ! grep -F -q "\"description\" : \"$IAP_EN_DESCRIPTION\"" Config/StagePane.storekit || \
   ! grep -F -q "\"description\" : \"$IAP_JA_DESCRIPTION\"" Config/StagePane.storekit || \
   ! grep -F -q 'United States launch price: **$4.99**' docs/MONETIZATION.md || \
   ! grep -F -q 'Japan launch price: **¥500**' docs/MONETIZATION.md || \
   ! grep -F -q "$IAP_EN_DESCRIPTION" docs/MONETIZATION.md || \
   ! grep -F -q "$IAP_JA_DESCRIPTION" docs/MONETIZATION.md; then
    print -u2 'StagePane Pro StoreKit metadata or launch pricing is missing, mismatched, or exceeds the 45-character IAP description limit'
    exit 70
fi

if grep -n -E 'pre-release draft|Continue Setup|ad-hoc|local development build|re-register' \
    docs/APP_STORE_HELP.md docs/APP_STORE_PRIVACY.md; then
    print -u2 "Mac App Store help/privacy resources contain development-only guidance"
    exit 70
fi
for executable in Scripts/app-store-archive-guard.sh \
    Scripts/archive-app-store.sh Scripts/test-app-store-archive-guard.sh \
    Scripts/test-app-store-release-scripts.sh \
    Scripts/verify-app-store-source.sh \
    Scripts/verify-app-store-archive.sh; do
    if [[ ! -x "$executable" ]]; then
        print -u2 "App Store release helper must be executable: $executable"
        exit 70
    fi
done
Scripts/test-app-store-archive-guard.sh
Scripts/test-app-store-release-scripts.sh

if grep -R -n -E 'CGVirtualDisplay|com\.apple\.security\.screen-capture' Sources StagePane.entitlements; then
    print -u2 "Private display API or invalid screen-capture entitlement detected"
    exit 70
fi

if grep -R -n -E 'sharingType[[:space:]]*=[[:space:]]*\.none|NSWindowSharingNone|kCGWindowSharingNone' Sources; then
    print -u2 "Unsupported window capture-exclusion setting detected"
    exit 70
fi

if grep -n -E 'EmptyView[[:space:]]*\(' Sources/StagePane/App/StagePaneApp.swift; then
    print -u2 "The application entry point must not ship an empty Settings scene"
    exit 70
fi

if grep -R -n -E 'import ApplicationServices|PreviewInput|AXIsProcessTrusted|AXUIElement|AXValue|kAX|AXPress|Press Buttons|Button Press|ボタン操作|supportsControlMode|case[[:space:]]+\.control' Sources Tests; then
    print -u2 "Removed cross-application button-control code or copy detected"
    exit 70
fi

if grep -R -n -E 'CGEventPost|CGEventCreateMouseEvent|CGEventCreateKeyboardEvent|CGEventTapCreate|CGWarpMouseCursorPosition|CGAssociateMouseAndMouseCursorPosition|NSEvent\.add(Global|Local)MonitorForEvents' Sources Tests; then
    print -u2 "Raw input injection or event-monitoring code detected"
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
