#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}

fail() {
    print -u2 "error: $1"
    exit 1
}

if [[ $# -ne 1 || "$1" != /* ]]; then
    fail "Usage: verify-app-store-archive.sh /absolute/path/StagePane.xcarchive"
fi

ARCHIVE_PATH=$1
[[ -d "$ARCHIVE_PATH" && ! -L "$ARCHIVE_PATH" ]] || fail "Archive path is missing or symlinked"
APP_PATH="$ARCHIVE_PATH/Products/Applications/StagePane.app"
INFO_PATH="$APP_PATH/Contents/Info.plist"
BINARY_PATH="$APP_PATH/Contents/MacOS/StagePane"
[[ -d "$APP_PATH" && ! -L "$APP_PATH" && -f "$INFO_PATH" && -f "$BINARY_PATH" ]] || \
    fail "Archive does not contain the expected StagePane app"

ARCHIVE_INFO="$ARCHIVE_PATH/Info.plist"
[[ -f "$ARCHIVE_INFO" ]] || fail "Archive metadata is missing"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PATH")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PATH")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PATH")
ARCHIVE_TEAM=$(/usr/bin/plutil -extract ApplicationProperties.Team raw -o - "$ARCHIVE_INFO")
ARCHIVE_BUNDLE=$(/usr/bin/plutil -extract ApplicationProperties.CFBundleIdentifier raw -o - "$ARCHIVE_INFO")
ARCHIVE_VERSION=$(/usr/bin/plutil -extract ApplicationProperties.CFBundleShortVersionString raw -o - "$ARCHIVE_INFO")
ARCHIVE_BUILD=$(/usr/bin/plutil -extract ApplicationProperties.CFBundleVersion raw -o - "$ARCHIVE_INFO")

[[ "$BUNDLE_ID" == com.hinoshiba.stagepane && "$ARCHIVE_BUNDLE" == "$BUNDLE_ID" ]] || \
    fail "Archive bundle identifier is incorrect"
[[ "$ARCHIVE_TEAM" == 94HVVWXLK3 ]] || fail "Archive Team ID is incorrect"
[[ "$ARCHIVE_VERSION" == "$VERSION" && "$ARCHIVE_BUILD" == "$BUILD" ]] || \
    fail "Archive metadata version/build is inconsistent"

SOURCE_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Info.plist")
SOURCE_BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PROJECT_DIR/Info.plist")
[[ "$VERSION" == "$SOURCE_VERSION" && "$BUILD" == "$SOURCE_BUILD" ]] || \
    fail "Archive version/build does not match the checked-in release"
[[ "$(/usr/bin/plutil -extract ITSAppUsesNonExemptEncryption raw -o - "$INFO_PATH")" == false ]] || \
    fail "Archive export-compliance flag is incorrect"
[[ "$(/usr/bin/plutil -extract LSMinimumSystemVersion raw -o - "$INFO_PATH")" == 14.0 ]] || \
    fail "Archive minimum macOS version is incorrect"

/usr/bin/codesign --verify --deep --strict \
    --test-requirement='=anchor apple generic and identifier "com.hinoshiba.stagepane" and certificate leaf[subject.OU] = "94HVVWXLK3"' \
    "$APP_PATH"
VERIFY_TEMP=$(/usr/bin/mktemp -d /tmp/StagePane-archive-verify.XXXXXX)
trap '/bin/rm -rf -- "$VERIFY_TEMP"' EXIT
/usr/bin/codesign -d --entitlements :- "$APP_PATH" >"$VERIFY_TEMP/entitlements.plist" 2>/dev/null
/usr/bin/codesign -dv --verbose=4 "$APP_PATH" >"$VERIFY_TEMP/signing.txt" 2>&1
/usr/bin/grep -q 'flags=.*runtime' "$VERIFY_TEMP/signing.txt" || fail "Hardened Runtime is missing"
/usr/bin/grep -Fxq 'TeamIdentifier=94HVVWXLK3' "$VERIFY_TEMP/signing.txt" || \
    fail "the application signature belongs to an unexpected Team"
ENTITLEMENT_KEY_COUNT=$(/usr/bin/plutil -p "$VERIFY_TEMP/entitlements.plist" | /usr/bin/grep -c ' => ' || true)
[[ "$ENTITLEMENT_KEY_COUNT" -eq 2 ]] || fail "Archive contains an unexpected entitlement"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$VERIFY_TEMP/entitlements.plist")" == true ]] || \
    fail "App Sandbox entitlement is missing"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.files.user-selected.read-write' "$VERIFY_TEMP/entitlements.plist")" == true ]] || \
    fail "User-selected file entitlement is missing"
if [[ -f "$APP_PATH/Contents/embedded.provisionprofile" ]]; then
    /usr/bin/security cms -D -i "$APP_PATH/Contents/embedded.provisionprofile" \
        -o "$VERIFY_TEMP/profile.plist" >/dev/null 2>&1 || fail "embedded profile is unreadable"
    [[ "$(/usr/bin/plutil -extract TeamIdentifier.0 raw -o - "$VERIFY_TEMP/profile.plist")" == 94HVVWXLK3 ]] || \
        fail "embedded profile belongs to an unexpected Team"
    [[ "$(/usr/bin/plutil -extract Entitlements.application-identifier raw -o - "$VERIFY_TEMP/profile.plist")" == 94HVVWXLK3.com.hinoshiba.stagepane ]] || \
        fail "embedded profile has an unexpected application identifier"
fi

ARCHS=$(/usr/bin/lipo -archs "$BINARY_PATH")
[[ " $ARCHS " == *" arm64 "* && " $ARCHS " == *" x86_64 "* ]] || \
    fail "Archive is not universal arm64/x86_64"

for resource in AppIcon.icns PrivacyInfo.xcprivacy LICENSE.txt NOTICE.txt \
    THIRD_PARTY_NOTICES.md TRADEMARKS.md BRAND_ASSET_LICENSE.md PRIVACY.md HELP.md \
    en.lproj/InfoPlist.strings ja.lproj/InfoPlist.strings; do
    [[ -s "$APP_PATH/Contents/Resources/$resource" ]] || fail "Archive is missing required resource: $resource"
done

compare_resource() {
    /usr/bin/cmp -s "$PROJECT_DIR/$1" "$APP_PATH/Contents/Resources/$2" || \
        fail "Archive resource differs from the reviewed source: $2"
}
compare_resource Resources/PrivacyInfo.xcprivacy PrivacyInfo.xcprivacy
compare_resource LICENSE LICENSE.txt
compare_resource NOTICE NOTICE.txt
compare_resource THIRD_PARTY_NOTICES.md THIRD_PARTY_NOTICES.md
compare_resource TRADEMARKS.md TRADEMARKS.md
compare_resource Assets/LICENSE.md BRAND_ASSET_LICENSE.md
compare_resource docs/APP_STORE_PRIVACY.md PRIVACY.md
compare_resource docs/APP_STORE_HELP.md HELP.md
compare_resource Resources/en.lproj/InfoPlist.strings en.lproj/InfoPlist.strings
compare_resource Resources/ja.lproj/InfoPlist.strings ja.lproj/InfoPlist.strings

[[ ! -e "$APP_PATH/Contents/Resources/DEVELOPMENT_BUILD_DO_NOT_DISTRIBUTE.txt" ]] || \
    fail "Archive contains a development-only marker"
if /usr/bin/grep -R -E 'RELEASE_[A-Z0-9_]+_PLACEHOLDER' "$APP_PATH/Contents/Resources" >/dev/null 2>&1; then
    fail "Archive contains an unresolved release placeholder"
fi
if /usr/bin/find "$APP_PATH/Contents" -type l -print -quit | /usr/bin/grep -q .; then
    fail "Archive contains an unexpected symlink"
fi

MACHO_COUNT=0
while IFS= read -r -d '' candidate; do
    if /usr/bin/file -b "$candidate" | /usr/bin/grep -q 'Mach-O'; then
        (( MACHO_COUNT += 1 ))
        [[ "$candidate" == "$BINARY_PATH" ]] || fail "Archive contains an unexpected executable"
        if /usr/bin/otool -l "$candidate" | /usr/bin/awk '
            $1 == "cmd" && $2 == "LC_RPATH" { getline; getline; if ($2 ~ /^\//) found = 1 }
            END { exit(found ? 0 : 1) }
        '; then
            fail "Archive contains an absolute LC_RPATH"
        fi
    fi
done < <(/usr/bin/find "$APP_PATH/Contents" -type f -print0)
[[ "$MACHO_COUNT" -eq 1 ]] || fail "Archive must contain exactly one executable"

print "Verified StagePane $VERSION ($BUILD), Team 94HVVWXLK3, arm64/x86_64."
