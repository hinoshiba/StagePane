#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h}
cd "$PROJECT_DIR"
DIST_DIR="$PROJECT_DIR/dist"

NOTARY_TEMP=""
BUILD_TEMP=""
cleanup_notary_temp() {
    if [[ -n "$NOTARY_TEMP" && -d "$NOTARY_TEMP" && \
          "$NOTARY_TEMP" == /tmp/stagepane-notary.* ]]; then
        rm -rf -- "$NOTARY_TEMP"
    fi
}
cleanup_build_temp() {
    if [[ -n "$BUILD_TEMP" && -d "$BUILD_TEMP" && \
          "$BUILD_TEMP" == /tmp/stagepane-build.* ]]; then
        rm -rf -- "$BUILD_TEMP"
    fi
}
cleanup_temporaries() {
    cleanup_notary_temp
    cleanup_build_temp
}
trap cleanup_temporaries EXIT

MODE=${1:-dev}
if [[ "$MODE" != "dev" && "$MODE" != "--dist" && "$MODE" != "dist" ]]; then
    print -u2 "Usage: ./build.sh [dev|--dist]"
    exit 64
fi

if [[ "$MODE" == "--dist" || "$MODE" == "dist" ]]; then
    : "${STAGEPANE_DIST_IDENTITY:?Set STAGEPANE_DIST_IDENTITY to a Developer ID Application identity}"
    : "${STAGEPANE_NOTARY_PROFILE:?Set STAGEPANE_NOTARY_PROFILE to a notarytool keychain profile}"
    "$PROJECT_DIR/Scripts/release-check.sh" --distribution
    source "$PROJECT_DIR/Scripts/signing-identity.sh"
    if ! DIST_SIGNING_IDENTITY=$(stagepane_normalize_sha1 "$STAGEPANE_DIST_IDENTITY"); then
        print -u2 "STAGEPANE_DIST_IDENTITY must be the approved 40-hex certificate SHA-1"
        exit 70
    fi
    if [[ "$DIST_SIGNING_IDENTITY" != "$STAGEPANE_DIRECT_IDENTITY_SHA1" ]]; then
        print -u2 "Refusing an unapproved Developer ID Application identity"
        print -u2 "Expected SHA-1: $STAGEPANE_DIRECT_IDENTITY_SHA1"
        exit 70
    fi
    stagepane_require_direct_identity
    BUILD_TEMP=$(mktemp -d /tmp/stagepane-build.XXXXXX)
    swift build --scratch-path "$BUILD_TEMP/arm64" -c release \
        --triple arm64-apple-macosx14.0
    ARM64_BIN_DIR=$(swift build --scratch-path "$BUILD_TEMP/arm64" -c release \
        --triple arm64-apple-macosx14.0 --show-bin-path)
    swift build --scratch-path "$BUILD_TEMP/x86_64" -c release \
        --triple x86_64-apple-macosx14.0
    X86_64_BIN_DIR=$(swift build --scratch-path "$BUILD_TEMP/x86_64" -c release \
        --triple x86_64-apple-macosx14.0 --show-bin-path)
    BINARY_PATH="$BUILD_TEMP/StagePane"
    lipo -create \
        "$ARM64_BIN_DIR/StagePane" \
        "$X86_64_BIN_DIR/StagePane" \
        -output "$BINARY_PATH"
else
    "$PROJECT_DIR/Scripts/release-check.sh"
    swift build -c release
    BINARY_PATH="$PROJECT_DIR/.build/release/StagePane"
fi

if [[ -L "$DIST_DIR" ]]; then
    print -u2 "Refusing symlinked distribution directory: $DIST_DIR"
    exit 70
fi
if [[ -e "$DIST_DIR" && ! -d "$DIST_DIR" ]]; then
    print -u2 "Refusing non-directory distribution path: $DIST_DIR"
    exit 70
fi
mkdir -p "$DIST_DIR"

REAL_PROJECT_DIR=${PROJECT_DIR:A}
REAL_DIST_DIR=${DIST_DIR:A}
if [[ "$REAL_DIST_DIR" != "$REAL_PROJECT_DIR/dist" ]]; then
    print -u2 "Refusing distribution directory outside the project: $REAL_DIST_DIR"
    exit 70
fi

APP_PATH="$REAL_DIST_DIR/StagePane.app"
if [[ -L "$APP_PATH" ]]; then
    print -u2 "Refusing symlinked application output: $APP_PATH"
    exit 70
fi
rm -rf -- "$APP_PATH"
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

swift "$PROJECT_DIR/Scripts/MakeIcon.swift" "$REAL_DIST_DIR" >/dev/null
iconutil -c icns "$REAL_DIST_DIR/StagePane.iconset" -o "$REAL_DIST_DIR/AppIcon.icns"
cp "$REAL_DIST_DIR/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"

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
    "$PROJECT_DIR/Scripts/release-check.sh" --verify-release-source
    ARCHITECTURES=$(lipo -archs "$APP_PATH/Contents/MacOS/StagePane")
    if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
        print -u2 "Distribution binary is not universal: $ARCHITECTURES"
        exit 70
    fi
    codesign --force --options runtime --timestamp \
        --entitlements "$PROJECT_DIR/StagePane.entitlements" \
        --sign "$DIST_SIGNING_IDENTITY" \
        "$APP_PATH"
else
    codesign --force --options runtime \
        --entitlements "$PROJECT_DIR/StagePane.entitlements" \
        --sign - \
        "$APP_PATH"
fi

if [[ "$MODE" == "--dist" || "$MODE" == "dist" ]]; then
    stagepane_verify_signed_identity \
        "$APP_PATH" \
        "$DIST_SIGNING_IDENTITY" \
        "$STAGEPANE_OFFICIAL_TEAM_ID" \
        developer-id-application \
        "$STAGEPANE_DIRECT_IDENTITY_CN"
else
    codesign --verify --strict --verbose=2 "$APP_PATH"
fi
plutil -lint "$APP_PATH/Contents/Info.plist" "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy"

if [[ "$MODE" == "--dist" || "$MODE" == "dist" ]]; then
    NOTARY_TEMP=$(mktemp -d /tmp/stagepane-notary.XXXXXX)
    ditto -c -k --keepParent "$APP_PATH" "$NOTARY_TEMP/StagePane.zip"
    xcrun notarytool submit "$NOTARY_TEMP/StagePane.zip" \
        --keychain-profile "$STAGEPANE_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$APP_PATH"
    xcrun stapler validate "$APP_PATH"
    stagepane_verify_signed_identity \
        "$APP_PATH" \
        "$DIST_SIGNING_IDENTITY" \
        "$STAGEPANE_OFFICIAL_TEAM_ID" \
        developer-id-application \
        "$STAGEPANE_DIRECT_IDENTITY_CN"
    cleanup_notary_temp
    NOTARY_TEMP=""

    VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
        "$APP_PATH/Contents/Info.plist")
    EXPECTED_DMG_PATH="$REAL_DIST_DIR/StagePane-$VERSION.dmg"
    DMG_PATH=$("$PROJECT_DIR/Scripts/make-dmg.sh" "$APP_PATH")
    if [[ "$DMG_PATH" != "$EXPECTED_DMG_PATH" || ! -f "$DMG_PATH" || \
          -L "$DMG_PATH" ]]; then
        print -u2 "DMG builder returned an unexpected artifact: $DMG_PATH"
        exit 70
    fi
    codesign --force --timestamp --sign "$DIST_SIGNING_IDENTITY" "$DMG_PATH"
    stagepane_verify_signed_identity \
        "$DMG_PATH" \
        "$DIST_SIGNING_IDENTITY" \
        "$STAGEPANE_OFFICIAL_TEAM_ID" \
        developer-id-application \
        "$STAGEPANE_DIRECT_IDENTITY_CN"
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$STAGEPANE_NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
    stagepane_verify_signed_identity \
        "$DMG_PATH" \
        "$DIST_SIGNING_IDENTITY" \
        "$STAGEPANE_OFFICIAL_TEAM_ID" \
        developer-id-application \
        "$STAGEPANE_DIRECT_IDENTITY_CN"
    DMG_DIRECTORY=${DMG_PATH:h}
    DMG_FILENAME=${DMG_PATH:t}
    CHECKSUM_PATH="$DMG_PATH.sha256"
    if [[ -e "$CHECKSUM_PATH" || -L "$CHECKSUM_PATH" ]]; then
        print -u2 "Refusing to overwrite an existing checksum: $CHECKSUM_PATH"
        exit 70
    fi
    (
        setopt NO_CLOBBER
        cd "$DMG_DIRECTORY"
        shasum -a 256 "$DMG_FILENAME" > "$DMG_FILENAME.sha256"
    )
fi

printf 'Built %s\n' "$APP_PATH"
if [[ "$MODE" == "dev" ]]; then
    print -u2 "DEVELOPMENT ONLY — dist/StagePane.app is ad-hoc signed and must not be published."
fi
