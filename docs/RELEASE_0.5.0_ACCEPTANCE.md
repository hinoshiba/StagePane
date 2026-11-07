# StagePane 0.5.0 acceptance preparation

Status: **Not accepted. The release owner assigned 0.5.0 (build 14); review
and exact-candidate manual acceptance are still required before merge.**

Preparation started from a clean local `main` equal to canonical `origin/main`
at `ee1a1efda0315d0d2d583d634db544e5bc38dc3a` on 2026-11-07. Existing feature
work was preserved and applied after that baseline check. The release branch
is `codex/release-0.5.0`. App Store Connect's macOS Build Uploads was checked on
the same day: the largest uploaded build is 13, version 0.4.6; that version is
Ready for Distribution. The new build is 14 and the recorded upload floor is 13.

Follow [RELEASE.md](RELEASE.md) and [AGENTS.md](../AGENTS.md). This document does
not record a completed review, acceptance, tag, archive, upload, submission, or
public release. Keep account information, private test material, signing
inventory, and Organizer output outside the public repository.

## Changes to review

- Two screens in Free and ten in Pro, with Free's four-source limit per screen.
  A screen tab selects the private preview; Send to Stage changes the audience
  composition in the same Stage window. Blue identifies editing and red plus a
  label identifies Stage output. Editing output applies immediately, and
  switching preserves Curtain. Screens and layouts are session-only.
- Independent compact Screens and Layers, persisted display preferences,
  restored layer-list width, keyboard/context-menu access, and removal of the
  repeated meeting-sharing caption.
- Shared native capture for matching picker-authorized single windows on
  macOS 15.2+, with independent placement, crop, color, and rendering. Cursor
  requirements can split inputs. Older macOS and other filter types use the
  conservative same-filter-instance fallback.
- Hide/Remove affects a subscriber. Other subscribers can keep the input and
  its latest frame alive; the last active subscriber stops capture. Stop All,
  system revocation, and Quit cover all affected screens. Privacy and metadata
  text now describes this retention behavior.
- Pro revocation locks excess screens and ends their capture. Unavailable
  output closes Curtain and falls back; layouts remain in memory. Restoring
  Pro requires new source selection for those screens.

See [SCREEN_GROUPS_REVIEW.md](SCREEN_GROUPS_REVIEW.md) for feature-level tests
and the limits of earlier synthetic and native-development observations.

## Development validation, not manual acceptance

Local source gates, all 291 tests, strict compilation, and the unsigned universal
Store build passed on macOS 26.5.2 (arm64). Both language fixture runs passed
the 61-image name/dimension/opacity checks. Record the final signed commit,
tree, CI runs, and command results in the PR.
The source-built app is a development artifact and must not be distributed.

| Check | Required evidence |
| --- | --- |
| Source and regression gates | `./build.sh` / `Scripts/release-check.sh`: 291 tests, generated-project consistency, source and archive-guard checks |
| Strict compilation | Complete concurrency checking with warnings treated as errors |
| Store project | Unsigned Release build for arm64 and x86_64; version 0.5.0 and build 14 verified |
| Native synthetic fixtures | 61 opaque PNGs per language; Japanese and English names/dimensions match CI, with expanded/compact rails, preview/output, settings and Free/Pro comparison inspected |
| Website assets | Regenerated localized images and Open Graph assets; plan limits and retention copy aligned with the app |
| Public metadata | Japanese/English release notes, descriptions, review notes, bundled privacy/help, and SBOM updated; both review-note alternatives fit 4,000 UTF-8 bytes |

The snapshot renderer lets AppKit-backed controls complete initial layout
before caching their off-screen view. Fixture generation uses no real screen
capture. Its source-build Pro access is not evidence of StoreKit behavior.

## Exact-candidate manual acceptance still required

| Area | Required result | Status |
| --- | --- | --- |
| Environment coverage | Supported macOS versions and Apple Silicon/Intel, with hardware and app/OS versions recorded | Pending |
| Preview versus output | Private preview edits remain private; Send to Stage retains window identity and Curtain; output edits, shape, ink, magnifier and PNG use the correct screen | Pending |
| Limits and lifecycle | Free 2/4 and Pro 10 limits, group deletion/failure/retry, switching guards, all-screen Stop All and Quit | Pending |
| Input reuse | Real static/moving windows across layers/screens, crop/size/color independence, cursor modes, replacing/removing/hiding one subscriber, last subscriber and system revocation | Pending |
| Capture reliability | Picker approvals/cancel and permission changes, long-session behavior, recovery, real meeting receiver, and no stale-pixel disclosure | Pending |
| Compact navigation | Both rails, keyboard/context menus, width and preference restoration, VoiceOver, Increase Contrast and Reduce Motion | Pending |
| StoreKit | Localized price, purchase/cancel/pending/restore, third-screen/fifth-source continuation, revocation and restoration in an actual Store review environment | Pending |
| Store presentation | Exact Store-candidate product and IAP review screenshots, localized metadata, privacy answers and selected release mode | Pending |

The complete matrix in RELEASE.md remains applicable. Earlier TCC and
long-session capture limitations are not claimed resolved by the shared-input
change. Synthetic tests do not establish CPU/GPU/WindowServer savings.

GitHub retired macOS 14 hosted runners on 2026-11-02. CI now uses the standard
`macos-15-intel` and `macos-15` runners, preserving Xcode 16.2 SDK coverage on
Intel. The app's minimum remains macOS 14; actual macOS 14 runtime acceptance
is still required and is not established by those runners. See the
[official retirement announcement](https://github.com/actions/runner-images/issues/13518)
and [Intel image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md).

## Promotion gates

1. Complete review, passing PR CI, and exact-candidate manual acceptance. Keep
   every release commit cryptographically signed with a DCO Signed-off-by.
2. Use a normal merge commit; verify accepted-tree equality and passing
   merged-main CI before creating a new immutable signed `v0.5.0` tag.
3. Recheck that build 14 has not been consumed. Archive only through
   `Scripts/archive-app-store.sh` on the clean, reviewed, tagged `main`.
4. The release owner privately verifies Distribution Summary and performs the
   authorized upload in Xcode Organizer. Wait for exact-build processing.
5. Verify matching metadata and the exact build in App Store Connect. Confirm
   the release mode and the owner’s submission/public-release authorization
   before those actions. The version/build assignment alone is not a release
   mode decision or proof that any gate passed.

The existing Pages workflow deploys `site/` on every `main` push. This PR's
website changes therefore go live at merge. Coordinate that promotion with
availability of the new App Store features; PR preview images and a local
website check are not a website deployment or an App Store release.
