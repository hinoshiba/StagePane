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

print "App Store release script tests passed"
