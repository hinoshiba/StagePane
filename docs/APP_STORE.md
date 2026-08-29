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
  includes two sources; StagePane Pro expands to four and removes the mark.
- **Promotional Text (JA):** 見せたいものだけ、ひとつのステージへ。無料で2ソース、StagePane Proなら最大4ソースとロゴ非表示。
- **What's New 0.2.0 (EN):** StagePane Pro is now available as a one-time
  In-App Purchase. Free supports two simultaneous sources; Pro expands this to
  four and lets you hide the StagePane mark. Restore Purchases is available
  from the Pro screen.
- **What's New 0.2.0 (JA):** StagePane Proを追加しました。無料版は同時に2ソース、買い切りのProは最大4ソースとStagePaneロゴの非表示に対応します。Pro画面から購入の復元もできます。
- **Privacy Policy URL (JA):** https://stagepane.hinoshiba.com/privacy/
- **Privacy Policy URL (EN):** https://stagepane.hinoshiba.com/en/privacy/
- **Support URL (JA):** https://stagepane.hinoshiba.com/#support
- **Support URL (EN):** https://stagepane.hinoshiba.com/en/#support

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
> ・同時に2つのソースを配置
> ・自由配置とクイック配置
> ・選択した1ソースを手元で下書きし、「適用」で反映する切り抜き
> ・ペン、蛍光ペン、部分消しゴム
> ・Privacy Curtain、一時停止、選び直し、すべて停止
> ・レーザーポインターと4種類のStage形状
> ・Audience Stage画像のコピー／PNG保存（StagePaneロゴ入り）
>
> StagePane Pro（1回限りのアプリ内課金）：
> ・同時ソースを最大4つへ拡張
> ・Stage、Curtain、Audience画像のStagePaneロゴを非表示
>
> Proは買い切りで、サブスクリプションではありません。価格はApp Storeが
> 購入前に表示します。復元が必要な場合はPro画面の「購入を復元」を利用できます。
>
> StagePaneは録画、音声取得、StagePaneアカウント、広告、利用解析を行いません。
> 画面はMac上で処理し、自動保存や発行者サーバーへの送信はしません。

### Description draft — English (U.S.)

> Put only what you mean to show on one dedicated sharing Stage.
>
> StagePane separates the audience-facing Stage from the Workspace you control
> privately. Add only a window, app, or display you approve in Apple’s picker,
> then share the normal “StagePane Stage” window in your meeting app.
>
> Included free:
> • Compose two simultaneous sources
> • Freeform and quick layouts
> • Per-source Crop with a private one-source draft and explicit Apply or Cancel
> • Pen, highlighter, and partial eraser
> • Privacy Curtain, pause, replace, and Stop All
> • Laser pointer and four Stage shapes
> • Copy or save an Audience Stage PNG with the StagePane mark
>
> StagePane Pro — one-time In-App Purchase:
> • Expand to four simultaneous sources
> • Hide the StagePane mark from the Stage, Curtain, and Audience images
>
> Pro is a one-time purchase, not a subscription. The App Store shows the price
> before purchase. When restoration is needed, use Restore Purchases on the
> Pro screen.
>
> StagePane has no recording, audio capture, StagePane account, ads, or usage analytics.
> It processes screen content on your Mac, never saves it automatically, and
> never sends it to a publisher-operated server.

## Shipping build route

Push a reviewed `v<major>.<minor>.<patch>` tag and let the `App Store Release`
Xcode Cloud workflow archive the checked-in `StagePane.xcodeproj` with the
shared `StagePane-AppStore` scheme. The target is sandboxed, has no network
entitlement, grants read/write access only to locations the user explicitly
selects for Audience PNG export, and bundles the privacy manifest, English/Japanese usage strings,
`AppIcon.icns`, help, privacy policy, license, notices, trademark policy, and
brand-asset license. Xcode Cloud uses automatic signing for Team `94HVVWXLK3`
and the canonical `com.hinoshiba.stagepane` bundle identifier. See
`RELEASE.md` for workflow settings, tag/version gates, and handoff steps.

The submitted Mac App Store binary includes Arrange, Crop, and Draw and contains no
cross-application input or Accessibility permission/action path. No
direct-distribution build currently ships.

## Screenshot story

1. **見せたいものだけ、このステージへ。** — the clean Share Stage beside the
   private Stage Workspace, making the share/private boundary unmistakable.
2. **Proなら最大4つ。無料でも安全機能はすべて。** — Workspace → Sources,
   the clear Pro label, and its removal caution.
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

## 0.2.0 App Review notes

Use this concise block in App Store Connect:

> No sign-in is required.
>
> StagePane has two normal macOS windows: “StagePane Stage” is the
> audience-facing window to share; “StagePane Workspace — Keep Private” is the
> private editor. In Workspace, choose Add Source and approve a harmless
> window, app, or display in Apple’s ScreenCaptureKit picker. Free supports two
> simultaneous sources. With two sources active, choose Add Source again to
> open StagePane Pro.
>
> StagePane Pro is a one-time non-consumable In-App Purchase
> (`com.hinoshiba.stagepane.pro`). It is also available from the Workspace
> sidebar, the app menu, and by trying to turn off the StagePane mark under
> Appearance. The Pro screen shows StoreKit’s localized price, states that it
> is not a subscription, and includes Restore Purchases and Continue Free. Pro
> unlocks up to four sources and makes the StagePane mark optional on the
> Stage, Privacy Curtain, and explicitly copied/saved Audience PNG. Canceling
> does not change or stop the current Stage.
>
> Arrange changes only StagePane’s local composition. Draw adds bounded
> in-memory ink to the Workspace and Stage. Privacy Curtain hides only the
> public Stage; Stop All ends every stream and removes every layer. Copy
> Audience Image and Save Audience Image create a PNG only after the reviewer
> explicitly chooses the action.
>
> StagePane is sandboxed. It does not record, capture audio or microphone
> input, create an account, use analytics or ads, upload frames, or operate a
> publisher server. Screen content stays on the Mac; StoreKit receives only
> product and verified transaction information.

## Detailed reviewer walkthrough reference

> StagePane is a focused screen-sharing utility with two normal macOS windows:
> “StagePane Stage” is the clean window to share, while “Stage Workspace” is the
> private live Canvas for arranging, cropping, drawing, and taking an Audience Stage PNG.
> Its Docker-style sidebar also contains Sources, Stage Settings, Appearance,
> Permissions, Privacy, and About. It
> does not add a display, replace or imitate the macOS desktop, provide an app
> launcher, modify Finder or the Dock, install a driver, use private APIs, or
> continue running after the user quits.
>
> The app can be tested without permission by sharing its neutral Stage window.
> To test source composition, choose “Add Source,” approve exactly one test
> window, app, or display in the macOS ScreenCaptureKit system picker, and
> repeat for two sources in Free or up to four after the StagePane Pro
> non-consumable purchase. Each source appears in the private source list,
> where “Pause” stops only that stream and makes its layer transparent in the
> Stage, private Workspace, and Audience PNG output while preserving placement,
> crop, and z-order. “Resume” starts it again and reveals it only after a new
> complete frame arrives. “Replace” reopens the picker for only that item, and
> “Remove” asks for confirmation, ends only its stream, and deletes its layer.
> If macOS ends sharing outside StagePane, the old frame is immediately removed
> while that layer's placement, crop, and stacking order remain. “Select Again”
> reconnects a new picker choice to the same layer; Remove or Stop All explicitly
> deletes retained layers.
> In Stage Workspace, drag or resize tiles in Arrange mode, or use “Auto
> Arrange." These gestures change only StagePane's composition. Each tile and
> source row has a crop button; it shows that exact layer in full in the private Workspace and lets the reviewer move
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
> a third Add Source attempt in Free, or an attempt to turn off the StagePane
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
two Free sources, the third-source Pro entry point, the normal Pro screen and
Restore Purchases, per-source pause/resume, replace, removal confirmation, drag,
resize, all four Quick Layout presets, the Arrange/Draw switch, each layer's
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
