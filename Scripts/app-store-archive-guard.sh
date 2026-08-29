#!/bin/sh
set -eu

fail() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--settings-only" ]; }; then
    fail "Usage: app-store-archive-guard.sh [--settings-only]"
fi

SETTINGS_ONLY=false
if [ "${1:-}" = "--settings-only" ]; then
    SETTINGS_ONLY=true
fi

[ "${CI_XCODE_CLOUD:-}" != "TRUE" ] || fail "Xcode Cloud Archive is not an authorized release path"
[ "${ACTION:-}" = "install" ] || fail "the App Store archive action must be install"
[ "${CONFIGURATION:-}" = "Release" ] || fail "the App Store archive must use Release"
[ "${TARGET_NAME:-}" = "StagePaneAppStore" ] || fail "unexpected App Store archive target"
[ "${PRODUCT_NAME:-}" = "StagePane" ] || fail "unexpected App Store product name"
[ "${PRODUCT_BUNDLE_IDENTIFIER:-}" = "com.hinoshiba.stagepane" ] || \
    fail "unexpected App Store bundle identifier"
[ "${DEVELOPMENT_TEAM:-}" = "94HVVWXLK3" ] || fail "unexpected Apple Developer Team"
[ "${CODE_SIGN_STYLE:-}" = "Automatic" ] || fail "App Store signing must remain automatic"
[ "${CODE_SIGN_ENTITLEMENTS:-}" = "StagePane.entitlements" ] || \
    fail "unexpected App Store entitlements file"
[ "${INFOPLIST_FILE:-}" = "Config/StagePane-AppStore-Info.plist" ] || \
    fail "unexpected App Store Info.plist"
[ "${ENABLE_APP_SANDBOX:-}" = "YES" ] || fail "App Sandbox must remain enabled"
[ "${ENABLE_HARDENED_RUNTIME:-}" = "YES" ] || fail "Hardened Runtime must remain enabled"
[ "${ONLY_ACTIVE_ARCH:-}" = "NO" ] || fail "App Store archives must build every supported architecture"
[ "${SKIP_INSTALL:-}" = "NO" ] || fail "the App Store application must be installable"
[ "${SUPPORTED_PLATFORMS:-}" = "macosx" ] || fail "the App Store archive must target macOS"
[ "${PLATFORM_NAME:-}" = "macosx" ] || fail "the App Store archive platform must be macOS"
[ "${VALIDATE_PRODUCT:-}" = "YES" ] || fail "App Store product validation must remain enabled"
[ "${SWIFT_STRICT_CONCURRENCY:-}" = "complete" ] || fail "strict concurrency checking must remain complete"
[ "${SWIFT_TREAT_WARNINGS_AS_ERRORS:-}" = "YES" ] || fail "Swift warnings must remain errors"

[ "${ARCHS:-}" = "arm64 x86_64" ] || [ "${ARCHS:-}" = "x86_64 arm64" ] || \
    fail "the App Store archive architectures must be exactly arm64 and x86_64"

case "${CURRENT_PROJECT_VERSION:-}" in
    ''|0|0*|*[!0-9]*) fail "CURRENT_PROJECT_VERSION must be a canonical positive integer" ;;
esac
case "${STAGEPANE_PREVIOUS_UPLOADED_BUILD:-}" in
    ''|0|0*|*[!0-9]*) fail "STAGEPANE_PREVIOUS_UPLOADED_BUILD must be a canonical positive integer" ;;
esac
[ "${#CURRENT_PROJECT_VERSION}" -le 18 ] || fail "CURRENT_PROJECT_VERSION is too long"
[ "${#STAGEPANE_PREVIOUS_UPLOADED_BUILD}" -le 18 ] || \
    fail "STAGEPANE_PREVIOUS_UPLOADED_BUILD is too long"
[ "$CURRENT_PROJECT_VERSION" -gt "$STAGEPANE_PREVIOUS_UPLOADED_BUILD" ] || \
    fail "CURRENT_PROJECT_VERSION must exceed the recorded App Store build floor"
printf '%s\n' "${MARKETING_VERSION:-}" | /usr/bin/grep -Eq \
    '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || \
    fail "MARKETING_VERSION must be semantic versioning"

if [ "$SETTINGS_ONLY" = true ]; then
    exit 0
fi

[ -n "${SRCROOT:-}" ] || fail "SRCROOT is unavailable"
ROOT=$(cd "$SRCROOT" && /bin/pwd -P)
[ "$ROOT" = "$(cd "$(dirname "$0")/.." && /bin/pwd -P)" ] || fail "unexpected Archive source root"

AUTH_FILE=${STAGEPANE_APP_STORE_AUTHORIZATION_FILE:-}
AUTH_TOKEN=${STAGEPANE_APP_STORE_AUTHORIZATION_TOKEN:-}
case "$AUTH_FILE" in
    /tmp/StagePane-AppStore.??????/archive.authorization) ;;
    *) fail "run Scripts/archive-app-store.sh instead of invoking Archive directly" ;;
esac
[ -f "$AUTH_FILE" ] && [ ! -L "$AUTH_FILE" ] || \
    fail "the one-time Archive authorization is missing"
[ "$(/usr/bin/stat -f '%Lp' "$AUTH_FILE")" = "600" ] || fail "unsafe Archive authorization permissions"
[ "$(/usr/bin/stat -f '%u' "$AUTH_FILE")" = "$(/usr/bin/id -u)" ] || fail "unexpected Archive authorization owner"
[ "$(/usr/bin/wc -l < "$AUTH_FILE" | /usr/bin/tr -d ' ')" = "5" ] || fail "invalid Archive authorization"
AUTH_FORMAT=$(/usr/bin/sed -n '1p' "$AUTH_FILE")
FILE_TOKEN=$(/usr/bin/sed -n '2p' "$AUTH_FILE")
AUTH_COMMIT=$(/usr/bin/sed -n '3p' "$AUTH_FILE")
AUTH_VERSION=$(/usr/bin/sed -n '4p' "$AUTH_FILE")
AUTH_BUILD=$(/usr/bin/sed -n '5p' "$AUTH_FILE")
[ "$AUTH_FORMAT" = "STAGEPANE_APP_STORE_ARCHIVE_V1" ] && \
    [ -n "$AUTH_TOKEN" ] && [ "$FILE_TOKEN" = "$AUTH_TOKEN" ] || fail "invalid one-time Archive authorization"

"$ROOT/Scripts/verify-app-store-source.sh" >/dev/null
HEAD_COMMIT=$(/usr/bin/git -C "$ROOT" rev-parse HEAD)
[ "$AUTH_COMMIT" = "$HEAD_COMMIT" ] && [ "$AUTH_VERSION" = "$MARKETING_VERSION" ] && \
    [ "$AUTH_BUILD" = "$CURRENT_PROJECT_VERSION" ] || fail "stale Archive authorization"

INFO_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist")
INFO_BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$ROOT/Info.plist")
[ "$STAGEPANE_PREVIOUS_UPLOADED_BUILD" = "$(/usr/bin/awk '$1 == "STAGEPANE_PREVIOUS_UPLOADED_BUILD:" { gsub(/"/, "", $2); print $2; exit }' "$ROOT/project.yml")" ] || \
    fail "resolved previous uploaded build does not match project.yml"
[ "$INFO_VERSION" = "$MARKETING_VERSION" ] || fail "Info.plist version does not match the Archive"
[ "$INFO_BUILD" = "$CURRENT_PROJECT_VERSION" ] || fail "Info.plist build does not match the Archive"

[ ! -e "$AUTH_FILE.used" ] || fail "the one-time Archive authorization was already consumed"
/bin/mv "$AUTH_FILE" "$AUTH_FILE.used"

printf 'Validated StagePane %s (%s) for local App Store Archive.\n' \
    "$MARKETING_VERSION" "$CURRENT_PROJECT_VERSION"
