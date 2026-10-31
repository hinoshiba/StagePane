#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
ARCHIVE_HELPER="$SCRIPT_DIR/archive-app-store.sh"
ARCHIVE_GUARD="$SCRIPT_DIR/app-store-archive-guard.sh"
ARCHIVE_VERIFIER="$SCRIPT_DIR/verify-app-store-archive.sh"
SOURCE_VERIFIER="$SCRIPT_DIR/verify-app-store-source.sh"

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

# Exercise the real local-source checks without reaching the canonical remote
# or signing: a clean fixture must reach the intentional non-main branch guard.
SOURCE_FIXTURE="$FIXTURE_ROOT/source"
/bin/mkdir -p "$SOURCE_FIXTURE/Scripts" "$SOURCE_FIXTURE/StagePane.xcodeproj" \
    "$SOURCE_FIXTURE/Sources/StagePaneCore" "$SOURCE_FIXTURE/Resources/en.lproj"
/bin/cp "$SOURCE_VERIFIER" "$SOURCE_FIXTURE/Scripts/verify-app-store-source.sh"
/bin/cp "$ARCHIVE_HELPER" "$SOURCE_FIXTURE/Scripts/archive-app-store.sh"
cat >"$SOURCE_FIXTURE/Scripts/release-check.sh" <<'SH'
#!/bin/sh
touch "$(dirname "$0")/../preflight-ran"
SH
/bin/chmod 0755 "$SOURCE_FIXTURE/Scripts/release-check.sh"
for input in Info.plist project.yml .gitignore; do
    /bin/cp "$SCRIPT_DIR/../$input" "$SOURCE_FIXTURE/$input"
done
/bin/cp "$SCRIPT_DIR/../StagePane.xcodeproj/project.pbxproj" \
    "$SOURCE_FIXTURE/StagePane.xcodeproj/project.pbxproj"
printf 'public enum ReviewedSource {}\n' >"$SOURCE_FIXTURE/Sources/StagePaneCore/Reviewed.swift"
printf '"reviewed" = "fixture";\n' >"$SOURCE_FIXTURE/Resources/en.lproj/InfoPlist.strings"
fixture_git() {
    /usr/bin/env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 /usr/bin/git \
        -C "$SOURCE_FIXTURE" -c core.hooksPath=/dev/null -c commit.gpgSign=false \
        -c user.name='StagePane Test Fixture' -c user.email='fixture@example.invalid' "$@"
}
fixture_git init -q -b source-verifier-fixture
fixture_git add --all
fixture_git commit -qm 'Create synthetic source-verification fixture'

expect_source_rejection() {
    local label=$1 expected=$2
    local output="$FIXTURE_ROOT/source-$label.log"
    if /usr/bin/env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
            "$SOURCE_FIXTURE/Scripts/verify-app-store-source.sh" >"$output" 2>&1; then
        fail "source verifier unexpectedly accepted fixture: $label"
    fi
    /usr/bin/grep -Fq -- "$expected" "$output" || \
        fail "source verifier rejected fixture at the wrong boundary: $label"
}

expect_source_rejection clean 'official archives must be created from main'
if /usr/bin/env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
        "$SOURCE_FIXTURE/Scripts/archive-app-store.sh" >"$FIXTURE_ROOT/source-entrypoint.log" 2>&1; then
    fail 'archive helper accepted the non-main source fixture'
fi
[[ ! -e "$SOURCE_FIXTURE/preflight-ran" ]] || \
    fail 'archive helper executed preflight before checking source provenance'
/usr/bin/grep -Fq 'official archives must be created from main' \
    "$FIXTURE_ROOT/source-entrypoint.log" || fail 'archive helper missed the source verification boundary'
/bin/mkdir -p "$SOURCE_FIXTURE/.build" "$SOURCE_FIXTURE/dist"
: >"$SOURCE_FIXTURE/.build/allowed-output"
: >"$SOURCE_FIXTURE/dist/allowed-output"
expect_source_rejection build-output 'official archives must be created from main'

/bin/mkdir -p "$SOURCE_FIXTURE/Sources/StagePaneCore/build"
printf 'public enum UnreviewedSource {}\n' \
    >"$SOURCE_FIXTURE/Sources/StagePaneCore/build/Unreviewed.swift"
[[ -z "$(fixture_git status --porcelain)" ]] || fail 'ignored-source fixture is not Git-clean'
expect_source_rejection ignored-source 'source, test, and resource directories must not contain ignored files'
/bin/rm "$SOURCE_FIXTURE/Sources/StagePaneCore/build/Unreviewed.swift"

/bin/mkdir -p "$SOURCE_FIXTURE/Tests/StagePaneCoreTests/build"
printf 'public enum UnreviewedTest {}\n' \
    >"$SOURCE_FIXTURE/Tests/StagePaneCoreTests/build/Unreviewed.swift"
[[ -z "$(fixture_git status --porcelain)" ]] || fail 'ignored-test fixture is not Git-clean'
expect_source_rejection ignored-test 'source, test, and resource directories must not contain ignored files'
/bin/rm "$SOURCE_FIXTURE/Tests/StagePaneCoreTests/build/Unreviewed.swift"

: >"$SOURCE_FIXTURE/Resources/en.lproj/unreviewed.log"
[[ -z "$(fixture_git status --porcelain)" ]] || fail 'ignored-resource fixture is not Git-clean'
expect_source_rejection ignored-resource 'source, test, and resource directories must not contain ignored files'
/bin/rm "$SOURCE_FIXTURE/Resources/en.lproj/unreviewed.log"

fixture_git config status.showUntrackedFiles no
printf 'public enum UntrackedSource {}\n' >"$SOURCE_FIXTURE/Sources/StagePaneCore/Untracked.swift"
[[ -z "$(fixture_git status --porcelain)" ]] || fail 'hidden-untracked fixture is not Git-clean'
expect_source_rejection hidden-untracked 'worktree must be clean before Archive'
/bin/rm "$SOURCE_FIXTURE/Sources/StagePaneCore/Untracked.swift"

for index_flag in assume-unchanged skip-worktree; do
    fixture_git update-index "--$index_flag" Sources/StagePaneCore/Reviewed.swift
    printf 'public enum HiddenModification {}\n' >"$SOURCE_FIXTURE/Sources/StagePaneCore/Reviewed.swift"
    [[ -z "$(fixture_git status --porcelain)" ]] || fail "hidden-index fixture is not Git-clean: $index_flag"
    expect_source_rejection "$index_flag" 'must not use assume-unchanged or skip-worktree flags'
    fixture_git update-index "--no-$index_flag" Sources/StagePaneCore/Reviewed.swift
    fixture_git checkout -- Sources/StagePaneCore/Reviewed.swift
done
expect_source_rejection restored 'official archives must be created from main'

print "App Store release script tests passed"
