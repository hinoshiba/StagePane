#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h}
cd "$PROJECT_DIR"

NOTARY_TEMP=""
cleanup_notary_temp() {
    if [[ -n "$NOTARY_TEMP" && -d "$NOTARY_TEMP" && \
          "$NOTARY_TEMP" == /tmp/stagepane-notary.* ]]; then
        rm -rf -- "$NOTARY_TEMP"
    fi
}
trap cleanup_notary_temp EXIT

MODE=${1:-dev}
if [[ "$MODE" != "dev" && "$MODE" != "--dist" && "$MODE" != "dist" ]]; then
    print -u2 "Usage: ./build.sh [dev|--dist]"
    exit 64
fi

if [[ "$MODE" == "--dist" || "$MODE" == "dist" ]]; then
    : "${STAGEPANE_DIST_IDENTITY:?Set STAGEPANE_DIST_IDENTITY to a Developer ID Application identity}"
    : "${STAGEPANE_NOTARY_PROFILE:?Set STAGEPANE_NOTARY_PROFILE to a notarytool keychain profile}"
    "$PROJECT_DIR/Scripts/release-check.sh" --distribution
    swift build -c release --arch arm64 --arch x86_64
    BINARY_PATH="$PROJECT_DIR/.build/apple/Products/Release/StagePane"
else
    "$PROJECT_DIR/Scripts/release-check.sh"
    swift build -c release
    BINARY_PATH="$PROJECT_DIR/.build/release/StagePane"
fi

APP_PATH="$PROJECT_DIR/dist/StagePane.app"
if [[ "$APP_PATH" != "$PROJECT_DIR/dist/StagePane.app" ]]; then
    print -u2 "Refusing unexpected application path: $APP_PATH"
    exit 70
fi
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

cp "$BINARY_PATH" "$APP_PATH/Contents/MacOS/StagePane"
cp "$PROJECT_DIR/Info.plist" "$APP_PATH/Contents/Info.plist"
printf 'APPL????' > "$APP_PATH/Contents/PkgInfo"
cp "$PROJECT_DIR/Resources/PrivacyInfo.xcprivacy" "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy"
cp -R "$PROJECT_DIR/Resources/en.lproj" "$APP_PATH/Contents/Resources/en.lproj"
cp -R "$PROJECT_DIR/Resources/ja.lproj" "$APP_PATH/Contents/Resources/ja.lproj"
cp "$PROJECT_DIR/LICENSE" "$APP_PATH/Contents/Resources/LICENSE.txt"
cp "$PROJECT_DIR/NOTICE" "$APP_PATH/Contents/Resources/NOTICE.txt"
cp "$PROJECT_DIR/THIRD_PARTY_NOTICES.md" "$APP_PATH/Contents/Resources/THIRD_PARTY_NOTICES.md"
cp "$PROJECT_DIR/TRADEMARKS.md" "$APP_PATH/Contents/Resources/TRADEMARKS.md"
cp "$PROJECT_DIR/Assets/LICENSE.md" "$APP_PATH/Contents/Resources/BRAND_ASSET_LICENSE.md"
cp "$PROJECT_DIR/docs/PRIVACY.md" "$APP_PATH/Contents/Resources/PRIVACY.md"
cp "$PROJECT_DIR/docs/HELP.md" "$APP_PATH/Contents/Resources/HELP.md"

if [[ "$MODE" == "dev" ]]; then
    print -r -- \
        "Development build only: ad-hoc signed, not notarized, and not approved for public distribution." \
        > "$APP_PATH/Contents/Resources/DEVELOPMENT_BUILD_DO_NOT_DISTRIBUTE.txt"
fi

mkdir -p "$PROJECT_DIR/dist"
swift "$PROJECT_DIR/Scripts/MakeIcon.swift" "$PROJECT_DIR/dist" >/dev/null
iconutil -c icns "$PROJECT_DIR/dist/StagePane.iconset" -o "$PROJECT_DIR/dist/AppIcon.icns"
cp "$PROJECT_DIR/dist/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"

BUNDLED_BINARY="$APP_PATH/Contents/MacOS/StagePane"
ABSOLUTE_RPATHS=$(otool -l "$BUNDLED_BINARY" | awk '
    $1 == "cmd" && $2 == "LC_RPATH" { getline; getline; if ($2 ~ /^\//) print $2 }
' | sort -u)
for rpath in ${(f)ABSOLUTE_RPATHS}; do
    install_name_tool -delete_rpath "$rpath" "$BUNDLED_BINARY"
done
if otool -l "$BUNDLED_BINARY" | awk '
    $1 == "cmd" && $2 == "LC_RPATH" { getline; getline; if ($2 ~ /^\//) found = 1 }
    END { exit(found ? 0 : 1) }
'; then
    print -u2 "Bundled binary contains an absolute LC_RPATH after normalization"
    exit 70
fi

if [[ "$MODE" == "--dist" || "$MODE" == "dist" ]]; then
    ARCHITECTURES=$(lipo -archs "$APP_PATH/Contents/MacOS/StagePane")
    if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
        print -u2 "Distribution binary is not universal: $ARCHITECTURES"
        exit 70
    fi
    codesign --force --options runtime --timestamp \
        --entitlements "$PROJECT_DIR/StagePane.entitlements" \
        --sign "$STAGEPANE_DIST_IDENTITY" \
        "$APP_PATH"
else
    codesign --force --options runtime \
        --entitlements "$PROJECT_DIR/StagePane.entitlements" \
        --sign - \
        "$APP_PATH"
fi

codesign --verify --strict --verbose=2 "$APP_PATH"
plutil -lint "$APP_PATH/Contents/Info.plist" "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy"

if [[ "$MODE" == "--dist" || "$MODE" == "dist" ]]; then
    NOTARY_TEMP=$(mktemp -d /tmp/stagepane-notary.XXXXXX)
    ditto -c -k --keepParent "$APP_PATH" "$NOTARY_TEMP/StagePane.zip"
    xcrun notarytool submit "$NOTARY_TEMP/StagePane.zip" \
        --keychain-profile "$STAGEPANE_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$APP_PATH"
    xcrun stapler validate "$APP_PATH"
    cleanup_notary_temp
    NOTARY_TEMP=""

    DMG_PATH=$("$PROJECT_DIR/Scripts/make-dmg.sh" "$APP_PATH" | tail -1)
    codesign --force --timestamp --sign "$STAGEPANE_DIST_IDENTITY" "$DMG_PATH"
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$STAGEPANE_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
    DMG_DIRECTORY=${DMG_PATH:h}
    DMG_FILENAME=${DMG_PATH:t}
    (
        cd "$DMG_DIRECTORY"
        shasum -a 256 "$DMG_FILENAME" > "$DMG_FILENAME.sha256"
    )
fi

printf 'Built %s\n' "$APP_PATH"
if [[ "$MODE" == "dev" ]]; then
    print -u2 "DEVELOPMENT ONLY — dist/StagePane.app is ad-hoc signed and must not be published."
fi
