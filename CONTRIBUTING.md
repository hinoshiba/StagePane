# Contributing to StagePane

Thank you for helping make screen sharing calmer and safer.

## Before coding

For substantial behavior, privacy, dependency, permission, brand, or public-API
changes, open an issue first. Explain the user problem, security/privacy impact,
App Store impact, alternatives, accessibility plan, and validation plan.

Never include real meeting screenshots, private window titles, access tokens,
private signing keys, exported signing identities, App Store Connect keys,
Apple Account credentials, user data, or proprietary assets in an issue, test,
fixture, log, or pull request.

## Build and test

```bash
swift test
./build.sh
open dist/StagePane.app
```

Before proposing a change:

```bash
./Scripts/release-check.sh
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

UI changes must be checked in Japanese and English, light and dark appearance,
VoiceOver, keyboard-only navigation, Increase Contrast, and Reduce Motion.
Capture changes require approved/declined/revoked permission states and a
manual leak/retention check.

## Architectural constraints

- Public Apple APIs only; never add undocumented `CGVirtualDisplay` calls.
- No raw mouse/keyboard event synthesis, keyboard/drag forwarding, event taps,
  unattended remote control, generic canvas/content control, or input to
  ambiguous/app/display sources. The sandboxed Mac App Store build must omit
  Press Buttons and its cross-application Accessibility permission/action path. In an
  unsandboxed local development build on macOS 15.2 or later, a Press-Buttons
  accessibility Press must retain explicit Accessibility consent, exact
  single-window scope, supported-action checks, and fresh displayed-frame
  validation.
- No network, analytics, advertising, recording, audio, account, or updater
  dependency without an approved product/privacy proposal.
- Use `SCContentSharingPicker` for consent. Do not build a covert window-title
  inventory.
- Preserve the explicit difference between Curtain (hide) and Stop (end capture).
- Workspace is not assumed to be technically unshareable; its title and user
  guidance remain part of the safety design.

## Dependencies and assets

The default answer to a new dependency is “not yet.” A proposal must include
origin, exact version, integrity verification, full transitive license tree,
binary/runtime behavior, privacy manifest, update cadence, alternatives, and
SBOM/NOTICE changes. GPL/AGPL, field-of-use restrictions, private SDKs, remote
code loading, and unknown/proprietary assets are not accepted for the core app.

## Developer Certificate of Origin

Contributions use the Developer Certificate of Origin 1.1. Add this line to each
commit message:

```text
Signed-off-by: Your Name <your-email@example.com>
```

By signing off, you certify that you wrote the contribution or otherwise have
the right to submit it under the project's Apache-2.0 license, as described at
<https://developercertificate.org/>. This is not a copyright assignment and
does not grant the project rights to relicense a contribution under proprietary
terms.

## Pull requests

- Keep one coherent change per pull request.
- Add or update tests and user/privacy/release documentation.
- Include before/after images for UI changes using synthetic content only.
- List manual OS/hardware/meeting-app testing actually performed.
- Mark modified upstream-derived files prominently if the project ever accepts
  such code and preserve all required notices.
- Do not change signing, release, license, privacy, or trademark policy without
  explicit maintainer and appropriate professional review.
