# StagePane

> 見せたいものだけ、ひとつのステージへ。<br>
> A clean stage for everything you share.

StagePane is an open-source macOS app that creates a dedicated, ordinary
window for screen sharing. Use the private **Stage Workspace** with its live
Canvas and persistent layer list. Stage appearance lives in **Stage Settings**;
the separate **Settings** window has **General** and **About**, including privacy
information. Share only the chrome-free **StagePane Stage** in Zoom, Microsoft Teams,
Google Meet, Webex, Slack Huddles, Discord, OBS, or another app that can share a
window.

StagePane is deliberately **not** a virtual display driver or alternate
desktop. It doesn't modify macOS display configuration and doesn't use private
`CGVirtualDisplay` APIs. With your explicit approval, Apple's public
ScreenCaptureKit picker can add a window, an app, or a display as an independent
source. The free Mac App Store app supports four simultaneous sources, while
the one-time StagePane Pro purchase removes StagePane's source-count limit.
The number that can run in practice depends on Mac performance and
operating-system constraints. Approval is scoped to each picker selection and
capture session; StagePane does not request separate, broad Screen Recording
access.

## Why StagePane

- **A clean share target** — the audience Stage contains no editing chrome.
  The private Stage Workspace has an unmistakable title and keeps editing
  controls beside the live Canvas, with Stage Settings above it.
- **Privacy Curtain** — cover the Stage instantly with `Shift-Command-H`.
- **Exact shapes** — switch between 16:9, 4:3, 9:16, and 1:1 while preserving
  the Stage window identity used by meeting apps.
- **Double-click to maximize** — double-click the Stage's displayed content to
  fit its shape within the current screen, then double-click again to restore
  its previous size and position.
- **Consent-preserving source picker** — StagePane uses the macOS system picker,
  not a hand-built list of private window names. Each picker choice authorizes
  only that source for its capture session, without a separate broad Screen
  Recording permission.
- **Screen-sharing guidance when needed** — **About Screen Sharing** opens a
  separate guide from the Stage menu or Settings → About. Add Source opens
  Apple's picker for session-scoped sharing; no permission warning appears at launch.
- **Layers beside the Canvas** — manage every source without leaving the
  composition. The persistent list runs from front to back, so a covered or
  hidden layer stays easy to select. Selection and Canvas movement or resizing
  preserve stacking order. Drag the list's grips or use Move Forward, Move
  Backward, Bring to Front, or Send to Back in the layer's More menu to change it.
  Only the selected tile shows editing handles; Crop and the selected layer's
  More menu stay in the fixed tools below the Canvas.
  Its outline and handles follow the visible source or applied crop, excluding
  empty margins. Resize preserves that content's proportions.
  Choose Grid, Side by Side, Stacked, or Picture in Picture from Layout.
  If macOS ends one source's sharing session, its
  layer remains in place without an old frame and offers Select Again; its crop,
  placement, and stacking order survive the reconnection.
- **Hide and show one layer** — the direct Hide action pauses that source and
  clears its visible pixels while keeping its placement, crop, and stacking
  order. Show resumes it and waits for a new complete frame before revealing it.
- **Per-layer cropping** — use Crop in the fixed selected-layer tools below the
  Canvas or in that layer's More menu to
  open that layer alone in the private Workspace and draft its framed region.
  The audience Stage does not change until you choose Apply Crop; Cancel
  discards the draft. Each layer keeps its own applied crop in memory for the
  current StagePane run, including while that layer waits for Select Again.
- **Focused private Workspace tools** — Arrange composes the audience Stage,
  each layer owns its crop, and Draw adds session-only pen,
  highlighter, and erasable ink while automatically hiding the audience
  pointer. Magnify follows your cursor with a circular 2×, 3×, or 4× lens in
  both the private Canvas and shared Stage, without changing layout or crop.
  Returning to Arrange restores the selected pointer style.
  StagePane never forwards input to a source app and does not request
  Accessibility or Input Monitoring permission.
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
If source selection or capture cannot start, a separate message window explains
the issue while the editor remains usable. Canceling the picker does not show
that message. Hide and Stop failures remain in the layer and capture status.

## Build and run

```bash
git clone https://github.com/hinoshiba/StagePane.git
cd StagePane
./build.sh
open dist/StagePane.app
```

The default command creates a current-Mac development build. It uses the same
App Sandbox entitlements and Arrange/Crop/Draw/Magnify feature set as the Store target, is
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
`project.yml`, not to build the checked-in project. From a reviewed `main`
commit carrying an annotated signed release tag,
`Scripts/archive-app-store.sh` runs the fixed
`StagePane-AppStore` Release archive with automatic signing, verifies the local
candidate, and opens it in Xcode Organizer. The release owner verifies
Distribution Summary and, only after separate authorization, uploads manually;
App Store Connect build selection, review submission, and release remain
explicit, release-mode-aware actions. See the [release
instructions](docs/RELEASE.md).

## How to use it

1. Open StagePane. Keep **StagePane Workspace — Keep Private** on your screen.
2. Select **Add Source** and approve one window, app, or display in the macOS
   system picker. That choice authorizes the selected content for its capture
   session; repeat for up to four sources in Free. StagePane Pro removes the
   app's source-count limit; the practical total depends on Mac performance and
   operating-system constraints.
3. In **Workspace**, select a layer on the Canvas or in the list beside it and
   use **Arrange** to move and resize it. Selecting or moving a layer on the
   Canvas does not bring it forward. Drag its grip in the layer list to change
   stacking order; higher rows are in front. The order changes when you drop,
   and canceling the drag keeps the original order. Placement, crop, and the
   selected layer stay unchanged. Finish Crop or source selection before
   reordering. The More menu in the layer's row or selected-layer tools provides
   ordering actions without dragging. For a covered or hidden layer, drag its selected title badge or use
   arrow keys; its resize handle remains reachable above the other layers.
   Move using the visible content edges, including after cropping; empty margins
   do not block selecting a layer behind them. Drag the resize handle to scale
   the content proportionally from its upper-left corner.
   Choose **Crop** in the selected-layer tools below the Canvas, adjust its frame or four
   corner handles, then choose **Apply Crop**. The Stage keeps that layer's
   previously applied region until then. Use **Layout** for Grid, Side by
   Side, Stacked, or Picture in Picture.
4. Use **Hide** or **Show** beside a layer to temporarily remove or restore it.
   The same list provides crop, replace, and remove actions. Switch to **Draw**
   when you want to place session-only ink over the Stage, or **Magnify** to
   show a detail through a circular lens.
5. In your meeting app, share **StagePane Stage — Share This Window**.
6. Use `Shift-Command-H` whenever you need the Privacy Curtain.
7. Select **Stop All** to end every ScreenCaptureKit stream and remove all
   layers, including disconnected layers whose placement and crop were retained.

Selecting an app can include all windows owned by that app. Select a single
window instead when you need the narrowest sharing scope.

In windowed mode, double-click the Stage's displayed content to maximize it
within the current screen while preserving its aspect ratio and leaving the
menu bar and Dock available. Double-click again to restore its previous size
and position. Drag the content to move the window.

Cropping changes only the local composition shown on the Stage and in an
Audience PNG. Whenever a source stream is running, ScreenCaptureKit handles the
complete window, app, or display approved in Apple's picker. **Hide** pauses
that stream and makes its layer transparent in the Stage, private Workspace,
and Audience PNG output. **Show** resumes capture and reveals the layer only
after a new complete frame arrives;
placement, crop, and z-order remain unchanged. Remove or Stop All ends its
capture session. The private Workspace deliberately shows the complete source
while Crop is active; only the selected source is shown there, and draft changes
do not reach the Stage until Apply Crop. Keep the Workspace private and use the
Curtain before applying content that is not ready for the audience.

Under **Stage Settings → Pointer**, choose the standard macOS pointer,
an audience-friendly laser pointer, or no pointer. Its color, diameter, and glow
are adjustable, with a PowerPoint-like red presentation dot as the default. The
dot is drawn only in the Stage's frontmost source and does not change your Mac's
system pointer. If that frontmost source is paused, StagePane shows no dot; it
does not fall back to a source behind it. A translucent StagePane mark appears
in the lower-right of the holding screen, shared content, and Curtain by default,
is mirrored in the private Workspace. StagePane Pro can disable it in
Stage Settings, including for the Curtain and explicit Audience PNG output.

Hidden layers remain in the layer list so you can select and restore the exact
layer without changing the stack. Remove discards the source's pixels and
deletes that layer; Stop All does so for every layer.

Toggling the Privacy Curtain updates the Stage without bringing its window to
the front, so the Workspace or source app you are using keeps its place.
Under **Stage Settings → Curtain**, use the size stepper to make the message
smaller or larger. Changes apply immediately and the size is saved for next time.

Dragging in **Arrange** changes only Stage placement. A layer's crop button
drafts only that layer's visible region privately, then changes the Stage
composition only when you apply it. **Draw** adds bounded vector ink with a pen or translucent
highlighter, plus a size-adjustable partial eraser
whose gestures can be undone exactly. The document stays in memory, is hidden
by the Curtain, and is cleared by Stop All or removal of the final source.

Choose **Magnify**, beside Arrange and Draw, then move the cursor over the
private Canvas to show a circular lens in both the preview and shared Stage.
Select **2×**, **3×**, or **4×** magnification; layout and crop stay unchanged.
The lens disappears when the cursor leaves the Canvas. With the Canvas focused,
arrow keys move the lens. Press **Escape** or choose **Exit Magnify** to return
to Arrange. The Curtain hides the audience lens, and returning to Arrange
restores your pointer preference. All tools remain available in every build
and require no Accessibility or Input Monitoring permission.

For PowerPoint Presenter View on one monitor, start the slide show, choose
**Show Presenter View** from PowerPoint's lower-left presentation controls,
then add that Presenter View window as a StagePane source. This avoids a
virtual-display dependency. Use PowerPoint itself for all presenter-view
controls. StagePane captures and composes the selected
Presenter View window but does not forward clicks, keys, or drags to PowerPoint.

The Stage Workspace keeps the Canvas and layer list together, including at the
minimum window size. **Stage Settings** above the Canvas changes Stage appearance
and output. Workspace and Settings automatically follow macOS Light or Dark
appearance, independently of the audience Stage theme; there is no separate
app appearance setting. The labeled **Settings** button (Command-comma) opens **General** and
**About** in a separate window. About includes a privacy summary, expandable
**Privacy and Data** details, and **About Screen Sharing**. The app menu's
**About StagePane** opens the same About page. The Workspace is intended to
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
       Free: up to four · Pro: no app-imposed source-count limit
              │  one ScreenCaptureKit stream per source (video only)
              ▼
      normalized position / size / front-to-back order
              │  memory only; no encoder or writer
              ├────► StagePane Stage ───► meeting app shares this exact window
              │                 └───────► explicit local PNG copy/save only
              └────► private Stage Workspace
                     Canvas + persistent layer list; separate Settings window
```

The project is a Swift Package with a testable framework-free core and a native
AppKit/SwiftUI executable. Details and constraints are in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Privacy and security

StagePane sends no data to the developer or any third party. Source frames are
displayed from memory and are not automatically saved or sent by StagePane. Only
an explicit screenshot action copies one clean Stage PNG to the macOS clipboard
or saves it to a location the user chooses. The app has no network entitlement or
publisher-operated network service. In the Mac App Store build, Apple StoreKit
retrieves Pro product and verified transaction information; screen content is
never part of that flow. On the user's Mac the app stores only local settings in
its sandboxed `UserDefaults`: the Stage preset and theme, window behavior, the
safe-area guide and StagePane mark visibility, pointer appearance, the Curtain
message and its text size, drawing tool settings, and the position and size of
the Workspace and Stage windows. The Mac App Store build additionally stores
three values used only to time the App Store rating prompt: a count of successful
sessions, the date of the first one, and the app version in which the prompt was
last shown. Screen content, source names, the Stage layout of sources, and
drawings are not stored.

- Privacy details: [`docs/PRIVACY.md`](docs/PRIVACY.md)
- Security reporting: [`SECURITY.md`](SECURITY.md)
- Dependency and license audit: [`docs/LICENSE_AUDIT.md`](docs/LICENSE_AUDIT.md)

Your meeting app is a separate product with its own capture, transmission,
recording, and privacy behavior.

## 免責事項

本サイトならびに本サイトで紹介・公開しているアプリケーション、コンテンツ、成果物およびソースコード等は、制作者が個人(hinoshiba)として制作・提供しているものです。

これらは制作者が所属する組織・団体とは関係なく、所属組織・団体の公式な見解、製品、サービスまたは活動を示すものではありません。

本サイトおよび本アプリケーション等に関するお問い合わせ、サポートその他の責任は制作者個人が負うものであり、所属組織・団体はこれらの提供・運営には関与しておりません。

本サイトまたは本アプリケーション等の利用により生じた損害については、法令上認められる範囲において、制作者は責任を負わないものとします。

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
プレゼンテーション・キャンバスです。手元のStage Workspaceでは、キャンバスの横に
前面から背面の順でレイヤー一覧を常設し、重なったソースも一覧から選べます。
選択とキャンバス上の移動・サイズ変更では重なり順は変わりません。一覧のつまみを
ドラッグするか、各レイヤーのその他メニューから前面・背面への操作で変更できます。
各レイヤーの「非表示」は取得を一時停止し、配置と切り抜きを保ちます。「再表示」は取得を
再開し、新しい完全なフレームが届いてから映像を戻します。
通常表示のStageは、表示内容をダブルクリックすると縦横比を保ったまま画面内で最大化し、
もう一度ダブルクリックすると元の大きさと位置へ戻ります。メニューバーとDockは利用できます。
**配置**・**手書き** の隣にある **虫眼鏡** では、手元のキャンバス上でカーソルを動かすと、
プレビューと共有Stageの両方に円形レンズを表示します。倍率は **2×**・**3×**・**4×** から選べ、
配置と切り抜きは変わりません。カーソルをキャンバスの外へ移すとレンズは消えます。
キャンバスにフォーカスがある間は矢印キーでも動かせます。**Escape** または **虫眼鏡を終了** で
配置へ戻り、選択中のポインター設定を復元します。カーテン中は観客側のレンズを隠します。
**Stage設定 → カーテン** の文字サイズステッパーで文字を小さく・大きくできます。
変更はすぐに反映され、文字の大きさは次回起動時も維持されます。
Stageの見た目はキャンバス上部の **Stage設定** で調整します。文字付きの **設定** ボタン
（⌘,）は **一般** と **このアプリについて** の2項目を持つ独立ウインドウを開きます。
プライバシーの要約と展開式の **プライバシーとデータ** は **このアプリについて** にまとめ、
アプリメニューの **StagePaneについて** からも同じ画面を開けます。
**画面共有について** はステージメニューや **このアプリについて** から別の案内ウインドウを
開きます。起動時の権限警告はなく、共有対象は
Appleの選択画面で1件ずつ、その取得セッションに限って許可され、別途広範な画面収録許可は
求めません。選択画面や取得を開始できない場合は、編集を妨げない別ウインドウで説明します。
キャンセルではこの案内を出さず、非表示・停止の失敗はレイヤーと取得状態で確認できます。
明示的な操作でだけ、観客側Stageの画像をコピーまたはPNG保存できます。
画面の扱いと保存については[プライバシーポリシー](https://stagepane.hinoshiba.com/#privacy)を確認できます。
Mac App Store版は無料で同時に4ソースまで利用でき、買い切りのStagePane Proでは
アプリ側のソース件数制限がなくなり、ロゴ非表示も利用できます。実際に利用できる件数は
Macの性能とOSの制約に依存します。購入と購入状態の確認はAppleのStoreKitが処理します。
