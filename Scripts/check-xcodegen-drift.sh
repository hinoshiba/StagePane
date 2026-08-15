#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
LOCK_FILE="$PROJECT_DIR/Config/XcodeGen.lock"

typeset -A TRACKED_FILES=(
    PROJECT_YML_SHA256 "$PROJECT_DIR/project.yml"
    PBXPROJ_SHA256 "$PROJECT_DIR/StagePane.xcodeproj/project.pbxproj"
    WORKSPACE_SHA256 "$PROJECT_DIR/StagePane.xcodeproj/project.xcworkspace/contents.xcworkspacedata"
    SCHEME_SHA256 "$PROJECT_DIR/StagePane.xcodeproj/xcshareddata/xcschemes/StagePane-AppStore.xcscheme"
    ENTITLEMENTS_SHA256 "$PROJECT_DIR/StagePane.entitlements"
)

if [[ "${1:-}" == "--print-lock" ]]; then
    print '# Refresh only after regenerating with XcodeGen 2.45.4 and reviewing the diff.'
    print 'XCODEGEN_VERSION=2.45.4'
    for key in PROJECT_YML_SHA256 PBXPROJ_SHA256 WORKSPACE_SHA256 SCHEME_SHA256 ENTITLEMENTS_SHA256; do
        print "$key=$(shasum -a 256 "${TRACKED_FILES[$key]}" | awk '{print $1}')"
    done
    exit 0
fi

if [[ ! -s "$LOCK_FILE" ]]; then
    print -u2 "Missing XcodeGen drift lock: $LOCK_FILE"
    exit 70
fi

for key in PROJECT_YML_SHA256 PBXPROJ_SHA256 WORKSPACE_SHA256 SCHEME_SHA256 ENTITLEMENTS_SHA256; do
    expected=$(awk -F= -v key="$key" '$1 == key { print $2 }' "$LOCK_FILE")
    actual=$(shasum -a 256 "${TRACKED_FILES[$key]}" | awk '{print $1}')
    if ! print -r -- "$expected" | grep -qE '^[0-9a-f]{64}$' || [[ "$actual" != "$expected" ]]; then
        print -u2 "XcodeGen input/output drift detected for ${TRACKED_FILES[$key]}"
        print -u2 "Regenerate with XcodeGen 2.45.4, review the diff, then refresh Config/XcodeGen.lock"
        exit 70
    fi
done

XCODEGEN_BIN=${XCODEGEN_BIN:-$(command -v xcodegen || true)}
if [[ -n "$XCODEGEN_BIN" && -x "$XCODEGEN_BIN" ]]; then
    INSTALLED_VERSION=$("$XCODEGEN_BIN" --version | awk '{print $2}')
    if [[ "$INSTALLED_VERSION" == "2.45.4" ]]; then
        CHECK_PARENT=$(mktemp -d /tmp/stagepane-xcodegen-check.XXXXXX)
        cleanup() {
            if [[ -n "${CHECK_PARENT:-}" && -d "$CHECK_PARENT" && \
                  "$CHECK_PARENT" == /tmp/stagepane-xcodegen-check.* ]]; then
                rm -rf -- "$CHECK_PARENT"
            fi
        }
        trap cleanup EXIT
        CHECK_ROOT="$CHECK_PARENT/StagePane"
        mkdir -p "$CHECK_ROOT"
        cp "$PROJECT_DIR/project.yml" "$CHECK_ROOT/project.yml"
        cp -R "$PROJECT_DIR/Sources" "$CHECK_ROOT/Sources"
        cp -R "$PROJECT_DIR/Resources" "$CHECK_ROOT/Resources"
        (
            cd "$CHECK_ROOT"
            "$XCODEGEN_BIN" -q
        )
        cmp -s "$PROJECT_DIR/StagePane.xcodeproj/project.pbxproj" \
            "$CHECK_ROOT/StagePane.xcodeproj/project.pbxproj"
        cmp -s "$PROJECT_DIR/StagePane.xcodeproj/project.xcworkspace/contents.xcworkspacedata" \
            "$CHECK_ROOT/StagePane.xcodeproj/project.xcworkspace/contents.xcworkspacedata"
        cmp -s "$PROJECT_DIR/StagePane.xcodeproj/xcshareddata/xcschemes/StagePane-AppStore.xcscheme" \
            "$CHECK_ROOT/StagePane.xcodeproj/xcshareddata/xcschemes/StagePane-AppStore.xcscheme"
    else
        print "Skipping live regeneration: XcodeGen $INSTALLED_VERSION is not locked version 2.45.4"
    fi
fi

print "XcodeGen input/output drift check passed"
