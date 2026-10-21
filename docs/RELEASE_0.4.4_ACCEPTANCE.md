# StagePane 0.4.4 (11) acceptance template

Status: **Not accepted. Candidate verification and manual acceptance are pending.**

This is a public template, not evidence that a release gate passed. Copy it to
the private release record and fill it against the exact release candidate.
Follow [RELEASE.md](RELEASE.md) and [AGENTS.md](../AGENTS.md); this template does
not replace their full matrix or authorize tagging, archiving, uploading,
submission, or release. Keep credentials, profiles, certificate details,
signing inventory, and private test content out of this file and the repository.

## Candidate identity

| Field | Intended value or evidence to record |
| --- | --- |
| Marketing version / build | 0.4.4 / 11; verify generated project and binary |
| Previous uploaded build floor | 10; retain the live App Store Connect check in the private record |
| Preparation branch | `codex/release-0.4.4` |
| Preparation base | `420473992a4e06aa3c892fcb5939e96dacae7a0c` |
| Exact candidate commit and tree | Pending |
| Release commit signature and DCO verification | Pending; record result without private signing details |
| Non-draft release PR and independent review | Pending |
| Candidate CI and source gates | Pending |
| Merged-main commit, accepted-tree equality, and CI | Pending |
| Immutable signed tag object and target commit | Pending; only after review, CI, and acceptance |

Prior source tests, synthetic screenshots, and native Settings checks are
recorded in [the UI review log](UI_REDESIGN_REVIEW_LOG.ja.md). They are not
acceptance of this exact release candidate. That log explicitly leaves live
capture, Crop draft preservation, picker/StoreKit Curtain access, meeting
sharing, and full VoiceOver paths unverified.

## Environment and evidence

Record each tested hardware/architecture, macOS build, Xcode version, display
and scale, language/appearance, meeting-app version/settings, purchase test
environment, tester, date, and evidence reference. Cover the supported OS and
architecture matrix required by RELEASE.md; an unsigned arm64 Debug build or
synthetic fixture is not a substitute for the exact Mac App Store candidate.

| Environment | Candidate commit/build | Tester/date | Evidence |
| --- | --- | --- | --- |
| Pending | Pending | Pending | Pending |

## Pre-merge verification

Every row is pending. These groups index the full manual matrix in RELEASE.md;
marking a group complete requires all its applicable scenarios and recorded
results, including failures. Do not treat an untested case as passed.

| Area | Required evidence | Status |
| --- | --- | --- |
| Source gates | `release-check.sh`, strict concurrency with warnings as errors, generated-project drift, exact version/build/floor and dependency/legal inventory | Pending |
| Screenshots and localization | 49 fixture names/dimensions per language, Japanese/English visual review, native Settings toolbar/focus separately; customer-facing and IAP review images from the required candidate/purchase state | Pending |
| Permission and picker lifecycle | Window/app/display consent and cancellation without optional app-wide access; first-launch guide, explicit Allow, later-launch behavior, Access & Privacy manual check | Pending |
| Free/Pro source lifecycle | Four Free sources and fifth-source upgrade; Pro sources beyond four; Hide/Show fresh frames, replace/cancel, disconnect/reselect, removal, Stop All, no stale pixels | Pending |
| Layout and layer operations | Minimum Workspace size, all Quick Layouts, move/resize bounds, overlaps, z-order, hidden/rear selection, keyboard and VoiceOver | Pending |
| Layer names | Save/cancel/reset, list/Canvas/Crop consistency, reconnect and layout retention, teardown, no custom names in audience output or PNG | Pending |
| Color inversion | Stage/Workspace/magnifier/PNG agreement, crops and overlaps, unchanged ink/laser colors, Hide/Show and reconnect, every Stage shape | Pending |
| Native Settings | All entry points and five panes, first/last/explicit pane, persistent preferences, no duplicate Workspace settings, live capture/tool/Crop draft preservation | Pending |
| Settings focus and safety | Shape/enlargement keeps Settings and its input active; closing returns to valid origin without reviving stale focus; picker/StoreKit Curtain reachability | Pending |
| Stage menus and window lifecycle | Right-click/Control-click and menu-bar parity, maximize/restore, stable share identity, window protection, close/reopen, full-screen/Spaces/display transitions | Pending |
| Audience separation and meeting output | Exact Stage-window sharing, private UI exclusion, full-app/display exposure guidance, all shapes, received dimensions, claimed meeting-app workflows | Pending |
| Pointer, Draw, Magnify, Crop, Curtain | Complete interaction matrix; shared saved pointer choice and temporary suppression; draft/apply/cancel; audience/preview/export alignment; ink undo/clear and teardown | Pending |
| PNG and privacy | All preset dimensions and effects; explicit copy/save/cancel; fresh-frame failures; no background export, new permission, or retained image history | Pending |
| StoreKit | Configuration, Sandbox, and TestFlight paths; localized price, success/cancel/pending/load failure/retry/restore/reinstall/revocation/unverified transactions | Pending |
| Purchase continuation | Current fifth-source/mark request resumes once; stale or direct requests do not auto-run; explicit continuation after external authentication; entitlement loss preserves existing sessions | Pending |
| Performance and accessibility | Free four-source and higher-count Pro soak, resource failures, keyboard and complete VoiceOver paths across supported environments | Pending |

## Review, merge, and owner handoffs

| Gate | Status and evidence to record |
| --- | --- |
| All required manual cases and independent review complete | Pending |
| Any permitted exception | None recorded; record approver, evidence, date, scope, and expiry. Do not waive mandatory source, tag, archive, or owner-authorization rules. |
| Non-draft release PR CI passed and normal merge completed | Pending |
| Merged main equals the accepted tree and its CI passed | Pending; repeat review/acceptance if the tree differs |
| New immutable signed version tag points to reviewed main | Pending |
| `Scripts/archive-app-store.sh` verification and Organizer archive | Pending; retain archive and private verification record outside the checkout |
| Owner Distribution Summary check and manual Organizer upload | Pending; no automated or alternate upload path |
| Exact uploaded version/build processing complete | Pending; do not re-upload while processing |
| Product-page metadata, privacy answers, review notes, screenshots, and build selection | Pending; verify saved Japanese/English state against the exact binary |
| Release mode and final Submit-for-Review authorization | Pending; automatic release requires approval of the future public release |
| Submission ID, timestamp, exact version/build, authoritative status | Pending |
| Public release if manual mode was chosen | Pending; separate owner authorization required |

Do not add signer identifiers, certificates, provisioning profiles, account
details, or private Organizer output when completing the record. Public commit,
tree, tag, PR, CI, version/build, and sanitized test-result references suffice
for a public summary.
