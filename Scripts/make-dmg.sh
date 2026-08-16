#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
APP_PATH=${1:-"$PROJECT_DIR/dist/StagePane.app"}
DIST_DIR="$PROJECT_DIR/dist"

if [[ -L "$DIST_DIR" ]]; then
    print -u2 "Refusing symlinked distribution directory: $DIST_DIR"
    exit 70
fi
if [[ ! -d "$DIST_DIR" ]]; then
    print -u2 "Distribution directory does not exist: $DIST_DIR"
    exit 70
fi

REAL_PROJECT_DIR=${PROJECT_DIR:A}
REAL_DIST_DIR=${DIST_DIR:A}
if [[ "$REAL_DIST_DIR" != "$REAL_PROJECT_DIR/dist" ]]; then
    print -u2 "Refusing distribution directory outside the project: $REAL_DIST_DIR"
    exit 70
fi

if [[ -L "$APP_PATH" || ! -d "$APP_PATH" ]]; then
    print -u2 "Refusing missing or symlinked application input: $APP_PATH"
    exit 70
fi
REAL_APP_PATH=${APP_PATH:A}
if [[ "$REAL_APP_PATH" != "$REAL_DIST_DIR/StagePane.app" ]]; then
    print -u2 "Refusing application input outside the fixed distribution path: $REAL_APP_PATH"
    exit 70
fi
APP_PATH="$REAL_APP_PATH"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
if [[ ${#VERSION} -gt 32 || ! "$VERSION" =~ '^[0-9]+([.][0-9]+){0,2}$' ]]; then
    print -u2 "Refusing invalid CFBundleShortVersionString: $VERSION"
    exit 70
fi

OUTPUT_PATH="$REAL_DIST_DIR/StagePane-$VERSION.dmg"
if [[ "${OUTPUT_PATH:h:A}" != "$REAL_DIST_DIR" ]]; then
    print -u2 "Refusing DMG output outside the distribution directory: $OUTPUT_PATH"
    exit 70
fi
if [[ -L "$OUTPUT_PATH" ]]; then
    print -u2 "Refusing symlinked DMG output: $OUTPUT_PATH"
    exit 70
fi
if [[ -e "$OUTPUT_PATH" ]]; then
    print -u2 "Refusing to overwrite an existing DMG: $OUTPUT_PATH"
    exit 70
fi

STAGING_DIR=$(mktemp -d /tmp/stagepane-dmg.XXXXXX)

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

cp -R "$APP_PATH" "$STAGING_DIR/StagePane.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "StagePane" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    "$OUTPUT_PATH" >&2

printf '%s\n' "$OUTPUT_PATH"
