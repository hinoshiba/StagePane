# StagePane 0.4.6 acceptance preparation

Status: **Not accepted. Version 0.4.6 (build 13) is assigned by the release owner;
review and exact-candidate manual acceptance remain pending.**

The permission-flow fix is prepared on `codex/release-0.4.6`, starting from clean
canonical `main` at `a2830bc858ca749e70afdc2f9adfd7b66d9f5888`.
The latest uploaded build was rechecked in App Store Connect on 2026-11-03:
0.4.5 (12). The checked-in version/build is 0.4.6 (13), and the uploaded-build
floor is 12. The release owner authorized automatic release after App Review
approval. That mode still needs to be saved and verified in App Store Connect
before submission. No tag, archive, upload, or submission is represented by this
document.

Follow [RELEASE.md](RELEASE.md) and [AGENTS.md](../AGENTS.md). Keep private test
content, account details, credentials, signing inventory, and Organizer output
outside this public repository.

## Change and review focus

Issue [#36](https://github.com/hinoshiba/StagePane/issues/36) tracks removal of the
custom Screen Recording permission pre-alert. First and repeat launch open
Workspace directly. Add Source retains Apple's ScreenCaptureKit picker. The
optional app-wide request now goes directly from Access & Privacy settings to
macOS, with status and System Settings recovery in that pane. There is no
app-controlled Allow decision or separate Continue dismissal.

This follows Apple's [permission-request design guidance](https://developer.apple.com/design/human-interface-guidelines/privacy#Requesting-permission).
The capture implementation and its previous live-validation limitations are
unchanged. This change does not establish that the reported long-session freeze
is fixed, that broader access resolves TCC failures, or that StoreKit purchase
and restore acceptance is complete.

## Development verification — not release acceptance

The source-built development app is ad-hoc signed and must not be distributed.
Record final command results in the PR after running checks against its exact
head. Synthetic fixtures do not exercise real macOS permission prompts.

| Check | Evidence / scope |
| --- | --- |
| Automated permission regressions | Fresh launch without the legacy onboarding flag; activation before opening Settings; status-only Settings opening; direct request; denial/repeated action; existing access; refreshed status after a system change |
| Source checks | `Scripts/release-check.sh`, generated-project drift, and strict concurrency with warnings as errors |
| Local bundle | `build.sh` development build with sandbox verification; no official archive |
| Synthetic fixtures | 49 English and 49 Japanese PNG names/dimensions checked; request, post-request denied, and allowed Settings states in light/dark appearance inspected |
| Native development smoke test | Japanese launch and relaunch showed Workspace without the old guide; Command-comma and Access & Privacy exposed the new controls; request returned to denied-status recovery without the old dialog; Add Source opened the native picker directly and its Cancel returned to idle with Add Source enabled and no error |
| Limits of native smoke test | No fresh native permission dialog or grant verified; system permission state was not reset. Full live capture and accessibility acceptance remain pending. |

## Before merge, tag, and archive

- Version/build assignment, the live uploaded-build floor, `Info.plist`,
  `project.yml`, generated Xcode project/lock, and SBOM are prepared for
  0.4.6 (13). Recheck the live upload history before archiving; do not reuse
  build 13 if another upload has consumed it.
- Complete review and passing PR CI against the final signed, DCO-signed-off
  release commit. Complete the full exact-candidate manual matrix in RELEASE.md,
  including the permission cases below and all outstanding capture/StoreKit
  cases. Do not promote the development smoke test into release acceptance.
- Use a normal merge commit. Verify merged-main tree equality and passing
  merged-main CI before making a new immutable annotated signed tag.
- Archive only with `Scripts/archive-app-store.sh`. The release owner verifies
  Distribution Summary privately and performs the authorized Organizer upload
  manually. Wait for the exact build to finish processing.
- Save matching Japanese/English metadata and review notes, select the exact
  processed build, and save and verify automatic release after approval before
  the authorized submission. The release owner's authorization includes that
  future public release.

## Exact-candidate permission matrix

| Case | Required result | Status |
| --- | --- | --- |
| Fresh installation and upgrade | No custom permission guide or app-wide request at first/repeat launch, regardless of the old onboarding flag | Pending |
| Access & Privacy | Status reads without a request; localized names, non-color status, VoiceOver and keyboard operation | Pending |
| Fresh app-wide request | Explicit Settings action goes straight to the macOS request without an intermediate app window; grant/deny are system choices | Pending |
| Denial | No automatic repeat on activation or settings reopening; source selection remains available; System Settings recovery is reachable | Pending |
| Existing or changed access | Existing access skips another request; activation after a System Settings change refreshes status | Pending |
| Source picker | Window/app/display selection and cancellation, including without app-wide access, with truthful error handling and no unrelated permission request | Pending |
| Capture and commerce | Full release matrix, exact Store candidate, supported environments, long-session checks, and StoreKit evidence | Pending |

Retain the final commit/tree, review, CI, manual evidence, tag object/target,
version/build, upload, processing, and submission identifiers in the private
release record. No gate is passed merely because it appears in this checklist.
