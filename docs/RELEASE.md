# App Store release operations

StagePane is distributed through the Mac App Store. Official binaries are
built locally from reviewed `main` commits carrying annotated signed
semantic-version tags that are never moved or reused.
`Scripts/archive-app-store.sh` is the only authorized
Archive entrypoint. It pins the checked-in `StagePane-AppStore` scheme, uses
automatic signing, verifies the archive, and opens it in Xcode Organizer.
Upload, TestFlight distribution, App Review submission, and public release are
separate explicit actions.

`./build.sh` remains available only for local development. By default its
`dist/StagePane.app` is ad-hoc signed. A developer may set
`STAGEPANE_LOCAL_SIGNING_IDENTITY` to an existing, caller-managed Keychain
identity for development signing. The value stays outside the repository and
the script neither discovers nor prints it. Both signing modes use the same App
Sandbox entitlements and Arrange/Crop/Draw feature set as the Store target, retain
Hardened Runtime, and must never be published. This opt-in has no effect on the
separate Mac App Store archive path.

## Local Organizer release authority

The release owner must use a Mac signed into Xcode with access to Apple
Developer Team `94HVVWXLK3`. Keep automatic signing enabled. Reuse the existing
approved team distribution path; do not create, revoke, rotate, import, export,
or force a signing identity or provisioning profile as a retry. Never add
`-allowProvisioningUpdates`, `CODE_SIGN_IDENTITY`, a certificate fingerprint,
profile content, private key, `.p12`, or App Store Connect credential to a
command, tracked file, log, or release record.

Before each release, inspect **App Store Connect > StagePane > TestFlight >
macOS > Build Uploads** and record the largest uploaded build number. Update
`STAGEPANE_PREVIOUS_UPLOADED_BUILD` in `project.yml` to that value and set
`CURRENT_PROJECT_VERSION` plus the development `Info.plist` build to a strictly
larger canonical integer. macOS build numbers must increase across every
marketing version. For StagePane 0.3.2, the verified uploaded floor is `5` and
the candidate build is `6`.

The exact candidate commit must:

- be a clean local `main` checkout equal to the canonical public repository's
  live `main`;
- have passing GitHub CI and the completed manual acceptance record;
- carry an annotated signed `v<major>.<minor>.<patch>` tag whose version equals
  `MARKETING_VERSION` and whose remote dereference resolves to that commit; and
- retain the checked-in Team, bundle ID, automatic signing, sandbox,
  Hardened Runtime, Release configuration, and universal architectures.

Never move, replace, or reuse a release tag. Record its tag object ID and commit
SHA in the private release record. The App Store target build phase rejects
normal raw Product > Archive, raw `xcodebuild archive`, and every Xcode Cloud
Archive action. Only `Scripts/archive-app-store.sh` creates and consumes the
one-time local authorization context after independently checking the release
source. This keeps one auditable Archive path while still handing the verified
result to Organizer.

## Prepare a release change

Update and review these values in one pull request:

- `Info.plist`: `CFBundleShortVersionString` and `CFBundleVersion`
- `project.yml`: `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, and
  `STAGEPANE_PREVIOUS_UPLOADED_BUILD`
- the checked-in Xcode project regenerated with XcodeGen 2.45.4
- `CHANGELOG.md`, App Store metadata, privacy answers, and review notes when
  behavior or claims changed
- localized website fixture screenshots and Open Graph images regenerated
  whenever an audience-visible default or Workspace layout changes. The
  source-built `dist` app intentionally has full Pro access, so these generated
  fixtures are not evidence of the Free commerce state. Label every image that
  shows more than four sources or an optional mark as StagePane Pro, but do not
  present a composition of four or fewer sources as a Pro-only unlock merely
  because the fixture build has Pro access. Because the app is sandboxed, write
  snapshots inside its app container, then copy the completed PNGs to the review
  workspace. Run once for each language, using a different generated directory:

  ```bash
  SNAPSHOT_PARENT="$HOME/Library/Containers/com.hinoshiba.stagepane/Data/tmp"
  mkdir -p "$SNAPSHOT_PARENT"
  SNAPSHOT_DIR="$(mktemp -d "$SNAPSHOT_PARENT/stagepane-release-shots.XXXXXX")"
  STAGEPANE_LANGUAGE=en \
    dist/StagePane.app/Contents/MacOS/StagePane --snapshot "$SNAPSHOT_DIR"
  ```

  `workspace.png`, `arrange.png`, `draw.png`, `sources.png`, `permissions.png`,
  `privacy.png`, `appearance.png`, and source-build `pro.png` must be opaque
  2880×1800 images. The
  1920×1080 Stage-only snapshots are website and QA assets, not valid Mac App
  Store upload dimensions. Do not use an arbitrary `/tmp` or repository
  directory as the sandboxed app's snapshot destination. Separately capture
  customer-facing Product Page screenshots from the exact `StagePane-AppStore`
  candidate. Label every gated feature “StagePane Pro” or “In-App Purchase” in
  its image/caption, but do not bake a price into these storefront-wide assets.
  Capture the review-only IAP App Review Screenshot from the real Pro screen
  under StoreKit Configuration, Sandbox, or TestFlight; it must show the
  localized `displayPrice`, one-time wording, Restore Purchases, and Continue
  Free. Never use the source-build active-entitlement fixture as IAP review
  evidence
- `THIRD_PARTY_NOTICES.md` and `docs/sbom.spdx.json` when their inventory or
  version changes

After changing `project.yml`, regenerate and verify the checked-in project:

```bash
/opt/homebrew/bin/xcodegen generate
./Scripts/check-xcodegen-drift.sh --print-lock > Config/XcodeGen.lock
./Scripts/check-xcodegen-drift.sh
```

Run the source gates and manual acceptance matrix before merging:

```bash
./Scripts/release-check.sh
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

Manual acceptance must cover supported macOS versions and architectures plus:

- per-selection `SCContentSharingPicker` approval and cancellation, including
  confirmation that the app requests no separate broad Screen Recording access
  and exposes no Screen Recording settings step in the source flow; end access
  by removing the source or stopping all sources;
- one-item window/application/display selection; Free mixed-source addition
  through 4/4 with the still-enabled fifth-source action opening StagePane Pro;
  Pro mixed-source addition at source five and beyond while Mac performance and
  operating-system constraints permit; no app-imposed Pro source-count ceiling;
- per-source pause and resume (stop the stream, make the layer transparent in
  Stage, Workspace, and Audience PNG while preserving placement/crop/z-order,
  then reveal it only after Resume receives a new complete frame), replace
  (with cancel preserving the old item), per-source removal while other streams
  remain live, and Stop All deleting pixels and logical state for every source;
- initial picture-in-picture placement, all four Quick Layout presets, boundary-clamped drag,
  free resize/minimum tile size, front ordering, matching Workspace/Stage
  layouts, and the Workspace's 900×620-point minimum content size;
- strict two-window separation: the private Workspace contains the Canvas and
  Docker-style sidebar for Sources, Stage Settings, Appearance, Permissions,
  Privacy, and About; its Canvas has Arrange and Draw global modes plus a Crop
  action on each layer; the public Stage has no private toolbar, mode control,
  selection outline, resize handle, notice, or other editing chrome;
- exact-window sharing guidance that never claims Workspace can
  be technically excluded from capture; verify application and full-display
  sharing can expose private windows and the UI directs users to choose the
  exact `StagePane Stage` window;
- Workspace close/reopen while live, drawing, resizing, choosing, and paused:
  closing ends an active stroke without stopping capture, clearing completed ink,
  closing Stage, or corrupting layout;
  closing the public Stage covers audience output without stopping capture or
  clearing layer placement/crop, and reopening starts covered by the Curtain;
- live source-window aspect changes, including a static slide after a layout or
  source resize, with no double letterbox and no transient black tile;
- Curtain hiding only the public Stage while the private Workspace remains
  live, without bringing Stage to the front, plus a fresh-container default-on
  translucent lower-right StagePane mark on the holding screen, shared content,
  and Curtain and its WYSIWYG Workspace mirror; confirm Free cannot hide it even
  when an older local preference is false; then purchase Pro, toggle it off,
  relaunch, and confirm the preference and verified entitlement restore;
- all Stage shapes and all three pointer styles, including one laser dot aligned
  only to the frontmost source, no dot and no fallback when that source is
  paused, exact fresh-container and Reset defaults of 22 pt, `#FF3B30`, and 55%
  glow, adjustable color/size/glow, relaunch persistence, live style/source
  changes, a static System-to-Laser transition
  with no native/laser double pointer (advance the slide if macOS defers the first
  cursorless complete frame), and removal on Curtain/stop;
- Arrange-mode drag/resize affecting only composition, with global Arrange and
  Draw plus a crop button on every layer available in Workspace in both the local sandboxed build and exact Mac App
  Store candidate on every supported OS; confirm the persistent Permissions view
  describes only picker-scoped screen-sharing session access and neither build
  contains a cross-application input-forwarding or Accessibility permission path;
- each tile and source row opening Crop for that exact layer at full Canvas size
  in the private Workspace; verify the target layer name, drag, four-corner
  resize, keyboard and VoiceOver actions;
  Reset to Full Source changes only the draft; Apply Crop is the only commit;
  Cancel, a mode change, or source loss discards the draft; the public Stage,
  laser projection, and every Audience PNG preset retain the previously applied
  crop until Apply; applied crop geometry remains in memory for the current
  StagePane run and survives source-sharing disconnects on retained layers; Crop never
  narrows the complete picker-approved source handled by a running
  ScreenCaptureKit stream;
- Draw-mode Stage/Workspace alignment, single-point and long strokes, Pen and
  Highlighter opacity, partial Eraser sizing and cursor, erase-over-crossing-lines,
  draw-after-erase ordering, exact Undo restoration, memory bounds, Clear
  confirmation, automatic audience-pointer hiding on entry, restoration of the
  latest selected pointer style on return to Arrange or Crop, pointer-style changes made
  while Draw remains active, Curtain hiding ink, intermediate-source
  removal preserving ink, and Stop All/final-source removal clearing it;
- destructive confirmation from both source-list and Workspace-context Remove,
  including destructive/cancel semantics, VoiceOver and keyboard paths,
  cancellation preserving stream/frame/layout, and source-state changes while
  the dialog is open;
- no redundant privacy slogans in the Stage dashboard or Workspace sidebar,
  no Important Limitation card in About, and the complete Privacy screen still
  available;
- explicit one-shot screenshot Copy and Save for every Stage preset: exact
  preset pixel dimensions; clean Audience Stage only; correct source layout and
  current content-or-Curtain, ink, watermark, safe-area guide when enabled, and
  pointer when visible; no Workspace navigation/controls or title-bar UI; Copy
  provides a readable PNG on the pasteboard; Save writes one readable PNG only to
  the selected location; save
  cancellation writes nothing and does not alter the clipboard; missing fresh
  frames fail visibly instead of exporting a black tile;
- screenshot permission/privacy behavior: no action at launch or in the
  background, no recording or screen upload, no new Screen Recording or other
  permission, no unrelated-window enumeration, and no retained screenshot
  history after the explicit copy/save completes;
- no Accessibility or Input Monitoring request, raw mouse/keyboard event
  synthesis, keyboard capture/forwarding, or event tap; keyboard/VoiceOver
  Arrange, Crop, and Draw actions; Spaces/full-screen/display
  changes; four-source Free CPU/memory plus higher-count Pro CPU/memory and
  graceful system-resource failure; and the currently claimed meeting-app
  workflows.
- StoreKit Configuration, Sandbox, and TestFlight purchase paths: localized
  `Product.displayPrice`, verified success, cancel, pending/Ask to Buy, product
  load failure and retry, restore, reinstall/second Mac, refund/revocation, and
  rejection of unverified transactions; purchase success must resume the exact
  fifth-source or mark-removal action that opened Pro; entitlement loss with
  more than four sources must preserve the existing session and block only new
  additions.

Record the exact commit, hardware, OS/app versions, results, and approved
exceptions in the release record.

## Create the release tag

Only tag the reviewed commit after GitHub CI and manual acceptance pass. The tag
must be exactly `v<major>.<minor>.<patch>` and its version must equal
`MARKETING_VERSION`:

```bash
git tag -s v0.3.2 -m "StagePane 0.3.2"
git push origin v0.3.2
```

Confirm the signed local tag and its pushed dereference both resolve to the
reviewed `main` commit. Do not create the tag from a release branch and do not
retag after an Archive or upload.

## Create and verify the local archive

Run the only authorized entrypoint from the clean tagged `main` checkout:

```bash
./Scripts/archive-app-store.sh
```

The helper runs the complete source checks, creates a new temporary directory
outside the checkout, and invokes Xcode with fixed project, scheme,
configuration, platform, and archive path arguments. It deliberately omits
upload/export options, `-allowProvisioningUpdates`, and signing-identity
overrides. The target Archive guard independently verifies the canonical
repository's live `main` commit, the exact signed remote tag object,
version/build floor, Team, bundle ID, automatic signing, sandbox, Hardened
Runtime, and universal settings. The helper repeats source, branch, remote, and
tag verification after the build to catch changes before Organizer opens.

After Xcode succeeds, `verify-app-store-archive.sh` checks Apple-anchored
code-signature validity and cryptographic Team identity, archive metadata,
bundle ID, version/build, both architectures, the exact entitlement set,
byte-identical reviewed resources, privacy manifest, unexpected executables,
and absolute `LC_RPATH` entries. Only then does the helper open the `.xcarchive`
in Xcode Organizer. An Archive can be development-signed; Organizer may select
the final Mac App Distribution application and installer signing path during
distribution. Verify the final signer against the maintainer's private approved
inventory in Organizer's Distribution Summary without copying signer details
into the repository or public logs. Stop before upload if that identity cannot
be verified.

## Verify and submit

In Xcode Organizer and App Store Connect, verify:

- source tag and commit, Xcode/macOS versions, version/build, local archive
  verification, and Organizer Distribution Summary;
- bundle ID `com.hinoshiba.stagepane`, Team `94HVVWXLK3`, App Sandbox,
  Hardened Runtime, privacy manifest, icon, localizations, and legal/help
  resources;
- Arrange, Crop, and Draw present, with no cross-application input-forwarding or
  Accessibility permission path in the archived Mac App Store candidate; the
  Permissions view must show only the picker-scoped sharing explanation;
- no unexpected entitlement, embedded executable/framework, absolute
  `LC_RPATH`, updater, analytics, automatic screenshot, recording, publisher
  server, or screen-upload path; confirm Apple StoreKit is the only commerce
  service and the only image export is the documented explicit local PNG
  copy/save path; and
- metadata, screenshots, privacy answers, export compliance, review notes,
  pricing, territories, and release mode against the exact build.

Preserve the local archive, validation result, upload result, and final
Distribution Summary reference in the private release record. Do not commit the
archive, package, profiles, certificates, signing inventory, or credentials.

Creating an Archive does not authorize Organizer validation/distribution or
upload. Uploading does not authorize selecting the build for an App Store
version, distributing to testers, adding it for review, submitting for review,
or releasing it. Treat every action as a separate handoff and do not perform it
without the release owner's explicit approval.
