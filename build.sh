#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h}
cd "$PROJECT_DIR"
DIST_DIR="$PROJECT_DIR/dist"
typeset -r LOCAL_SIGNING_IDENTITY=${STAGEPANE_LOCAL_SIGNING_IDENTITY:--}
unset STAGEPANE_LOCAL_SIGNING_IDENTITY

if [[ $# -ne 0 ]]; then
    print -u2 "Usage: ./build.sh"
    print -u2 "Official releases are built from v<version> tags by Xcode Cloud."
    exit 64
fi

"$PROJECT_DIR/Scripts/release-check.sh"
swift build -c debug
BINARY_DIR=$(swift build -c debug --show-bin-path)
BINARY_PATH="$BINARY_DIR/StagePane"

if [[ -L "$DIST_DIR" ]]; then
    print -u2 "Refusing symlinked output directory: $DIST_DIR"
    exit 70
fi
if [[ -e "$DIST_DIR" && ! -d "$DIST_DIR" ]]; then
    print -u2 "Refusing non-directory output path: $DIST_DIR"
    exit 70
fi
mkdir -p "$DIST_DIR"

REAL_PROJECT_DIR=${PROJECT_DIR:A}
REAL_DIST_DIR=${DIST_DIR:A}
if [[ "$REAL_DIST_DIR" != "$REAL_PROJECT_DIR/dist" ]]; then
    print -u2 "Refusing output directory outside the project: $REAL_DIST_DIR"
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
if [[ "$LOCAL_SIGNING_IDENTITY" == '-' ]]; then
    DEVELOPMENT_SIGNING_DESCRIPTION='ad-hoc signed'
    print -r -- \
        'This development build uses an ad-hoc code identity.' \
        > "$APP_PATH/Contents/Resources/DEVELOPMENT_BUILD_AD_HOC_SIGNING.txt"
else
    DEVELOPMENT_SIGNING_DESCRIPTION='signed with a caller-provided local identity'
fi
print -r -- \
    "Development build only: $DEVELOPMENT_SIGNING_DESCRIPTION and not approved for public distribution." \
    > "$APP_PATH/Contents/Resources/DEVELOPMENT_BUILD_DO_NOT_DISTRIBUTE.txt"

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

codesign --force --options runtime \
    --sign "$LOCAL_SIGNING_IDENTITY" \
    "$APP_PATH"
codesign --verify --strict --verbose=2 "$APP_PATH"
plutil -lint "$APP_PATH/Contents/Info.plist" "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy"

printf 'Built %s\n' "$APP_PATH"
print -u2 "DEVELOPMENT ONLY — dist/StagePane.app must not be published."
