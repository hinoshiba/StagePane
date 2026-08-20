# StagePane

> 見せたいものだけ、ひとつのステージへ。<br>
> A clean stage for everything you share.

StagePane is an open-source macOS app that creates a dedicated, ordinary
window for screen sharing. Use the private **Stage Workspace** for the live
Canvas, Sources, Stage Settings, Appearance, Permissions, Privacy, and About,
then share only the chrome-free **StagePane Stage** in Zoom, Microsoft Teams,
Google Meet, Webex, Slack Huddles, Discord, OBS, or another app that can share a
window.

StagePane is deliberately **not** a virtual display driver or alternate
desktop. It doesn't modify macOS display configuration and doesn't use private
`CGVirtualDisplay` APIs. With your explicit approval, Apple's public
ScreenCaptureKit picker can add a window, an app, or a display as an independent
source. Approval is scoped to that picker selection and capture session;
StagePane does not request separate, broad Screen Recording access. Add up to
four sources one at a time, then arrange them in the Stage.

## Why StagePane

- **A clean share target** — the audience Stage contains no editing chrome.
  The private Stage Workspace has an unmistakable title and keeps every editing
  and settings surface behind one Docker-style sidebar.
- **Privacy Curtain** — cover the Stage instantly with `Shift-Command-H`.
- **Exact shapes** — switch between 16:9, 4:3, 9:16, and 1:1 while preserving
  the Stage window identity used by meeting apps.
- **Consent-preserving source picker** — StagePane uses the macOS system picker,
  not a hand-built list of private window names. Each picker choice authorizes
  only that source for its capture session, without a separate broad Screen
  Recording permission.
- **A persistent permission guide** — Workspace's Permissions view explains
  the picker-scoped sharing model and keeps permission actions available without
  prompting at launch. In the local development build it also reports Press Buttons'
  separate Accessibility status; the Mac App Store build hides that card.
- **A source list and free layout** — add, pause or resume, replace, or remove
  each source independently in Workspace → Sources; drag and resize tiles on
  the large private Canvas or choose Grid, Side by Side, Stacked, or Picture in
  Picture from Quick Layout.
- **Private Workspace modes matched to the build** — the Mac App Store build
  includes Arrange and Draw. It omits Press Buttons and never requests
  Accessibility permission. The unsandboxed local development build can
  additionally expose narrowly scoped Press Buttons on macOS 15.2 or later.
- **One-shot audience screenshots** — explicitly copy a clean Stage image or
  save a PNG at the selected Stage dimensions. It includes the current Curtain,
  ink, watermark, and pointer, but never the private Workspace controls.
- **Local by construction** — no recorder, network client, account, telemetry,
  analytics SDK, advertising SDK, audio capture, or microphone capture.
- **Host controls** — menu-bar actions, all-Spaces mode, always-on-top
  compatibility, Presentation Lock, system/laser/hidden pointer styles,
  adjustable pointer color, size, and glow, safe-area guides, and neutral
  holding screens.
- **Public APIs and sandboxing** — SwiftUI, AppKit, AVFoundation, and
  ScreenCaptureKit in the sandboxed Mac App Store build. The optional
  ApplicationServices-based Press Buttons path is restricted to the unsandboxed local
  development build and is not present in the App Store binary.

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac
- Xcode 16 or newer, including matching Swift command-line tools, to build

The app asks you to approve content only in Apple's picker when you choose a
source to mirror. That selection grants session access to the chosen content;
there is no separate request for broad Screen Recording permission. Creating
and sharing an empty/holding Stage does not itself capture your screen.

## Build and run

```bash
git clone https://github.com/hinoshiba/StagePane.git
cd StagePane
./build.sh
open dist/StagePane.app
```

The default command creates a current-Mac development build. It is ad-hoc
signed and marked **do not distribute** inside the bundle. Developers who need
a stable macOS code identity across rebuilds can set
`STAGEPANE_LOCAL_SIGNING_IDENTITY` to an existing, caller-managed signing
identity in their Keychain before running `./build.sh`. The script does not
discover, store, or print that value; when the variable is absent or empty, it
keeps the ad-hoc fallback. Either result is still an unsandboxed local
development build with Hardened Runtime enabled, not an official distribution
artifact. Never publish `dist/StagePane.app` from this command. Automated tests
can be run independently:

```bash
swift test
```

A checked-in `StagePane.xcodeproj` and shared `StagePane-AppStore` scheme provide
the Mac App Store archive path. XcodeGen is needed only when changing
`project.yml`, not to build the checked-in project. A reviewed
`v<major>.<minor>.<patch>` tag starts the `App Store Release` Xcode Cloud
workflow, which archives with automatic signing and uploads the build to App
Store Connect. See the [release instructions](docs/RELEASE.md).

## How to use it

1. Open StagePane. Keep **StagePane Workspace — Keep Private** on your screen.
2. Select **Add Source** and approve one window, app, or display in the macOS
   system picker. That choice authorizes the selected content for its capture
   session; repeat to add up to four independent sources.
3. In **Workspace → Canvas**, drag a tile to move it and drag its lower-right
   handle to resize it. Use **Workspace → Sources** to pause or resume, replace,
   or remove one item. Use **Quick Layout** for Grid, Side by Side, Stacked, or
   Picture in Picture.
4. Switch the Workspace between **Arrange** and **Draw**. Arrange edits only the
   Stage composition; Draw places session-only ink over the Stage. The
   unsandboxed local development build also shows **Press Buttons** on macOS
   15.2 or later.
5. In your meeting app, share **StagePane Stage — Share This Window**.
6. Use `Shift-Command-H` whenever you need the Privacy Curtain.
7. Select **Stop All** to end every ScreenCaptureKit stream and discard all
   displayed frames.

Selecting an app can include all windows owned by that app. Select a single
window instead when you need the narrowest sharing scope.

Under **Appearance → Pointer appearance**, choose the standard macOS pointer,
an audience-friendly laser pointer, or no pointer. Its color, diameter, and glow
are adjustable, with a PowerPoint-like red presentation dot as the default. The
dot is drawn only in the Stage's frontmost source and does not change your Mac's
system pointer. If that frontmost source is paused, StagePane shows no dot; it
does not fall back to a source behind it. A translucent StagePane mark appears
in the lower-right of the holding screen, shared content, and Curtain by default,
is mirrored in the private Workspace, and can be disabled in Appearance.

Pausing a source stops its ScreenCaptureKit stream while retaining its last
frame in the Stage and private Workspace. Resume restarts that source; Remove or
Stop All discards the retained frame.

Toggling the Privacy Curtain updates the Stage without bringing its window to
the front, so the Workspace or source app you are using keeps its place.

Dragging in **Arrange** changes only the Stage composition. **Draw** adds bounded
vector ink with a pen or translucent highlighter, plus a size-adjustable partial
eraser whose gestures can be undone exactly. The document stays in memory, is hidden by the Curtain, and is cleared by
Stop All or removal of the final source. Both modes remain available in the Mac
App Store build, which omits Press Buttons and does not request Accessibility
permission.

In the unsandboxed local development build, **Press Buttons** is an explicit,
narrow action on macOS 15.2 or later. Selecting Press Buttons without access opens the
persistent **Permissions** view; only its explicit **Continue Setup** button
asks macOS for Accessibility access. After consent, selecting a point in an
exactly-one-window source asks a pressable accessibility control at that point
to perform its supported Press action. StagePane does not synthesize an
arbitrary mouse click, move the physical pointer, or activate/focus the source
app. The Mac App Store build does not show the Accessibility card.
App/display sources, black padding, stale or ambiguous frames, generic
canvas/content regions, keyboard input, and drag forwarding are rejected.

For PowerPoint Presenter View on one monitor, start the slide show, choose
**Show Presenter View** from PowerPoint's lower-left presentation controls,
then add that Presenter View window as a StagePane source. This avoids a
virtual-display dependency. In the Mac App Store build, use PowerPoint itself
for all presenter-view controls; StagePane provides Arrange and Draw only. An
unsandboxed local development build on macOS 15.2 or later can invoke a supported
accessibility Press action on a pressable control in that exact window. Slide
canvases and controls that do not expose Press are not generic click targets;
keep keyboard, drag, and presentation navigation in PowerPoint.

The Stage Workspace contains the live Canvas plus Sources, Stage Settings,
Appearance, Permissions, Privacy, and About in one sidebar. It is intended to
stay private. This is workflow guidance, not a technical capture boundary:
sharing the whole display or the StagePane application can expose the
Workspace. In your meeting app, choose the exact **StagePane Stage — Share This
Window** window.

From the Stage Workspace, explicitly choose **Copy Audience Image** or **Save
Audience Image…** to take a one-shot image of the clean audience Stage. The
image uses the selected Stage pixel dimensions and includes exactly the current
audience state, including the Curtain, ink, watermark, and pointer. StagePane never takes
screenshots automatically, starts a recording, or sends the image over the
network. A copied image remains on the macOS clipboard, and a PNG is written
only to the location you choose. Canceling Save writes nothing.

On macOS 15 and later, **Switch Active Share** can ask a compatible, already
active ScreenCaptureKit sharing session to switch to the Stage. It cannot start
or control every meeting app's sharing session.

## Architecture

```text
Up to four user-approved windows / apps / displays
              │  one ScreenCaptureKit stream per source (video only)
              ▼
      normalized position / size / front-to-back order
              │  memory only; no encoder or writer
              ├────► StagePane Stage ───► meeting app shares this exact window
              │                 └───────► explicit local PNG copy/save only
              └────► private Stage Workspace
                     Canvas + Sources + settings in one sidebar
```

The project is a Swift Package with a testable framework-free core and a native
AppKit/SwiftUI executable. Details and constraints are in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Privacy and security

StagePane collects no data. Source frames are displayed from memory and are not
automatically saved or sent by StagePane. Only an explicit screenshot action
copies one clean Stage PNG to the macOS clipboard or saves it to a location the
user chooses. The app has no network entitlement. Settings such as theme,
pointer appearance, watermark visibility, and window behavior are stored in the
app's sandboxed `UserDefaults`.

- Privacy details: [`docs/PRIVACY.md`](docs/PRIVACY.md)
- Security reporting: [`SECURITY.md`](SECURITY.md)
- Dependency and license audit: [`docs/LICENSE_AUDIT.md`](docs/LICENSE_AUDIT.md)

Your meeting app is a separate product with its own capture, transmission,
recording, and privacy behavior.

## Open source and commercial distribution

Source code is available under the [Apache License 2.0](LICENSE), which permits
commercial use, modification, redistribution, and sale subject to its terms.
Official signed binaries, support, and services may be sold even though the
source is open.

The source license does not grant rights to present a fork as an official
StagePane release. See [`TRADEMARKS.md`](TRADEMARKS.md). Official binary and
commercial distribution remain blocked until professional trademark clearance
and legal/support contacts are complete. This repository is product engineering
work, not legal advice.

## Clean-room origin and acknowledgements

StagePane was independently authored. The public MIT-licensed
[`hinoshiba/youyaku`](https://github.com/hinoshiba/youyaku) repository was
reviewed only as an operational reference for build, release, and
OSS documentation practices. No Youyaku code, assets, models, binaries, product
copy, keys, or brand elements are incorporated. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md), sign commits off under the Developer
Certificate of Origin, and follow [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## 日本語概要

StagePaneは、画面共有で選択するための専用ウインドウを作るmacOSアプリです。
本物の仮想ディスプレイや別デスクトップではなく、Appleの公開APIだけを使った
プレゼンテーション・キャンバスです。手元のStage Workspaceには、キャンバス、ソース、
Stage設定、見た目と動作、アクセス権限、プライバシー、このアプリについてをまとめ、
相手にはクロームのないStageだけを見せます。共有対象は
Appleの選択画面で1件ずつ、その取得セッションに限って許可され、別途広範な画面収録許可は
求めません。明示的な操作でだけ、観客側Stageの画像をコピーまたはPNG保存できます。
自動撮影、録画、外部送信、アカウント、広告、解析はありません。
