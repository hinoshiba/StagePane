#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
APP_PATH=${1:-"$PROJECT_DIR/dist/StagePane.app"}
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
OUTPUT_PATH="$PROJECT_DIR/dist/StagePane-$VERSION.dmg"
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
    -ov \
    -format UDZO \
    "$OUTPUT_PATH"

printf '%s\n' "$OUTPUT_PATH"
