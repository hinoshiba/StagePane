#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
ARCHIVE_HELPER="$SCRIPT_DIR/archive-app-store.sh"
ARCHIVE_GUARD="$SCRIPT_DIR/app-store-archive-guard.sh"
ARCHIVE_VERIFIER="$SCRIPT_DIR/verify-app-store-archive.sh"

fail() {
    print -u2 "error: $1"
    exit 70
}

for expected in \
    '-project StagePane.xcodeproj' \
    '-scheme StagePane-AppStore' \
    '-configuration Release' \
    "-destination 'generic/platform=macOS'" \
    'Scripts/verify-app-store-source.sh' \
    'Scripts/verify-app-store-archive.sh' \
    'umask 022' \
    'umask 077' \
    ': >"$XCODEBUILD_LOG"' \
    '/bin/chmod 0600 "$XCODEBUILD_LOG"' \
    'Upload is not authorized by this helper' \
    'When separately authorized, the release owner must verify Distribution Summary and upload manually' \
    'Build selection and App Review submission remain separately authorized; public release requires release-mode-aware authorization' \
    '/usr/bin/open -a Xcode'; do
    /usr/bin/grep -Fq -- "$expected" "$ARCHIVE_HELPER" || fail "archive helper lost a fixed release control"
done

for forbidden in '-allowProvisioningUpdates' 'CODE_SIGN_IDENTITY=' '-exportArchive' \
    '-exportOptionsPlist' 'notarytool' 'altool' 'iTMSTransporter'; do
    if /usr/bin/grep -Fq -- "$forbidden" "$ARCHIVE_HELPER"; then
        fail "archive helper contains a forbidden signing, export, or upload option"
    fi
done

/usr/bin/grep -Fq 'CI_XCODE_CLOUD' "$ARCHIVE_GUARD" || fail "archive guard must reject Xcode Cloud"
/usr/bin/grep -Fq 'archive.authorization' "$ARCHIVE_GUARD" || fail "archive guard must require one-time authorization"
/usr/bin/grep -Fq 'verify-app-store-source.sh' "$ARCHIVE_GUARD" || fail "archive guard must verify release provenance"

expect_verifier_rejection() {
    local label=$1
    shift
    if "$ARCHIVE_VERIFIER" "$@" >/dev/null 2>&1; then
        fail "archive verifier accepted invalid fixture: $label"
    fi
}

FIXTURE_ROOT=$(/usr/bin/mktemp -d /tmp/StagePane-verifier-tests.XXXXXX)
trap '/bin/rm -rf -- "$FIXTURE_ROOT"' EXIT
MISSING_ARCHIVE="$FIXTURE_ROOT/Missing.xcarchive"
/bin/mkdir -m 0700 "$MISSING_ARCHIVE"
/bin/ln -s "$MISSING_ARCHIVE" "$FIXTURE_ROOT/Symlink.xcarchive"
expect_verifier_rejection missing-argument
expect_verifier_rejection relative-path relative/StagePane.xcarchive
expect_verifier_rejection missing-app "$MISSING_ARCHIVE"
expect_verifier_rejection symlink "$FIXTURE_ROOT/Symlink.xcarchive"

PERMISSION_ARCHIVE="$FIXTURE_ROOT/Permissions.xcarchive"
PERMISSION_APP="$PERMISSION_ARCHIVE/Products/Applications/StagePane.app"
/bin/mkdir -p "$PERMISSION_APP/Contents/MacOS"
: >"$PERMISSION_APP/Contents/Info.plist"
: >"$PERMISSION_APP/Contents/MacOS/StagePane"
/usr/bin/find "$PERMISSION_APP" -type d -exec /bin/chmod 0755 {} +
/usr/bin/find "$PERMISSION_APP" -type f -exec /bin/chmod 0644 {} +

POSITIVE_OUTPUT="$FIXTURE_ROOT/permissions-positive.log"
if "$ARCHIVE_VERIFIER" "$PERMISSION_ARCHIVE" >"$POSITIVE_OUTPUT" 2>&1; then
    fail "incomplete readable fixture unexpectedly passed archive verification"
fi
/usr/bin/grep -Fq 'Archive metadata is missing' "$POSITIVE_OUTPUT" || \
    fail "archive verifier did not accept non-root-readable fixture permissions"

/bin/chmod 0600 "$PERMISSION_APP/Contents/Info.plist"
NEGATIVE_FILE_OUTPUT="$FIXTURE_ROOT/permissions-file-negative.log"
if "$ARCHIVE_VERIFIER" "$PERMISSION_ARCHIVE" >"$NEGATIVE_FILE_OUTPUT" 2>&1; then
    fail "archive verifier accepted a root-only-readable file"
fi
/usr/bin/grep -Fq 'file that non-root users cannot read' "$NEGATIVE_FILE_OUTPUT" || \
    fail "archive verifier did not reject a root-only-readable file"

/bin/chmod 0644 "$PERMISSION_APP/Contents/Info.plist"
/bin/chmod 0700 "$PERMISSION_APP/Contents/MacOS"
NEGATIVE_DIRECTORY_OUTPUT="$FIXTURE_ROOT/permissions-directory-negative.log"
if "$ARCHIVE_VERIFIER" "$PERMISSION_ARCHIVE" >"$NEGATIVE_DIRECTORY_OUTPUT" 2>&1; then
    fail "archive verifier accepted a root-only-traversable directory"
fi
/usr/bin/grep -Fq 'directory that non-root users cannot traverse' "$NEGATIVE_DIRECTORY_OUTPUT" || \
    fail "archive verifier did not reject a root-only-traversable directory"

print "App Store release script tests passed"
