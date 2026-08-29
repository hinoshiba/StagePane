#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
CANONICAL_REPOSITORY='https://github.com/hinoshiba/StagePane.git'

fail() {
    print -u2 "error: $1"
    exit 1
}

[[ $# -eq 0 ]] || fail "Usage: verify-app-store-source.sh"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PROJECT_DIR/Info.plist")
PROJECT_VERSION=$(awk '$1 == "MARKETING_VERSION:" { gsub(/"/, "", $2); print $2; exit }' "$PROJECT_DIR/project.yml")
PROJECT_BUILD=$(awk '$1 == "CURRENT_PROJECT_VERSION:" { gsub(/"/, "", $2); print $2; exit }' "$PROJECT_DIR/project.yml")
PREVIOUS_BUILD=$(awk '$1 == "STAGEPANE_PREVIOUS_UPLOADED_BUILD:" { gsub(/"/, "", $2); print $2; exit }' "$PROJECT_DIR/project.yml")

[[ ${#VERSION} -le 32 && "$VERSION" =~ '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$' ]] || \
    fail "the checked-in marketing version is invalid"
[[ ${#BUILD} -le 18 && "$BUILD" =~ '^[1-9][0-9]*$' ]] || \
    fail "the checked-in build number is invalid"
[[ ${#PREVIOUS_BUILD} -le 18 && "$PREVIOUS_BUILD" =~ '^[1-9][0-9]*$' ]] || \
    fail "the checked-in previous uploaded build is invalid"
(( BUILD > PREVIOUS_BUILD )) || fail "the build must exceed the previous uploaded build"
[[ "$PROJECT_VERSION" == "$VERSION" && "$PROJECT_BUILD" == "$BUILD" ]] || \
    fail "Info.plist and project.yml version/build values differ"
[[ "$(sed -n 's/^[[:space:]]*MARKETING_VERSION = \([^;]*\);/\1/p' "$PROJECT_DIR/StagePane.xcodeproj/project.pbxproj" | sort -u)" == "$VERSION" ]] || \
    fail "the generated project marketing version differs"
[[ "$(sed -n 's/^[[:space:]]*CURRENT_PROJECT_VERSION = \([^;]*\);/\1/p' "$PROJECT_DIR/StagePane.xcodeproj/project.pbxproj" | sort -u)" == "$BUILD" ]] || \
    fail "the generated project build number differs"
[[ "$(sed -n 's/^[[:space:]]*STAGEPANE_PREVIOUS_UPLOADED_BUILD = \([^;]*\);/\1/p' "$PROJECT_DIR/StagePane.xcodeproj/project.pbxproj" | sort -u)" == "$PREVIOUS_BUILD" ]] || \
    fail "the generated project previous uploaded build differs"

[[ -d "$PROJECT_DIR/.git" ]] || fail "the source is not the primary StagePane Git checkout"
[[ -z "$(/usr/bin/git -C "$PROJECT_DIR" status --porcelain)" ]] || \
    fail "the StagePane worktree must be clean before Archive"
BRANCH=$(/usr/bin/git -C "$PROJECT_DIR" symbolic-ref --short -q HEAD || true)
[[ "$BRANCH" == main ]] || fail "official archives must be created from main"
HEAD_COMMIT=$(/usr/bin/git -C "$PROJECT_DIR" rev-parse HEAD)

REMOTE_REFS=$(/usr/bin/env GIT_TERMINAL_PROMPT=0 /usr/bin/git \
    -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 \
    ls-remote "$CANONICAL_REPOSITORY" refs/heads/main \
    "refs/tags/v$VERSION" "refs/tags/v$VERSION^{}") || \
    fail "the canonical StagePane repository could not be queried"
REMOTE_MAIN=$(print -r -- "$REMOTE_REFS" | awk '$2 == "refs/heads/main" { print $1; exit }')
[[ "$REMOTE_MAIN" == "$HEAD_COMMIT" ]] || fail "local main must equal canonical origin/main"

TAG="v$VERSION"
LOCAL_TAG_TYPE=$(/usr/bin/git -C "$PROJECT_DIR" cat-file -t "refs/tags/$TAG" 2>/dev/null || true)
[[ "$LOCAL_TAG_TYPE" == tag ]] || fail "$TAG must be an annotated tag"
LOCAL_TAG_OBJECT=$(/usr/bin/git -C "$PROJECT_DIR" rev-parse "refs/tags/$TAG")
LOCAL_TAG_COMMIT=$(/usr/bin/git -C "$PROJECT_DIR" rev-list -n 1 "$TAG")
[[ "$LOCAL_TAG_COMMIT" == "$HEAD_COMMIT" ]] || fail "$TAG must point to the archived main commit"
/usr/bin/git -C "$PROJECT_DIR" verify-tag "$TAG" >/dev/null 2>&1 || \
    fail "$TAG must be cryptographically signed"
REMOTE_TAG_OBJECT=$(print -r -- "$REMOTE_REFS" | awk -v ref="refs/tags/$TAG" '$2 == ref { print $1; exit }')
REMOTE_TAG_COMMIT=$(print -r -- "$REMOTE_REFS" | awk -v ref="refs/tags/${TAG}^{}" '$2 == ref { print $1; exit }')
[[ "$REMOTE_TAG_OBJECT" == "$LOCAL_TAG_OBJECT" && "$REMOTE_TAG_COMMIT" == "$HEAD_COMMIT" ]] || \
    fail "the canonical remote must contain this exact signed tag object"

print "Validated StagePane $VERSION ($BUILD) source at $HEAD_COMMIT."
