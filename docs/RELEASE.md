# App Store release operations

StagePane is distributed through the Mac App Store. Official binaries are
built and uploaded by Xcode Cloud from immutable semantic-version tags; there
is no local release signing, notarization, DMG, archive, or upload procedure.

`./build.sh` remains available only for local development. By default its
`dist/StagePane.app` is ad-hoc signed. A developer may set
`STAGEPANE_LOCAL_SIGNING_IDENTITY` to an existing, caller-managed Keychain
identity for development signing. The value stays outside the repository and
the script neither discovers nor prints it. Both signing modes use the same App
Sandbox entitlements and Arrange/Draw feature set as the Store target, retain
Hardened Runtime, and must never be published. This opt-in has no effect on the
separate Xcode Cloud Mac App Store archive path.

## Xcode Cloud workflow

Complete the app's initial Xcode Cloud setup from Xcode. Edit the suggested
workflow to use a non-Archive **Build** action and run it once from `main`;
the release guard intentionally rejects an Archive without a release tag.
After that setup build, edit the workflow in Xcode or App Store Connect:

- **Name:** `App Store Release`
- **General:** enable **Restrict Editing** and limit workflow administrators to
  the designated release managers
- **Product:** StagePane (`com.hinoshiba.stagepane`), Team `94HVVWXLK3`
- **Repository:** `hinoshiba/StagePane`
- **Start condition:** Tag Changes; include `v*`
  and add no branch, pull-request, or schedule start condition; in this tag
  condition's **Options**, set **Auto-cancel Builds** to **Off** so a later tag
  cannot cancel an in-progress release archive
- **Environment:** the latest released macOS and Xcode; enable **Clean**
- **Action:** Archive, macOS, scheme `StagePane-AppStore`
- **Deployment Preparation:** `TestFlight and App Store`
- **Post-actions:** none by default. Add TestFlight distribution only after an
  intended tester group exists and the release owner approves automatic
  distribution to that exact group.

Keep automatic signing enabled. Xcode Cloud manages the distribution signing
assets; do not store certificates, profiles, App Store Connect keys, or Apple
Account credentials in this repository or in non-secret workflow variables.

After the non-Archive setup build succeeds, remove the generated branch/PR
start conditions from this release workflow and retain only the tag condition
above.

Xcode Cloud assigns the build number used by App Store Connect. Because this is
a macOS app, the build number must increase across all marketing versions. For
an existing app, open **App Store Connect > StagePane > Xcode Cloud > Settings
> Build Number** and set **Next Build Number** to an integer greater than the
largest build already uploaded for StagePane before the first tagged build.

## Protect release authority

Before enabling the release workflow, create an **Active** tag ruleset in
GitHub **Settings > Rules > Rulesets** for the `v*` target pattern. Enable
**Restrict creations**, **Restrict updates**, and **Restrict deletions**, and
allow bypass only for the designated release manager. Create a release tag only
on a reviewed `main` commit. Never move, replace, or reuse it. A permitted tag
creation authorizes Xcode Cloud to build and upload a signed candidate.

## Prepare a release change

Update and review these values in one pull request:

- `Info.plist`: `CFBundleShortVersionString`
- `project.yml`: `MARKETING_VERSION`
- the checked-in Xcode project regenerated with XcodeGen 2.45.4
- `CHANGELOG.md`, App Store metadata, privacy answers, and review notes when
  behavior or claims changed
- localized website screenshots and Open Graph images regenerated from the exact
  Mac App Store UI whenever an audience-visible default or Workspace layout
  changes; Store screenshots must show the Arrange and Draw workflow, and any
  Permissions screenshot must show only picker-scoped sharing access. Because
  the candidate is sandboxed, write snapshots inside its app container, then
  copy the completed PNGs to the review workspace. Run once for each language,
  using a different generated directory:

  ```bash
  SNAPSHOT_PARENT="$HOME/Library/Containers/com.hinoshiba.stagepane/Data/tmp"
  mkdir -p "$SNAPSHOT_PARENT"
  SNAPSHOT_DIR="$(mktemp -d "$SNAPSHOT_PARENT/stagepane-release-shots.XXXXXX")"
  STAGEPANE_LANGUAGE=en \
    dist/StagePane.app/Contents/MacOS/StagePane --snapshot "$SNAPSHOT_DIR"
  ```

  `workspace.png`, `arrange.png`, `draw.png`, `sources.png`, `permissions.png`,
  `privacy.png`, and `appearance.png` must be opaque 2880×1800 images. The
  1920×1080 Stage-only snapshots are website and QA assets, not valid Mac App
  Store upload dimensions. Do not use an arbitrary `/tmp` or repository
  directory as the sandboxed app's snapshot destination
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
- one-item window/application/display selection, mixed-source addition up to
  four, and a disabled Add Source action at 4/4;
- per-source pause and resume (stop the stream, retain the last frame in both
  renderers, then restart it), replace (with cancel preserving the old item),
  per-source removal while other streams remain live, and Stop All draining
  both renderers for every running or paused source;
- initial picture-in-picture placement, all four Quick Layout presets, boundary-clamped drag,
  free resize/minimum tile size, front ordering, matching Workspace/Stage
  layouts, and the Workspace's 900×620-point minimum content size;
- strict two-window separation: the private Workspace contains the Canvas and
  Docker-style sidebar for Sources, Stage Settings, Appearance, Permissions,
  Privacy, and About; its Canvas hosts Arrange and Draw; the public Stage has no
  private toolbar, mode control, selection outline, resize handle, notice, or
  other editing chrome;
- exact-window sharing guidance that never claims Workspace can
  be technically excluded from capture; verify application and full-display
  sharing can expose private windows and the UI directs users to choose the
  exact `StagePane Stage` window;
- Workspace close/reopen while live, drawing, resizing, choosing, and paused:
  closing ends an active stroke without stopping capture, clearing completed ink,
  closing Stage, or corrupting layout;
  closing the public Stage continues to cover output and stop active capture;
- live source-window aspect changes, including a static slide after a layout or
  source resize, with no double letterbox and no transient black tile;
- Curtain hiding only the public Stage while the private Workspace remains
  live, without bringing Stage to the front, plus a fresh-container default-on
  translucent lower-right StagePane mark on the holding screen, shared content,
  and Curtain and its WYSIWYG Workspace mirror; toggle it off, relaunch, and
  confirm the disabled preference persists;
- all Stage shapes and all three pointer styles, including one laser dot aligned
  only to the frontmost source, no dot and no fallback when that source is
  paused, exact fresh-container and Reset defaults of 22 pt, `#FF3B30`, and 55%
  glow, adjustable color/size/glow, relaunch persistence, live style/source
  changes, a static System-to-Laser transition
  with no native/laser double pointer (advance the slide if macOS defers the first
  cursorless complete frame), and removal on Curtain/stop;
- Arrange-mode drag/resize affecting only composition, with Arrange and Draw
  available in Workspace in both the local sandboxed build and exact Mac App
  Store candidate on every supported OS; confirm the persistent Permissions view
  describes only picker-scoped screen-sharing session access and neither build
  contains a cross-application input-forwarding or Accessibility permission path;
- Draw-mode Stage/Workspace alignment, single-point and long strokes, Pen and
  Highlighter opacity, partial Eraser sizing and cursor, erase-over-crossing-lines,
  draw-after-erase ordering, exact Undo restoration, memory bounds, Clear
  confirmation, automatic audience-pointer hiding on entry, restoration of the
  latest selected pointer style on return to Arrange, pointer-style changes made
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
  background, no recording or network request, no new Screen Recording or other
  permission, no unrelated-window enumeration, and no retained screenshot
  history after the explicit copy/save completes;
- no Accessibility or Input Monitoring request, raw mouse/keyboard event
  synthesis, keyboard capture/forwarding, or event tap; keyboard/VoiceOver
  Arrange and Draw actions; Spaces/full-screen/display
  changes; four-source CPU/memory; and the currently claimed meeting-app
  workflows.

Record the exact commit, hardware, OS/app versions, results, and approved
exceptions in the release record.

## Start the cloud build

Only tag the reviewed commit after GitHub CI and manual acceptance pass. The tag
must be exactly `v<major>.<minor>.<patch>` and its version must equal
`MARKETING_VERSION`:

```bash
git tag -s v0.1.1 -m "StagePane 0.1.1"
git push origin v0.1.1
```

`ci_scripts/ci_pre_xcodebuild.sh` rejects an Archive without Xcode Cloud, a
release tag, or a positive Cloud build number, as well as malformed tags,
tag/version mismatches,
or a cloud action configured with the wrong platform, scheme, bundle ID, or
team. It applies the Cloud build number to the temporary Xcode project. A
passing tag build archives the Release configuration and makes the
build available in App Store Connect for TestFlight/App Store use.

## Verify and submit

In the completed Xcode Cloud build and App Store Connect, verify:

- source tag and commit, Xcode/macOS versions, version/build, and archive logs;
- bundle ID `com.hinoshiba.stagepane`, Team `94HVVWXLK3`, App Sandbox,
  Hardened Runtime, privacy manifest, icon, localizations, and legal/help
  resources;
- Arrange and Draw present, with no cross-application input-forwarding or
  Accessibility permission path in the archived Mac App Store candidate; the
  Permissions view must show only the picker-scoped sharing explanation;
- no unexpected entitlement, embedded executable/framework, absolute
  `LC_RPATH`, updater, analytics, automatic screenshot, recording, or network
  path; confirm the only image export is the documented explicit local PNG
  copy/save path; and
- metadata, screenshots, privacy answers, export compliance, review notes,
  pricing, territories, and release mode against the exact build.

Xcode Cloud artifacts are retained for a limited period, so preserve the
release archive and logs in the private release record.

Tagging authorizes the Xcode Cloud build and upload only. Selecting a build for
an App Store version, distributing to testers, adding it for review, submitting
for review, and releasing it are separate App Store Connect actions. Do not
perform any of them without the release owner's explicit approval.
