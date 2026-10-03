# App Store positioning and review notes

## Metadata draft

- **Name:** StagePane
- **Subtitle (EN):** Screen Share Stage
- **Subtitle (JA):** 画面共有専用のステージ
- **Primary category:** Productivity
- **Secondary category:** Utilities
- **Tagline (EN):** A clean stage for everything you share.
- **Tagline (JA):** 見せたいものだけ、ひとつのステージへ。
- **Promotional Text (EN):** A clean stage for everything you share. Free
  includes four sources; Pro removes the app's source-count limit and mark.
  Source count depends on your Mac and OS.
- **Promotional Text (JA):** 見せたいものだけ、ひとつのステージへ。無料で4ソース、StagePane Proならアプリ側の件数制限なし・ロゴ非表示。利用可能数はMacとOSに依存します。
- **What's New 0.4.2 (EN):** Fixed Stage window dragging and startup sizing.
  Drag the Stage's content to move it; each shape now keeps its correct minimum
  proportions. Stage can now enter native full screen in its own macOS Space
  while Workspace remains available for private editing. The complete Stage
  canvas keeps its shape, and Audience PNGs retain their preset dimensions
  without full-screen margins. Stage Settings shows the actual rendering size
  separately from Audience PNG dimensions and adds Enlarge Stage for Sharing
  in windowed mode. Enlargement keeps the same share window and never shrinks
  an already larger Stage. Share only the Stage window; the meeting app still
  controls the resolution it sends.
- **What's New 0.4.2 (JA):** Stageウインドウのドラッグ移動と起動時サイズを修正しました。表示内容をドラッグして移動でき、縦長を含む各形状の最小サイズも縦横比を保ちます。Stageだけを専用のmacOS Spaceでフルスクリーン表示し、手元のWorkspaceで編集できるようになりました。Stage全体の形状を保ち、Audience PNGはフルスクリーンの余白を含めず、プリセットの寸法で出力します。Stage設定ではPNGサイズと実際の描画サイズを分けて表示し、通常ウインドウ向けの「共有向けにStageを拡大」を追加しました。拡大時も共有対象のウインドウを保ち、すでに大きいStageを縮小することはありません。会議アプリではStageだけを共有してください。送信解像度は会議アプリが決めます。
- **Privacy Policy URL (JA):** https://stagepane.hinoshiba.com/#privacy
- **Privacy Policy URL (EN):** https://stagepane.hinoshiba.com/en/privacy/

  The English URL is a static page whose policy text is in the HTTP response
  body, so it can be read without JavaScript. The Japanese policy is static in
  the root document; `https://stagepane.hinoshiba.com/?lang=en#privacy` still
  renders the same English text, but only with JavaScript enabled.
- **Support URL (JA):** https://stagepane.hinoshiba.com/#support
- **Support URL (EN):** https://stagepane.hinoshiba.com/?lang=en#support

- **Keywords (EN draft):** `presentation,meeting,window,privacy,demo,teaching,webinar,laser,canvas,annotate,training,remote`
- **キーワード（JA案）:** `プレゼン,会議,ウインドウ,発表,デモ,講義,プライバシー,ポインター,注釈`

These avoid repeating the product name and current subtitle. Re-check the live
character/byte counter and duplication rules in App Store Connect before use.

Do not use competitor trademarks in metadata and do not use `virtual display`,
`second monitor`, `independent desktop`, `real display`, or equivalents. The app
creates a normal shareable window, not an `NSScreen`.

### Description draft — Japanese

> 見せたいものだけを、ひとつの共有専用Stageへ。
>
> StagePaneは、相手に共有する「Stage」と、手元で操作する「Workspace」を
> 分けるmacOSアプリです。Appleの選択画面で許可したウインドウ、アプリ、
> または画面だけを追加し、会議アプリでは通常の「StagePane Stage」
> ウインドウを選んで共有します。
>
> 無料版で使える機能：
> ・同時に4つのソースを配置
> ・キャンバス横のレイヤー一覧、自由配置とクイック配置
> ・選択した1ソースを手元で下書きし、「適用」で反映する切り抜き
> ・ペン、蛍光ペン、部分消しゴム
> ・Privacy Curtain、レイヤーの非表示・再表示、選び直し、すべて停止
> ・レーザーポインターと4種類のStage形状
> ・Audience Stage画像のコピー／PNG保存（StagePaneロゴ入り）
>
> StagePane Pro（1回限りのアプリ内課金）：
> ・アプリ側のソース件数制限を解除（利用可能数はMacの性能とOSの制約に依存）
> ・Stage、Curtain、Audience画像のStagePaneロゴを非表示
>
> Proは買い切りで、サブスクリプションではありません。価格はApp Storeが
> 購入前に表示します。復元が必要な場合はPro画面の「購入を復元」を利用できます。
>
> 画面の扱いと保存は、アプリ内からプライバシーポリシーを確認できます。

### Description draft — English (U.S.)

> Put only what you mean to show on one dedicated sharing Stage.
>
> StagePane separates the audience-facing Stage from the Workspace you control
> privately. Add only a window, app, or display you approve in Apple’s picker,
> then share the normal “StagePane Stage” window in your meeting app.
>
> Included free:
> • Compose four simultaneous sources
> • A layer list beside the Canvas, freeform and quick layouts
> • Per-source Crop with a private one-source draft and explicit Apply or Cancel
> • Pen, highlighter, and partial eraser
> • Privacy Curtain, layer Hide/Show, replace, and Stop All
> • Laser pointer and four Stage shapes
> • Copy or save an Audience Stage PNG with the StagePane mark
>
> StagePane Pro — one-time In-App Purchase:
> • Remove StagePane's source-count limit (available total depends on Mac
>   performance and operating-system constraints)
> • Hide the StagePane mark from the Stage, Curtain, and Audience images
>
> Pro is a one-time purchase, not a subscription. The App Store shows the price
> before purchase. When restoration is needed, use Restore Purchases on the
> Pro screen.
>
> Read the privacy policy from the app for how screen content is handled and saved.

## Shipping build route

Prepare the release on `codex/release-<version>` with signed, DCO-compliant
commits; require pull-request review, pull-request CI, exact-candidate manual
acceptance, a normal merge, and passing merged-`main` CI. Create and push an
annotated signed `v<major>.<minor>.<patch>` tag on that exact reviewed `main`
commit, then run `Scripts/archive-app-store.sh`. The helper
archives the checked-in `StagePane.xcodeproj` with the shared
`StagePane-AppStore` scheme, verifies the candidate, and opens it in Xcode
Organizer without uploading it. The release owner verifies Distribution Summary
and, only after separate authorization, uploads manually from that same Mac.
After upload, wait for the exact build to complete processing before authorized
App Store Connect build selection, review submission, and release-mode-aware
public release actions. The target is sandboxed, has no network
entitlement, grants read/write access only to locations the user explicitly
selects for Audience PNG export, and bundles the privacy manifest, English/Japanese usage strings,
`AppIcon.icns`, help, privacy policy, license, notices, trademark policy, and
brand-asset license. Xcode uses automatic signing for Team `94HVVWXLK3` and the
canonical `com.hinoshiba.stagepane` bundle identifier. See `RELEASE.md` for
tag/version/build gates, archive verification, Organizer upload handoff, and
App Store Connect submission steps.

The submitted Mac App Store binary includes Arrange, Crop, and Draw and contains no
cross-application input or Accessibility permission/action path. No
direct-distribution build currently ships.

## Screenshot story

1. **見せたいものだけ、このステージへ。** — the clean Share Stage beside the
   private Stage Workspace, making the share/private boundary unmistakable.
2. **無料で4つ。Proならアプリ側の件数制限なし。** — the Workspace layer list beside the Canvas,
   the clear Pro label, the Mac/OS resource qualification, and its removal caution.
3. **配置・切り抜き・手書き・Audience画像を、大きな画面で。** — the private Workspace with the
   Mac App Store build's Arrange and Draw modes, per-layer Crop actions, bounded in-memory ink, and
   explicit Copy/Save Audience Image actions.
4. **レーザーとロゴを、発表に合わせる。** — laser color/size/glow and the
   Free-always-on / Pro-optional StagePane mark.
5. **ひと押しで隠し、終わったら完全停止。** — Curtain with the mark and Stop All.

Use real shipping UI, no unsupported claims, no meeting-service logos suggesting
partnership, and no “#1” or ranking guarantee. Export opaque 2880×1800 images
from the exact Store candidate, and localize screenshots and alt text for
Japanese and English.

## 0.4.2 App Review notes draft

Exact-candidate manual acceptance is pending. Use this concise block for the
0.4.2 candidate only after its acceptance checks have been recorded:

Keep the copied Notes text within Apple's [4,000-byte limit](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/).
Measure its UTF-8 size after removing the Markdown quote prefixes.

> No sign-in is required.
>
> Share only the "StagePane Stage" window in your meeting app; keep
> "StagePane Workspace — Keep Private" private. In Workspace, choose Add Source
> and approve a harmless window, app, or display in Apple's ScreenCaptureKit
> picker. Each selection authorizes only that content for its capture session.
> StagePane requests no broad Screen Recording or Accessibility permission.
> Free supports four simultaneous sources; a fifth Add Source attempt opens Pro.
>
> For this update, drag Stage content to move its titleless window, including
> while StagePane is inactive; the perimeter remains resizable. In Stage
> Settings, compare Current Stage Rendering Size with Audience PNG dimensions.
> Shrink Stage, then choose Enlarge Stage for Sharing: it grows the same window
> toward the preset size within the current screen, preserving its identity
> without shrinking an already larger Stage. For a separate macOS Space, choose
> Enter Stage Full Screen before starting your meeting share. Command-1 returns
> to the private Workspace; Control-Command-F toggles Stage full screen. The
> complete canvas keeps its preset proportions; PNGs exclude full-screen
> margins. Select only the Stage window and keep it open, not minimized. Check
> on a receiving device that Stage keeps updating while you edit in Workspace.
> Enlarge is available in windowed mode. The meeting app chooses capture and
> transmission resolution; neither size readout guarantees received resolution.
>
> StagePane Pro (com.hinoshiba.stagepane.pro) is a one-time non-consumable In-App
> Purchase, not a subscription. It removes the app's source-count limit and
> makes the Stage/Curtain/Audience PNG mark optional. Practical source count
> depends on the Mac and OS. Open Pro from the sidebar or fifth-source attempt;
> verify StoreKit's localized price, Restore Purchases and Continue Free.
> Canceling does not change or stop Stage. For IAP review screenshots, use the
> real Pro screen under StoreKit Configuration, Sandbox or TestFlight, showing
> price, one-time wording and both actions. Source-build fixtures are not
> purchase evidence.
>
> Arrange/Crop/Draw change only StagePane's composition and never forward input
> to source apps. Crop is a private draft until Apply and does not narrow the
> source approved in the picker. Draw stores bounded ink in memory. Hide pauses
> a source and clears its pixels while retaining placement/crop/order; Show
> waits for a fresh complete frame. Curtain covers only audience output without
> stopping capture. Stop All ends every stream and removes all layers.
> Copy/Save Audience Image creates one clean local PNG only when chosen.
>
> StagePane is sandboxed, has no network entitlement, and sends no screen
> content, drawings or other data to the developer or third parties. It does
> not record video, capture audio/microphone, use analytics/ads or operate a
> publisher server. Live frames remain only in memory and are released on Hide,
> removal, Stop All or quit. Only explicitly copied/saved PNGs persist. Meeting
> apps transmit shared Stage content; enabled clipboard/file synchronization
> may transmit user-created PNGs. Local preferences include window geometry and three
> rating-prompt timing values. Apple handles Pro commerce; no screen content is
> included.
>
> The Guideline 2.1 privacy reply for 0.4.0 (7), submission
> 90569aa7-c006-4848-8d52-4ec9aaaf46c5, is historical. Its disclosure/sharing/
> retention details remain in https://stagepane.hinoshiba.com/#privacy (JA),
> https://stagepane.hinoshiba.com/en/privacy/ (static EN), and bundled
> Contents/Resources/PRIVACY.md.

## Detailed reviewer walkthrough reference

> StagePane is a focused screen-sharing utility with two normal macOS windows:
> “StagePane Stage” is the clean window to share, while “Stage Workspace” is the
> private live Canvas for arranging, cropping, drawing, and taking an Audience
> Stage PNG. A persistent layer list stays beside the Canvas, including at the
> minimum 900×620-point Workspace size. Navigation also provides Stage Settings,
> Appearance, Permissions, Privacy, and About. It
> does not add a display, replace or imitate the macOS desktop, provide an app
> launcher, modify Finder or the Dock, install a driver, use private APIs, or
> continue running after the user quits.
>
> The app can be tested without permission by sharing its neutral Stage window.
> To test source composition, choose “Add Source,” approve exactly one test
> window, app, or display in the macOS ScreenCaptureKit system picker, and
> repeat for up to four sources in Free. A StagePane Pro non-consumable purchase
> removes StagePane's source-count limit, so source five and additional sources
> can be added while Mac performance and operating-system constraints permit.
> To verify entitlement loss, first keep more than four sources active with Pro,
> then revoke or refund the test entitlement: the existing session remains
> intact, the StagePane mark returns, and only new source additions are blocked.
> Each source appears in the private layer list from front to back,
> where “Hide” pauses only that stream and makes its layer transparent in the
> Stage, private Workspace, and Audience PNG output while preserving placement,
> crop, and z-order. The hidden layer remains selectable in the list. “Show”
> resumes it and reveals it only after a new complete frame arrives.
> “Replace” reopens the picker for only that item, and
> “Remove” asks for confirmation, ends only its stream, and deletes its layer.
> If macOS ends sharing outside StagePane, the old frame is immediately removed
> while that layer's placement, crop, and stacking order remain. “Select Again”
> reconnects a new picker choice to the same layer; Remove or Stop All explicitly
> deletes retained layers.
> Select an overlapping rear or hidden layer in the list and drag its private
> title badge or use arrow keys to move it. Its resize handle remains reachable
> above overlapping layers. Only the selected layer has editing chrome, and
> its transparent interior lets a click on visible foreground content select
> that foreground layer naturally. Selecting, dragging, resizing, or opening
> Crop does not change z-order. “Move Forward,” “Move Backward,” “Bring to Front,”
> and “Send to Back” update the audience stack and list explicitly while
> preserving placement and crop. Commands at the stack boundaries have no effect.
> “Auto Arrange” and the other Quick Layout presets also remain available.
> These actions change only StagePane's composition. The selected tile and each
> layer row have a crop button; it shows that exact layer in full in the private Workspace and lets the reviewer move
> or resize a draft frame. The public Stage retains the previously applied crop
> until “Apply Crop”; Cancel, a mode change, or source loss discards the draft.
> Reset to Full Source also changes only the draft. Cropping is a local
> composition mask: while the stream is running, the complete source selected in
> Apple's picker remains in that stream. Applied crop rectangles remain only in
> memory for the current StagePane run, including while a disconnected layer waits
> for Select Again, until Remove, confirmed Stop All, or app termination.
> StagePane provides global Arrange and Draw modes plus Crop on each layer. Arrange
> changes Stage placement, a layer's Crop changes only its visible source region, and Draw adds
> bounded in-memory vector ink to
> both the private Workspace and public Stage. Draw hides the audience pointer;
> returning to Arrange or opening a layer crop restores the selected pointer style. The Curtain hides
> ink and Stop All/final-source removal clears it. The StagePane process does not record,
> encode, automatically save, or transmit frames. Only an explicit “Copy
> Audience Image” or “Save Audience Image…” action creates one local PNG of the
> clean Stage; Copy uses the pasteboard, and Save writes only to the location the
> user chooses in the macOS save panel. Audio and microphone capture are
> disabled. “Stop All” ends every source, discards its pixels from both local
> display surfaces, and removes every layer. “Curtain” hides only the public Stage and does not
> bring its window to the front. It does not pause any source; unpaused streams
> continue and the private Stage Workspace remains available for preparation.
> Stage Workspace must remain private.
>
> StagePane Pro is reachable from the private Workspace sidebar, the app menu,
> a fifth Add Source attempt in Free, or an attempt to turn off the StagePane
> mark. It is a one-time non-consumable purchase. The screen shows StoreKit's
> localized price, clearly says it is not a subscription, offers Continue Free
> and Restore Purchases, and never appears in the audience Stage. Only a
> StoreKit-verified transaction for `com.hinoshiba.stagepane.pro` unlocks it.
> On successful purchase from the source limit, the app resumes Apple's picker;
> from the mark toggle, it completes the requested mark removal. Canceling never
> changes or stops the current Stage.
>
> Under “Appearance,” the pointer can remain standard, appear as a local red
> laser dot in the Stage, or be hidden. Its color, size, and glow are adjustable,
> and the dot appears only on the frontmost
> source; when that source is paused there is no dot and no fallback to a source
> behind it. Draw mode temporarily hides every pointer style. Laser pointer mode
> does not request an additional permission and
> does not retain pointer coordinates. A translucent
> StagePane mark is shown at the lower-right of the holding screen, shared
> content, and Curtain, and is mirrored in the private Workspace. Free always
> shows it; StagePane Pro makes it optional, including in Audience PNG output.
>
> StagePane uses SwiftUI, AppKit, AVFoundation display layers, and
> ScreenCaptureKit public APIs. It is sandboxed and has no network entitlement,
> analytics, ads, StagePane account, publisher server, external updater, or
> license-key mechanism. Optional Pro commerce uses Apple StoreKit for localized
> product information and verified transactions; no screen content enters that flow. It has no
> Accessibility/Input Monitoring permission request.

Attach a short reviewer video showing both window titles and roles, adding
four Free sources, the fifth-source Pro entry point, the normal Pro screen and
Restore Purchases, the persistent front-to-back layer list, covered/hidden layer
selection, title-badge/keyboard movement and resize without implicit reordering,
all four explicit ordering actions, Hide/Show with fresh-frame return,
replace, removal confirmation, all four Quick Layout presets, the Arrange/Draw switch, each layer's
Crop action and target label, crop draft, Reset to
Full Source, Apply, and Cancel (including an unchanged Stage before Apply),
unchanged physical pointer,
Draw/Clear/Curtain behavior, explicit Copy/Save Audience Image actions, the
watermark, and Stop All. The video must use the exact Mac App Store candidate
and must not show an Accessibility permission prompt. Provide
current Zoom, Teams, and Meet test results only as compatibility evidence, not
as affiliations.

## Review-risk checklist

- Guideline 2.3.1: metadata matches the normal-window implementation.
- 2.1(b): the IAP is complete and reviewable, with a review-only screenshot and
  exact navigation steps in Review Notes.
- 2.3.2: every customer-facing screenshot and description clearly labels
  features that require the StagePane Pro In-App Purchase.
- 3.1.1: digital feature unlock uses only Apple's non-consumable In-App
  Purchase, with no external purchase or license-key path.
- 2.5.1: documented public APIs only. The submitted sandboxed binary contains no
  cross-application Accessibility action path, raw mouse/keyboard
  event synthesis, keyboard/drag forwarding, or event tap.
- 2.5.8: no alternate desktop/home-screen environment.
- 2.5.14: explicit user consent and visible preview status/stop control.
- 4.1: original name, icon, copy, UI, and screenshots.
- 4.2: material utility beyond a blank window: source composition, confirmation
  and pause controls, Arrange and Draw modes, per-layer Crop actions, presets, Curtain, drawing, laser/
  watermark appearance, safe-area, holding screen, and window behavior.
- 5.1: accessible privacy policy and accurate Data Not Collected answers.
- Mac Store rules: sandboxed, self-contained, no self-update or license screen.

Always re-read the live App Review Guidelines before submission; this checklist
is a dated engineering interpretation, not approval or legal advice.

## Accessibility declaration gate

Only claim an App Store Accessibility Nutrition Label feature after all common
tasks pass with it. The release gate covers VoiceOver, Voice Control,
keyboard-only control, sufficient contrast, non-color state cues, Reduce Motion,
Increase Contrast, and text scaling. The Stage Workspace canvas must expose
stable editor/source-tile controls and must not announce individual video
frames.

## Ratings and ranking ethics

Rank cannot be guaranteed. Optimize for first-stage success, retention, honest
metadata relevance, crash-free sessions, accessibility, privacy trust, and
support quality. Request a rating only after at least three clean sessions that
reached a real preview, lasted one minute or longer, and ended at a clean Stop
All/close boundary using Apple's standard API. Do not offer
rewards, gate features, route low ratings away, or manipulate discovery.
