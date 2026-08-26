# StagePane

> 見せたいものだけ、ひとつのステージへ。<br>
> A clean stage for everything you share.

StagePane is an open-source macOS app that creates a dedicated, ordinary
window for screen sharing. Use the private **Stage Workspace** for the live
Canvas & Sources, Stage Settings, Appearance, Permissions, Privacy, and About,
then share only the chrome-free **StagePane Stage** in Zoom, Microsoft Teams,
Google Meet, Webex, Slack Huddles, Discord, OBS, or another app that can share a
window.

StagePane is deliberately **not** a virtual display driver or alternate
desktop. It doesn't modify macOS display configuration and doesn't use private
`CGVirtualDisplay` APIs. With your explicit approval, Apple's public
ScreenCaptureKit picker can add a window, an app, or a display as an independent
source. The free Mac App Store app supports two simultaneous sources and the
one-time StagePane Pro purchase removes StagePane's plan-level source-count
limit. Pro is not a promise of an absolute unlimited source count: the practical
number still depends on the Mac's performance, ScreenCaptureKit, and the content
selected. Approval is scoped to each picker selection and capture session;
StagePane does not request separate, broad Screen Recording access.

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
  how Add Source opens Apple's picker for session-scoped sharing, without
  prompting at launch.
- **One live Canvas & Sources workflow** — use the Canvas's left source rail to
  add, pause or resume, replace, remove, or stop sources while watching the live
  preview. The list is the layer order, with the top item frontmost. Drag and
  resize tiles on the Canvas or choose Grid, Side by Side, Stacked, or Picture
  in Picture from Quick Layout.
- **Focused private Workspace tools** — Arrange composes the audience Stage and
  Draw adds session-only pen, highlighter, and erasable ink while automatically
  hiding the audience pointer. Returning to Arrange restores the selected
  pointer style. StagePane never forwards input to a source app and does not
  request Accessibility or Input Monitoring permission.
- **One-shot audience screenshots** — explicitly copy a clean Stage image or
  save a PNG at the selected Stage dimensions. It includes the current Curtain,
  ink, watermark, safe-area guide when enabled, and pointer when visible, but
  never the private Workspace controls.
- **Local by construction** — no recorder, network client, account, telemetry,
  analytics SDK, advertising SDK, audio capture, or microphone capture.
- **Host controls** — menu-bar actions, all-Spaces mode, always-on-top
  compatibility, Presentation Lock, system/laser/hidden pointer styles,
  adjustable pointer color, size, and glow, safe-area guides, and neutral
  holding screens.
- **Public APIs and sandboxing** — every build uses App Sandbox with SwiftUI,
  AppKit, AVFoundation, and ScreenCaptureKit, with no private display driver or
  cross-application input path.

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

The default command creates a current-Mac development build. It uses the same
App Sandbox entitlements and Arrange/Draw feature set as the Store target, is
ad-hoc signed, and is intended only for local testing. Developers may set
`STAGEPANE_LOCAL_SIGNING_IDENTITY` to an existing, caller-managed signing
identity in their Keychain before running `./build.sh`. The script does not
discover, store, or print that value; when the variable is absent or empty, it
keeps the ad-hoc fallback. Either result retains App Sandbox and Hardened Runtime
and is not an official distribution artifact. Never publish
`dist/StagePane.app` from this command. Automated tests can be run independently:

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
   session; repeat for two sources in Free. StagePane Pro removes the app's
   plan-level source-count limit, subject to the practical capacity of the Mac,
   ScreenCaptureKit, and the selected content.
3. In **Workspace → Canvas & Sources**, keep the live preview visible while
   using the left rail to add, pause or resume, replace, remove, or **Stop All**.
   The top source is the frontmost layer; selecting another row brings it to the
   front. Drag a tile or its lower-right handle to move or resize it. Use
   **Quick Layout** for Grid, Side by Side, Stacked, or Picture in Picture.
4. Switch the Workspace between **Arrange** and **Draw**. Arrange edits only the
   Stage composition; Draw places session-only ink over the Stage.
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
is mirrored in the private Workspace. StagePane Pro can disable it in
Appearance, including for the Curtain and explicit Audience PNG output.

Pausing a source stops its ScreenCaptureKit stream while retaining its last
frame in the Stage and private Workspace. Resume restarts that source; Remove or
Stop All discards the retained frame.

Toggling the Privacy Curtain updates the Stage without bringing its window to
the front, so the Workspace or source app you are using keeps its place.

Dragging in **Arrange** changes only the Stage composition. **Draw** adds bounded
vector ink with a pen or translucent highlighter, plus a size-adjustable partial
eraser whose gestures can be undone exactly. The document stays in memory, is
hidden by the Curtain, and is cleared by Stop All or removal of the final
source. Both modes remain available in every build. Neither mode requires
Accessibility or Input Monitoring permission.

For PowerPoint Presenter View on one monitor, start the slide show, choose
**Show Presenter View** from PowerPoint's lower-left presentation controls,
then add that Presenter View window as a StagePane source. This avoids a
virtual-display dependency. Use PowerPoint itself for all presenter-view
controls. StagePane captures and composes the selected
Presenter View window but does not forward clicks, keys, or drags to PowerPoint.

The Stage Workspace contains one live **Canvas & Sources** view plus Stage
Settings, Appearance, Permissions, Privacy, and About in its sidebar. The
Canvas's left source rail replaces a separate Sources screen. It is intended to
stay private. This is workflow guidance, not a technical capture boundary:
sharing the whole display or the StagePane application can expose the
Workspace. In your meeting app, choose the exact **StagePane Stage — Share This
Window** window.

From the Stage Workspace, explicitly choose **Copy Audience Image** or **Save
Audience Image…** to take a one-shot image of the clean audience Stage. The
image uses the selected Stage pixel dimensions and includes exactly the current
audience state, including the Curtain, ink, watermark, safe-area guide when
enabled, and pointer when visible. StagePane never takes screenshots
automatically, starts a recording, or sends the image over the network. A copied
image remains on the macOS clipboard, and a PNG is written only to the location
you choose. Canceling Save writes nothing.

On macOS 15 and later, **Switch Active Share** can ask a compatible, already
active ScreenCaptureKit sharing session to switch to the Stage. It cannot start
or control every meeting app's sharing session.

## Architecture

```text
User-approved windows / apps / displays
     Free: 2; Pro: no app-imposed plan limit
              │  one ScreenCaptureKit stream per source (video only)
              ▼
      normalized position / size / front-to-back order
              │  memory only; no encoder or writer
              ├────► StagePane Stage ───► meeting app shares this exact window
              │                 └───────► explicit local PNG copy/save only
              └────► private Stage Workspace
                     Canvas & Sources + settings in one sidebar
```

The practical Pro source count is finite and varies with Mac performance,
ScreenCaptureKit behavior, and the selected content; StagePane does not impose
an additional plan limit or promise an absolute unlimited count.

The project is a Swift Package with a testable framework-free core and a native
AppKit/SwiftUI executable. Details and constraints are in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Privacy and security

StagePane collects no data. Source frames are displayed from memory and are not
automatically saved or sent by StagePane. Only an explicit screenshot action
copies one clean Stage PNG to the macOS clipboard or saves it to a location the
user chooses. The app has no network entitlement or publisher-operated network
service. In the Mac App Store build, Apple StoreKit retrieves Pro product and
verified transaction information; screen content is never part of that flow.
Settings such as theme, pointer appearance, watermark visibility, and window
behavior are stored in the app's sandboxed `UserDefaults`.

- Privacy details: [`docs/PRIVACY.md`](docs/PRIVACY.md)
- Security reporting: [`SECURITY.md`](SECURITY.md)
- Dependency and license audit: [`docs/LICENSE_AUDIT.md`](docs/LICENSE_AUDIT.md)

Your meeting app is a separate product with its own capture, transmission,
recording, and privacy behavior.

## Open source and commercial distribution

Source code is available under the [Apache License 2.0](LICENSE), which permits
commercial use, modification, redistribution, and sale subject to its terms.
Official signed binaries, support, and services may be sold even though the
source is open. The official Mac App Store binary offers a useful Free tier and
one non-consumable StagePane Pro purchase; source-built development binaries
expose all features. See [`docs/MONETIZATION.md`](docs/MONETIZATION.md).

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
プレゼンテーション・キャンバスです。手元のStage Workspaceには、ライブプレビューと
左側のソース一覧を統合した「キャンバスとソース」、
Stage設定、見た目と動作、アクセス権限、プライバシー、このアプリについてをまとめ、
相手にはクロームのないStageだけを見せます。共有対象は
Appleの選択画面で1件ずつ、その取得セッションに限って許可され、別途広範な画面収録許可は
求めません。明示的な操作でだけ、観客側Stageの画像をコピーまたはPNG保存できます。
自動撮影、録画、画面内容の外部送信、StagePaneアカウント、広告、解析はありません。
Mac App Store版は無料で2ソース、買い切りのStagePane ProではStagePaneによる
プラン上のソース数制限をなくし、ロゴ非表示も利用できます。実用上のソース数はMacの
性能、ScreenCaptureKit、選択内容に左右され、絶対的な無制限を保証するものではありません。
購入と購入状態の確認はAppleのStoreKitが処理します。
