#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
cd "$PROJECT_DIR"

: "${STAGEPANE_APPSTORE_TEAM_ID:?Set STAGEPANE_APPSTORE_TEAM_ID to the Apple Developer Team ID}"
: "${STAGEPANE_APPSTORE_BUNDLE_ID:?Set STAGEPANE_APPSTORE_BUNDLE_ID to a publisher-controlled App ID}"

if [[ ! "$STAGEPANE_APPSTORE_TEAM_ID" =~ '^[A-Z0-9]{10}$' ]]; then
    print -u2 "Refusing a malformed Apple Developer Team ID"
    exit 70
fi

if [[ "$STAGEPANE_APPSTORE_BUNDLE_ID" == "app.stagepane.StagePane" ]] ||
   ! print -r -- "$STAGEPANE_APPSTORE_BUNDLE_ID" |
       grep -qE '^[A-Za-z0-9][A-Za-z0-9-]*(\.[A-Za-z0-9][A-Za-z0-9-]*)+$'; then
    print -u2 "Refusing the unconfigured or malformed App Store bundle identifier"
    exit 70
fi

"$PROJECT_DIR/Scripts/release-check.sh" --app-store

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist)
ARCHIVE_PATH=${STAGEPANE_APPSTORE_ARCHIVE_PATH:-"$PROJECT_DIR/dist/StagePane-$VERSION-AppStore.xcarchive"}

if [[ -e "$ARCHIVE_PATH" ]]; then
    print -u2 "Refusing to overwrite an existing archive: $ARCHIVE_PATH"
    exit 70
fi

xcodebuild \
    -project "$PROJECT_DIR/StagePane.xcodeproj" \
    -scheme StagePane-AppStore \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$STAGEPANE_APPSTORE_TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$STAGEPANE_APPSTORE_BUNDLE_ID" \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGN_STYLE=Automatic \
    archive

APP_PATH="$ARCHIVE_PATH/Products/Applications/StagePane.app"
BINARY_PATH="$APP_PATH/Contents/MacOS/StagePane"

ARCHIVED_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist")
if [[ "$ARCHIVED_BUNDLE_ID" != "$STAGEPANE_APPSTORE_BUNDLE_ID" ]]; then
    print -u2 "Archived bundle ID does not match the requested App ID: $ARCHIVED_BUNDLE_ID"
    exit 70
fi

for required in \
    "$APP_PATH/Contents/Resources/AppIcon.icns" \
    "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy" \
    "$APP_PATH/Contents/Resources/en.lproj/InfoPlist.strings" \
    "$APP_PATH/Contents/Resources/ja.lproj/InfoPlist.strings" \
    "$APP_PATH/Contents/Resources/LICENSE.txt" \
    "$APP_PATH/Contents/Resources/NOTICE.txt" \
    "$APP_PATH/Contents/Resources/THIRD_PARTY_NOTICES.md" \
    "$APP_PATH/Contents/Resources/TRADEMARKS.md" \
    "$APP_PATH/Contents/Resources/BRAND_ASSET_LICENSE.md" \
    "$APP_PATH/Contents/Resources/PRIVACY.md" \
    "$APP_PATH/Contents/Resources/HELP.md"; do
    if [[ ! -s "$required" ]]; then
        print -u2 "Archive is missing required resource: $required"
        exit 70
    fi
done

codesign --verify --strict --verbose=2 "$APP_PATH"

ENTITLEMENTS_FILE=$(mktemp /tmp/stagepane-app-store-entitlements.XXXXXX)
cleanup() {
    rm -f "$ENTITLEMENTS_FILE"
}
trap cleanup EXIT
codesign -d --entitlements :- "$APP_PATH" > "$ENTITLEMENTS_FILE" 2>/dev/null

if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$ENTITLEMENTS_FILE")" != "true" ]]; then
    print -u2 "Archived app is not sandboxed"
    exit 70
fi
if [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.network.client' "$ENTITLEMENTS_FILE" 2>/dev/null || true)" == "true" ]]; then
    print -u2 "Archived app unexpectedly has a network client entitlement"
    exit 70
fi

ARCHITECTURES=$(lipo -archs "$BINARY_PATH")
if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
    print -u2 "Archived App Store binary is not universal: $ARCHITECTURES"
    exit 70
fi

MACHO_COUNT=0
while IFS= read -r -d '' candidate; do
    if file "$candidate" | grep -q 'Mach-O'; then
        (( MACHO_COUNT += 1 ))
        ABSOLUTE_RPATHS=$(otool -l "$candidate" | awk '
            $1 == "cmd" && $2 == "LC_RPATH" { getline; getline; if ($2 ~ /^\//) print $2 }
        ')
        if [[ -n "$ABSOLUTE_RPATHS" ]]; then
            print -u2 "Archived Mach-O contains absolute LC_RPATH entries: $candidate"
            print -u2 "$ABSOLUTE_RPATHS"
            exit 70
        fi
    fi
done < <(find "$APP_PATH/Contents" -type f -print0)
if [[ "$MACHO_COUNT" -eq 0 ]]; then
    print -u2 "Archive contains no Mach-O executable"
    exit 70
fi

typeset -A RESOURCE_SOURCES=(
    LICENSE.txt "$PROJECT_DIR/LICENSE"
    NOTICE.txt "$PROJECT_DIR/NOTICE"
    THIRD_PARTY_NOTICES.md "$PROJECT_DIR/THIRD_PARTY_NOTICES.md"
    TRADEMARKS.md "$PROJECT_DIR/TRADEMARKS.md"
    BRAND_ASSET_LICENSE.md "$PROJECT_DIR/Assets/LICENSE.md"
    PRIVACY.md "$PROJECT_DIR/docs/PRIVACY.md"
    HELP.md "$PROJECT_DIR/docs/HELP.md"
)
for bundled_name source_path in ${(kv)RESOURCE_SOURCES}; do
    if ! cmp -s "$source_path" "$APP_PATH/Contents/Resources/$bundled_name"; then
        print -u2 "Archived legal/help resource differs from source: $bundled_name"
        exit 70
    fi
done

PLACEHOLDER_TOKENS=(
    RELEASE_REPOSITORY_URL_PLACEHOLDER
    RELEASE_TRADEMARK_OWNER_PLACEHOLDER
    RELEASE_CONTACT_PLACEHOLDER
    RELEASE_SECURITY_CONTACT_PLACEHOLDER
    RELEASE_SUPPORT_CONTACT_PLACEHOLDER
    RELEASE_CONDUCT_CONTACT_PLACEHOLDER
    RELEASE_GITHUB_OWNER_PLACEHOLDER
)
for token in "${PLACEHOLDER_TOKENS[@]}"; do
    if grep -R -F -n "$token" \
        "$APP_PATH/Contents/Info.plist" "$APP_PATH/Contents/Resources"; then
        print -u2 "Archived app contains a release placeholder: $token"
        exit 70
    fi
done

print "Created and verified App Store archive: $ARCHIVE_PATH"
print "No upload was performed. Validate and distribute the archive with Xcode Organizer."
