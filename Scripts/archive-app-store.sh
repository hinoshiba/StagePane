#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
cd "$PROJECT_DIR"

if [[ $# -ne 0 ]]; then
    print -u2 "Usage: ./Scripts/archive-app-store.sh"
    exit 64
fi

./Scripts/release-check.sh
./Scripts/verify-app-store-source.sh

umask 077
ARCHIVE_DIR=$(/usr/bin/mktemp -d /tmp/StagePane-AppStore.XXXXXX)
ARCHIVE_PATH="$ARCHIVE_DIR/StagePane.xcarchive"
XCODEBUILD_LOG="$ARCHIVE_DIR/xcodebuild.log"
SOURCE_COMMIT=$(/usr/bin/git rev-parse HEAD)
SOURCE_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
SOURCE_BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Info.plist)
AUTHORIZATION_FILE="$ARCHIVE_DIR/archive.authorization"
AUTHORIZATION_TOKEN=$(/usr/bin/uuidgen)
printf 'STAGEPANE_APP_STORE_ARCHIVE_V1\n%s\n%s\n%s\n%s\n' \
    "$AUTHORIZATION_TOKEN" "$SOURCE_COMMIT" "$SOURCE_VERSION" "$SOURCE_BUILD" >"$AUTHORIZATION_FILE"
/bin/chmod 0600 "$AUTHORIZATION_FILE"

if ! STAGEPANE_APP_STORE_AUTHORIZATION_FILE="$AUTHORIZATION_FILE" \
        STAGEPANE_APP_STORE_AUTHORIZATION_TOKEN="$AUTHORIZATION_TOKEN" \
        /usr/bin/xcodebuild -quiet \
        -project StagePane.xcodeproj \
        -scheme StagePane-AppStore \
        -configuration Release \
        -destination 'generic/platform=macOS' \
        -archivePath "$ARCHIVE_PATH" \
        clean archive >"$XCODEBUILD_LOG" 2>&1; then
    print -u2 "Archive failed. Keep signing details private and inspect: $XCODEBUILD_LOG"
    exit 1
fi

[[ ! -e "$AUTHORIZATION_FILE" && -f "$AUTHORIZATION_FILE.used" ]] || {
    print -u2 "Archive did not consume its one-time authorization"
    exit 1
}

./Scripts/verify-app-store-source.sh
./Scripts/verify-app-store-archive.sh "$ARCHIVE_PATH"
print "Source commit: $SOURCE_COMMIT"
print "Verified archive: $ARCHIVE_PATH"
print "Private Xcode log: $XCODEBUILD_LOG"
print "Xcode Organizer is opening. Upload and App Review actions remain manual."
/usr/bin/open -a Xcode "$ARCHIVE_PATH"
