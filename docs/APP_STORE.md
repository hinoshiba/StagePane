# App Store positioning and review notes

## Metadata draft — 0.4.5 (build 12)

This candidate follows 0.4.4 (build 11). Exact-candidate manual acceptance and
StoreKit purchase evidence remain pending. These fields describe the current
implementation; they are not a record of upload, review, or release.

- **Name:** StagePane
- **Subtitle (EN):** Arrange windows for sharing
- **Subtitle (JA):** 見せたい画面を、並べて共有
- **Primary category:** Productivity
- **Secondary category:** Utilities
- **Tagline (EN):** Your work, together. Your space, private.
- **Tagline (JA):** 見せたいものを、ひとつの画面に。
- **Promotional Text (EN):** Put slides and demos together on a dedicated sharing Stage. Keep your own layout. Start free with four sources; Pro is a one-time purchase.
- **Promotional Text (JA):** 資料とデモを、ひとつの共有画面に。ウインドウを個別に選び、会議ではStageだけを共有。手元の配置を変えずに、見せる内容を整えられます。無料で4ソース、Proは買い切りです。
- **Privacy Policy URL (JA):** https://stagepane.hinoshiba.com/#privacy
- **Privacy Policy URL (EN):** https://stagepane.hinoshiba.com/en/privacy/

  The English URL serves standalone static policy text without JavaScript.
  The Japanese URL targets the policy text included in the root page's HTML.
  The existing `/privacy/` route redirects to that Japanese section; it does
  not contain standalone policy text.
- **Support URL (JA):** https://stagepane.hinoshiba.com/#support
- **Support URL (EN):** https://stagepane.hinoshiba.com/?lang=en#support

- **Keywords (EN draft):** `presentation,meeting,privacy,demo,teaching,webinar,laser,canvas,annotate,training,remote`
- **キーワード（JA案）:** `プレゼン,会議,ウインドウ,発表,デモ,講義,プライバシー,ポインター,注釈`

These avoid repeating the product name and current subtitle. Re-check the live
character/byte counter and duplication rules in App Store Connect before use.

Do not use competitor trademarks in metadata and do not use `virtual display`,
`second monitor`, `independent desktop`, `real display`, or equivalents. The app
creates a normal shareable window, not an `NSScreen`.

### What's New 0.4.5 — Japanese

> ソースの切り替えと再表示の安定性を改善しました。
>
> ・非表示からの再表示やソースの選び直しで、最新の映像サイズが正しく反映されるようにしました。
> ・ソースの再表示に失敗した後の表示と、再試行の動作を改善しました。
> ・ソースの停止と、観客向け画像のコピー・PNG保存の処理を改善しました。

### What's New 0.4.5 — English (U.S.)

> Improved reliability when switching and showing sources.
>
> • Keep the latest source dimensions in sync when showing a hidden source or replacing it.
> • Improve the display state and retry behavior after a source fails to resume.
> • Improve source cleanup and Audience Image copying and PNG saving.

These changes are relative to the 0.4.4 app.

### Description draft — Japanese

> 見せたいものを、ひとつの画面に。
>
> 資料とアプリのデモを、ひとつの共有画面に。StagePaneは、選んだ映像を手元のWorkspaceで並べ、会議では専用の「StagePane Stage」ウインドウを共有するmacOSアプリです。手元のウインドウ配置を変えずに、大きさ・位置・重なりを整えられます。
>
> 見せる範囲を選ぶ
> Appleの選択画面で、ウインドウ、アプリ、または画面を追加します。範囲を絞るにはウインドウを個別に選び、会議アプリでは「StagePane Stage」だけを共有してください。選ばなかった別アプリの通知や個人メモはStageに含まれません。選択したウインドウ内の通知・ダイアログは映る場合があります。画面全体やアプリ全体を選ぶと共有範囲が広がり、会議でデスクトップやStagePane全体を共有するとWorkspaceも映る場合があります。
>
> 無料で使える主な機能
> ・同時に4つのソースを配置。自由配置とグリッドなどの配置プリセット
> ・レイヤー名の変更と、レイヤーごとの色の反転
> ・手元で範囲を下書きし、「適用」で反映するレイヤーごとの切り抜き
> ・ペン、蛍光ペン、部分消しゴムと、2倍・3倍・4倍の虫眼鏡
> ・標準・レーザー・非表示から選べる共有ポインタ
> ・カーテン、レイヤーの非表示・再表示、選び直し、すべて停止
> ・16:9、4:3、9:16、1:1のStage形状
> ・観客向けStage画像のコピーとPNG保存（StagePaneロゴ入り）
>
> 設定はmacOSのメニューバーから「StagePane → 設定…」（⌘,）へ。ポインタ、Stage、ウインドウの動作、アクセスとプライバシー、Proをまとめて確認できます。
>
> 元のアプリの操作は、元のウインドウで行います。StagePaneは共有映像の構図や注釈を編集するもので、ソースアプリへクリックやキー入力を送信しません。
>
> 表示と取得を分けて管理
> 切り抜きは表示範囲だけを変え、取得対象はAppleの選択画面で許可したソース全体です。カーテンはStageを覆いますが、画面取得は続きます。レイヤーの「非表示」はそのソースの取得を一時停止し、「すべて停止」はすべての取得を終了して全レイヤーを削除します。
>
> StagePane Pro — 1回限りのアプリ内課金
> ・アプリ側のソース件数制限を解除。利用可能数はMacの性能とOSの制約に依存します
> ・Stage、カーテン、保存・コピーするStage画像のStagePaneロゴを非表示にできます
>
> Proは買い切りで、サブスクリプションではありません。価格は購入前にApp Storeが表示します。購入済みの場合はPro画面の「購入を復元」を利用できます。
>
> 画面の処理は、このMacで
> アカウントは不要です。StagePaneは画面を開発者に送信せず、録画・音声取得・広告・行動分析を行いません。画面と手書きは使用中のメモリで扱い、画像を残すのは利用者が明示的にコピーまたはPNG保存した場合だけです。参加者への配信は、お使いの会議アプリが行います。
>
> macOS 14以降。Apple SiliconとIntel Macに対応。アプリ全体の画面収録アクセスは任意で、未許可でもAppleの選択画面で選んだ内容を共有できます。

### Description draft — English (U.S.)

> Your work, together. Your space, private.
>
> Put slides and app demos together on one sharing Stage. Arrange selected content in your own Workspace, then share the dedicated “StagePane Stage” window in your meeting app. Move, resize, and overlap sources without rearranging the windows on your desktop.
>
> Choose what to show
> Add a window, app, or display through Apple’s picker. For a narrow scope, choose individual windows and share only “StagePane Stage” in your meeting app. Other apps’ notifications and personal notes outside those selected windows are not included in the Stage. Notifications or dialogs inside a selected window may appear. Selecting an entire app or display widens the source scope; sharing your desktop or the whole StagePane app in a meeting may also expose Workspace.
>
> Included free
> • Compose four simultaneous sources with freeform and preset layouts
> • Rename layers and invert colors for each layer
> • Draft a layer’s crop privately, then apply it explicitly
> • Pen, highlighter, partial eraser, and a 2×, 3×, or 4× magnifying lens
> • Standard, laser, or hidden audience pointer
> • Curtain, layer Hide/Show, source replacement, and Stop All
> • 16:9, 4:3, 9:16, and 1:1 Stage shapes
> • Copy or save an audience Stage PNG with the StagePane mark
>
> Open StagePane → Settings… (Command-,) from the macOS menu bar for Pointer, Stage, Window, Access & Privacy, and Pro.
>
> Operate your source apps in their original windows. StagePane edits the shared composition and annotations; it does not send clicks or keystrokes to source apps.
>
> Control display and capture separately
> Crop changes only the displayed area; the complete source approved in Apple’s picker remains the capture source. Curtain covers the Stage while capture continues. Hide pauses one source. Stop All ends every capture session and removes all layers.
>
> StagePane Pro — one-time In-App Purchase
> • Remove the app’s source-count limit. Practical capacity depends on your Mac’s performance and operating-system constraints
> • Optionally hide the StagePane mark on the Stage, Curtain, and copied or saved Stage images
>
> Pro is a one-time purchase, not a subscription. The App Store displays the price before purchase. Use Restore Purchases in the Pro window when needed.
>
> Processed on your Mac
> No account is required. StagePane sends no screen content to the developer and includes no video recording, audio capture, advertising, or analytics. Screen content and drawings stay in memory during use; an image persists only when you explicitly copy it or save a PNG. Your meeting app handles transmission to participants.
>
> Requires macOS 14 or later on Apple Silicon or Intel. App-wide Screen Recording Access is optional: Apple’s picker can share selected content without it.

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

1. **見せたいものを、ひとつの画面に。** — individually selected windows in the
   audience Stage beside the private Workspace. Make the condition explicit:
   the meeting app shares only the Stage window, not the display or whole app.
2. **無料で4つ。Proは買い切り。** — the current Workspace and private Pro purchase
   screen, localized StoreKit price, Mac/OS capacity qualification, and the
   distinction between free features and optional mark removal.
3. **並べる。切り抜く。伝える。** — the layer list, Arrange/Draw/Magnify tools,
   per-layer Crop with Apply/Cancel, and explicit Copy/Save Audience Image.
   Show real layer naming and color inversion where useful; names stay private.
4. **ポインタの設定を、いつもの場所に。** — StagePane → Settings… (Command-,),
   Pointer controls, and the Stage → Pointer shortcut menu. Draw/Magnify
   temporarily suppress the pointer without changing the saved style.
5. **準備中はカーテン。終わったら停止。** — Curtain covering the audience Stage
   while capture continues, with Stop All separately ending streams and
   removing all layers.

Use real shipping UI, no unsupported claims, no meeting-service logos suggesting
partnership, and no “#1” or ranking guarantee. Export opaque 2880×1800 images
from the exact Store candidate, and localize screenshots and alt text for
Japanese and English. Website illustrations and source-build fixtures do not
establish StoreKit purchase behavior or exact-candidate acceptance.

## 0.4.5 App Review notes draft

Exact-candidate manual acceptance is pending. Use this block only after the
0.4.5 (build 12) candidate's acceptance checks have been recorded. Product
loading, localized price, purchase/restore/cancel/pending behavior, and IAP
review images require the actual StoreKit review environment; synthetic
source-build fixtures are not purchase evidence.

Keep the copied Notes text within Apple's [4,000-byte limit](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/).
Measure its UTF-8 size after removing the Markdown quote prefixes. Use the
English block by default, or the Japanese alternative, never both concatenated.

### English (preferred)

> StagePane 0.4.5, build 12. No sign-in or demo account is required.
>
> In Workspace, choose Add Source and approve a harmless window in Apple’s ScreenCaptureKit picker. Each selection authorizes that source for its capture session. Repeat to compose sources. In your meeting app share only “StagePane Stage”, check the target, then open the Curtain. Whole-app or whole-display sharing can expose Workspace and private settings. Notifications/dialogs inside a selected source may appear.
>
> The first launch may show an optional Mac Screen Recording Access guide. Only Allow requests broad access; Continue or Escape dismisses it. Apple’s picker remains usable without broad access. Recheck in StagePane > Settings > Access & Privacy > Check Mac Screen Recording Access. Accessibility and Input Monitoring access are never requested.
>
> Updated in 0.4.5: source sizing during Show and replacement, recovery after a failed Show, and capture cleanup. Please check Hide/Show, source replacement, Stop All, and Copy/Save Audience Image with harmless test content.
>
> StagePane > Settings (Command-,) and the menu-bar status icon open the same private window. The Stage’s right-click menu controls its size, full screen, and window behavior. Layer names stay private and session-only; per-layer Invert Colors affects that source across Workspace, Stage, Magnify, and PNG output.
>
> Free permits four simultaneous sources. A fifth Add Source attempt opens the private Pro purchase window. Settings > Pro > Purchase or Restore also opens it. Product com.hinoshiba.stagepane.pro is a one-time non-consumable IAP, not a subscription. Pro removes the app’s source-count limit and makes the Stage/Curtain/PNG mark optional; practical capacity depends on Mac and OS. Check the localized price, Restore Purchases, and Continue Free. Canceling leaves the Stage running.
>
> Operate source apps in their original windows. Arrange/Crop/Draw/Magnify never forward input. Crop is private until Apply, and never narrows the complete picker-approved capture source. Hide pauses one source and clears its pixels while retaining its layer; Show waits for a fresh frame. Curtain covers audience output but capture continues. Stop All ends all streams and removes all layers, including disconnected ones. Copy/Save Audience Image creates one local PNG only when chosen.
>
> The sandboxed app has no network entitlement and sends no screen content, drawings or other data to the developer or third parties. No video/audio recording, analytics or ads. Frames stay in memory and are released on Hide, removal, Stop All or quit. Only explicitly copied/saved PNGs persist; clipboard/file synchronization can transmit those images. Meeting apps transmit the Stage. Local preferences include appearance, window behavior, last Settings pane, an access-guide flag and rating-prompt timing; Apple handles IAP without screen content.
>
> Privacy: https://stagepane.hinoshiba.com/#privacy (JA), https://stagepane.hinoshiba.com/en/privacy/ (EN), and bundled PRIVACY.md.

### Japanese alternative

> StagePane 0.4.5、ビルド12。ログインやデモアカウントは不要です。
>
> Workspaceの「ソースを追加」からAppleのScreenCaptureKit選択画面で無害なテスト用ウインドウを許可します。許可は選択した内容と取得セッションに限定されます。会議アプリでは「StagePane Stage」だけを共有し、対象を確認してカーテンを開いてください。アプリ全体・画面全体の共有ではWorkspaceや設定が映る場合があります。選択したソース内の通知・ダイアログも映る場合があります。
>
> 初回は任意の「Macの画面収録アクセス」案内を表示する場合があります。「許可する」だけが広範なアクセスを要求し、「続ける」やEscapeで閉じられます。未許可でもAppleの選択画面を利用できます。再確認は「StagePane → 設定 → アクセスとプライバシー」から行います。アクセシビリティや入力監視は要求しません。
>
> 0.4.5では、再表示・選び直し時の映像サイズの反映、再表示に失敗した後の再試行、ソース停止時の処理を改善しました。無害なテスト用コンテンツで、非表示・再表示、選び直し、すべて停止、観客向け画像のコピー・PNG保存をご確認ください。
>
> 「StagePane → 設定」（⌘,）とメニューバー右側のアイコンは同じ手元用の設定を開きます。Stageの右クリックメニューからサイズ、フルスクリーン、ウインドウの動作を変更できます。レイヤー名は手元用でセッション中だけ保持します。色反転はそのソースに適用され、Workspace・Stage・虫眼鏡・PNGへ反映します。
>
> 無料版は同時に4ソースまでです。5件目の追加、または「設定 → Pro → 購入・復元」でPro購入画面を開きます。com.hinoshiba.stagepane.proは1回限りの非消耗型アプリ内課金で、継続課金ではありません。Proはアプリ側の件数制限を解除し、Stage・カーテン・PNGのロゴを任意に非表示にします。実用上の件数はMacとOSに依存します。価格と「購入を復元」「無料版を続ける」をご確認ください。キャンセルしてもStageは動作を続けます。
>
> 元アプリの操作は元のウインドウで行い、StagePaneは入力を転送しません。切り抜きは適用まで手元の下書きで、許可したソース全体の取得範囲を狭めません。「非表示」は1ソースを一時停止して映像を消し、再表示では新しいフレームを待ちます。カーテンは表示を覆いますが取得は続きます。「すべて停止」は全取得を終了し、切断中を含む全レイヤーを削除します。
>
> アプリはサンドボックス化され、ネットワーク接続の権限を持ちません。画面等を開発者や第三者に送信せず、録画・音声取得・分析・広告はありません。映像はメモリ内で扱い、非表示・解除・すべて停止・終了で解放します。明示的にコピー・保存したPNGだけが残ります。会議アプリやクリップボード・ファイル同期は別途送信する場合があります。設定、最後の設定項目、初回案内済みフラグ、評価依頼の時期を判断する値はローカルに保存します。購入はAppleが処理し、画面を含みません。
>
> Privacy: https://stagepane.hinoshiba.com/#privacy (JA), https://stagepane.hinoshiba.com/en/privacy/ (EN), bundled PRIVACY.md.

## Detailed reviewer walkthrough reference

This walkthrough describes the 0.4.5 candidate UI. The metadata and review-note
drafts above remain pending exact-candidate acceptance. Prepare submission
evidence only after validating the exact release candidate.

> StagePane is a focused screen-sharing utility with two primary macOS windows:
> “StagePane Stage” is the clean window to share, while “Stage Workspace” is the
> private live Canvas for arranging, cropping, drawing, magnifying, and taking an Audience
> Stage PNG. A persistent layer list stays beside the Canvas, including at the
> minimum 900×620-point Workspace size. StagePane → Settings… (Command-,)
> opens a separate native window with Pointer, Stage, Window, Access & Privacy,
> and Pro. The status icon opens the same Settings window. It starts on Pointer
> and remembers the last pane; changes apply immediately without discarding the
> selected layer, tool, or crop draft. Workspace and Settings follow macOS
> Light or Dark appearance. About StagePane remains in the app menu, and Pro
> purchases use a separate private window. These windows are not technically
> excluded from whole-display or whole-app sharing: share only Stage. StagePane
> does not add a display, replace or imitate the macOS desktop, provide an app
> launcher, modify Finder or the Dock, install a driver, use private APIs, or
> continue running after the user quits.
> Settings → Stage → Output Details shows Stage rendering size. Audience PNG
> exports instead use the selected shape preset's dimensions; neither size
> guarantees the resolution transmitted by the meeting app.
>
> Right-click or Control-click the Stage for Maximize/Restore, Enlarge Stage for
> Sharing, full screen, window behavior, Show Stage Workspace, and Stage
> Settings. The latter opens Settings → Stage. These commands are also in the
> Stage and Window menus. Maximize and sharing enlargement are unavailable in
> full screen, and size changes are disabled during full-screen transitions.
>
> The app can be tested without permission by sharing its neutral Stage window.
> At launch, a public API reads the app-wide Mac Screen Recording Access status.
> On the first check only, if access is not allowed, an optional private guide
> appears. Only its “Allow…” button requests access; “Continue” leaves
> picker-based sharing available without it. Later launches do not repeat the
> guide. Reopen it from Settings → Access & Privacy → Check Mac Screen
> Recording Access.
> Local preferences store the first-check-completed flag and this window's frame,
> not the permission status. Source-selection or capture-start errors remain in
> Workspace until dismissed or resolved, with retry and detail controls; they do
> not open a separate error window or imply missing app-wide access.
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
> Rename in a layer's More menu gives it a private session-only name, visible
> in the list, Canvas, and crop controls, never in the audience Stage or PNG.
> Empty names restore the automatic title. A name survives source replacement,
> reconnection, Hide/Show, and layout changes until that layer is removed,
> Stop All, or quit. Invert Colors in the selected-layer tools or More menu
> inverts all source colors, including photos, in Workspace, Stage, Magnify,
> and Audience PNG. Other layers, background, annotations, and the laser
> pointer retain their colors. A system cursor embedded in the captured source
> pixels is part of that source and is inverted too. Turning inversion off
> restores the original colors.
> Select an overlapping rear or hidden layer in the list and drag its private
> title badge or use arrow keys to move it. Its resize handle remains reachable
> above overlapping layers. Only the selected layer has editing chrome, and
> its transparent interior lets a click on visible foreground content select
> that foreground layer naturally. Selection, Canvas movement, resizing, and
> opening Crop do not change z-order. Drag a layer's list grip to reorder it;
> higher rows are in front, and dropping commits the order. Canceling the drag
> preserves the order. Placement, crop, and selection remain unchanged.
> Finish Crop or close the source picker before reordering. “Move Forward,”
> “Move Backward,” “Bring to Front,” and “Send to Back” remain in the layer's
> More menu as keyboard-accessible alternatives. Commands at the stack
> boundaries have no effect. The Layout menu offers Grid, Side by Side,
> Stacked, and Picture in Picture without changing source order.
> These actions change only StagePane's composition. Crop is available in the
> fixed selected-layer tools below the Canvas and each layer's More menu;
> it shows that exact layer in full in the private Workspace and lets the reviewer move
> or resize a draft frame. The public Stage retains the previously applied crop
> until “Apply Crop”; Cancel, a mode change, or source loss discards the draft.
> Reset to Full Source also changes only the draft. Cropping is a local
> composition mask: while the stream is running, the complete source selected in
> Apple's picker remains in that stream. Applied crop rectangles remain only in
> memory for the current StagePane run, including while a disconnected layer waits
> for Select Again, until Remove, confirmed Stop All, or app termination.
> StagePane provides Arrange, Draw, and Magnify modes plus Crop on each layer. Arrange
> changes Stage placement, a layer's Crop changes only its visible source region, and Draw adds
> bounded in-memory vector ink to
> both the private Workspace and public Stage. Magnify enlarges content in a
> temporary lens without changing the source layout or controlling the source app.
> Draw and Magnify hide the audience pointer;
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
> StagePane Pro is reachable from Settings → Pro → Purchase or Restore, the app menu,
> a fifth Add Source attempt in Free, or an attempt to turn off the StagePane
> mark. It is a one-time non-consumable purchase. The screen shows StoreKit's
> localized price, clearly says it is not a subscription, offers Continue Free
> and Restore Purchases, and never appears in the audience Stage. Only a
> StoreKit-verified transaction for `com.hinoshiba.stagepane.pro` unlocks it.
> While the app and Pro window remain active and the originating request is
> still current, a successful purchase from the source limit resumes Apple's
> picker once; a purchase from the mark toggle completes the requested mark
> removal. Closing or minimizing Pro, moving to another window or app, or
> starting another edit cancels automatic continuation without discarding a
> verified entitlement. If purchase authentication moves to another app, use
> “Add the Next Source” or “Hide the StagePane Mark” in the still-open Pro
> window after purchase. These actions are localized as “次のソースを追加” and
> “ロゴを非表示”. If Pro was closed, use Add Source or Settings → Stage to
> continue manually. A direct Pro purchase starts no unrequested source or
> mark change. Canceling never changes or stops the current Stage.
>
> Under Settings → Pointer, the pointer can remain standard, appear as a local red
> laser dot in the Stage, or be hidden. Its color, size, and glow are adjustable,
> and the dot appears only on the frontmost
> source; when that source is paused there is no dot and no fallback to a source
> behind it. Stage → Pointer provides quick changes and a link to the same
> settings. Its checkmark reflects the saved choice, including while Draw and
> Magnify temporarily hide every pointer style. Laser pointer mode
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
unchanged physical pointer, Magnify and its exit action,
Draw/Clear/Curtain behavior, explicit Copy/Save Audience Image actions, the
watermark, and Stop All. The video must use the exact Mac App Store candidate
and must not show an Accessibility permission prompt. Include the native
Settings panes, quick pointer menu and suppression state, Rename, Invert Colors,
and the Stage context menu. Provide
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
