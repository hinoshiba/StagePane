#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
GUARD="$SCRIPT_DIR/app-store-archive-guard.sh"
BASE_ENV=(
    ACTION=install
    CONFIGURATION=Release
    TARGET_NAME=StagePaneAppStore
    PRODUCT_NAME=StagePane
    PRODUCT_BUNDLE_IDENTIFIER=com.hinoshiba.stagepane
    DEVELOPMENT_TEAM=94HVVWXLK3
    CODE_SIGN_STYLE=Automatic
    CODE_SIGN_ENTITLEMENTS=StagePane.entitlements
    INFOPLIST_FILE=Config/StagePane-AppStore-Info.plist
    ENABLE_APP_SANDBOX=YES
    ENABLE_HARDENED_RUNTIME=YES
    ONLY_ACTIVE_ARCH=NO
    SKIP_INSTALL=NO
    SUPPORTED_PLATFORMS=macosx
    PLATFORM_NAME=macosx
    VALIDATE_PRODUCT=YES
    SWIFT_STRICT_CONCURRENCY=complete
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
    ARCHS="arm64 x86_64"
    CURRENT_PROJECT_VERSION=5
    STAGEPANE_PREVIOUS_UPLOADED_BUILD=3
    MARKETING_VERSION=0.3.1
)

/usr/bin/env "${BASE_ENV[@]}" "$GUARD" --settings-only

expect_rejection() {
    local label=$1
    shift
    if /usr/bin/env "${BASE_ENV[@]}" "$@" "$GUARD" --settings-only >/dev/null 2>&1; then
        print -u2 "Archive guard accepted invalid case: $label"
        exit 70
    fi
}

expect_rejection xcode-cloud CI_XCODE_CLOUD=TRUE
expect_rejection build-action ACTION=build
expect_rejection debug CONFIGURATION=Debug
expect_rejection wrong-target TARGET_NAME=StagePane
expect_rejection wrong-product PRODUCT_NAME=StagePaneAppStore
expect_rejection wrong-bundle PRODUCT_BUNDLE_IDENTIFIER=com.example.StagePane
expect_rejection wrong-team DEVELOPMENT_TEAM=0000000000
expect_rejection manual-signing CODE_SIGN_STYLE=Manual
expect_rejection wrong-entitlements CODE_SIGN_ENTITLEMENTS=Other.entitlements
expect_rejection wrong-info-plist INFOPLIST_FILE=Info.plist
expect_rejection no-sandbox ENABLE_APP_SANDBOX=NO
expect_rejection no-hardened-runtime ENABLE_HARDENED_RUNTIME=NO
expect_rejection active-architecture-only ONLY_ACTIVE_ARCH=YES
expect_rejection skipped-install SKIP_INSTALL=YES
expect_rejection wrong-platform SUPPORTED_PLATFORMS=iphoneos
expect_rejection wrong-platform-name PLATFORM_NAME=iphoneos
expect_rejection no-product-validation VALIDATE_PRODUCT=NO
expect_rejection incomplete-concurrency SWIFT_STRICT_CONCURRENCY=minimal
expect_rejection warnings-allowed SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
expect_rejection missing-intel ARCHS=arm64
expect_rejection extra-architecture ARCHS="arm64 x86_64 i386"
expect_rejection missing-build CURRENT_PROJECT_VERSION=
expect_rejection zero-build CURRENT_PROJECT_VERSION=0
expect_rejection dotted-build CURRENT_PROJECT_VERSION=4.1
expect_rejection leading-zero-build CURRENT_PROJECT_VERSION=04
expect_rejection overlong-build CURRENT_PROJECT_VERSION=1234567890123456789
expect_rejection reused-build CURRENT_PROJECT_VERSION=3
expect_rejection old-build CURRENT_PROJECT_VERSION=2
expect_rejection missing-previous-build STAGEPANE_PREVIOUS_UPLOADED_BUILD=
expect_rejection zero-previous-build STAGEPANE_PREVIOUS_UPLOADED_BUILD=0
expect_rejection overlong-previous-build STAGEPANE_PREVIOUS_UPLOADED_BUILD=1234567890123456789
expect_rejection invalid-version MARKETING_VERSION=0.3

print "App Store archive guard tests passed"
