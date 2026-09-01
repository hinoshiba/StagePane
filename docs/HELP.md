# StagePane Help / StagePane の使い方

## Share safely / 安全に共有する

1. Keep **StagePane Workspace — Keep Private** on your Mac.<br>
   **StagePane Workspace — 共有しない編集画面** は手元に置きます。
2. Choose **Add Source / ソースを追加** and approve one window, app, or
   display in the macOS system picker. Free supports four simultaneous sources;
   the one-time StagePane Pro purchase removes StagePane's source-count limit.
   The number that can run in practice depends on Mac performance and
   operating-system constraints.
3. Open **Canvas / キャンバス** in the private Stage Workspace to arrange,
   crop, or draw. Drag and resize sources there. Use **Pause / 一時停止**,
   **Resume / 再開**, **Replace / 選び直す**,
   or **Remove / 解除** in **Sources / ソース**, or **Auto Arrange / 自動配置**
   for an even grid.
   In Arrange mode, **Quick Layout / クイック配置** also offers Side by
   Side, Stacked, and Picture in Picture without changing source order.
4. In your meeting app, share **StagePane Stage — Share This Window / このウインドウを共有**.
5. Confirm the correct share target, then choose **Reveal Stage / カーテンを開く**.

Selecting an app can include every window owned by that app. Select a single
window when you want to limit the source more narrowly.

アプリを選ぶと、そのアプリが持つすべてのウインドウが含まれる場合があります。
共有範囲を狭くしたい場合は、アプリではなく1つのウインドウを選んでください。

## Permissions / アクセス権限

Workspace's persistent **Permissions / アクセス権限** view explains every
access path StagePane can use. Screen sharing is approved one selection at a
time in Apple's `SCContentSharingPicker`: choosing a window, app, or display
authorizes only that content for its capture session. StagePane does not request
separate, broad Screen Recording access, and canceling the picker grants no
source access.

Workspaceの常設 **アクセス権限** 画面では、StagePaneが利用できるアクセス経路を
確認できます。画面共有はAppleの `SCContentSharingPicker` で1件ずつ承認され、選んだ
ウインドウ、アプリ、または画面だけが、その取得セッション中に許可されます。別途、
広範な画面収録許可を求めることはなく、ピッカーをキャンセルした場合はソースへの
アクセスも始まりません。

In **Appearance / 見た目と動作**, set **Pointer appearance / カーソルの表示方法**
to **System / 通常**, **Laser pointer / レーザーポインター**, or **Hidden /
非表示**. The laser pointer's color, size, and glow are adjustable. Its dot is
drawn only over the frontmost Stage source; it does not replace the pointer you
see locally. If the frontmost source is paused, no dot is shown—StagePane does
not fall back to a source behind it.

「レーザーポインター」は色・サイズ・発光を調整できます。点はStage上の最前面ソース
にだけ表示され、手元で見ているmacOSのカーソルは置き換えません。最前面ソースが
一時停止中なら点は表示せず、背面のソースへは切り替えません。

The translucent **StagePane mark / StagePaneロゴ** appears in the lower-right of
the holding screen, shared content, and Curtain, and is mirrored in the private
Workspace. It is always shown in Free and can be disabled with StagePane Pro.

半透明の **StagePaneロゴ** は待機画面、共有内容、カーテンの右下に表示され、手元の
Workspaceにも反映されます。無料版では常に表示され、StagePane Proでは無効にできます。

**Pause / 一時停止** stops only that source's ScreenCaptureKit stream and
makes its layer transparent in the Stage, private Workspace, and Audience PNG
output. **Resume / 再開** restarts the same source and reveals it only after a
new complete frame arrives. Placement, crop, and z-order remain unchanged.

**一時停止** はそのソースのScreenCaptureKitストリームだけを停止し、Stage、手元用
Workspace、Audience PNGでレイヤーを透明にします。**再開** で同じソースの取得を再開し、
新しい完全なフレームが届いた時点で再表示します。配置・切り抜き・重なり順は保持します。

**Remove / 解除** always asks for confirmation because it stops that source and
discards its pixels and retained layer state. Pause and Replace do not show
this warning.

**解除** は、そのソースを停止して映像と保持中のレイヤー状態を破棄するため、
必ず確認を表示します。一時停止と選び直しではこの警告は表示しません。

When switching a completely static source from System to Laser pointer, StagePane
waits for macOS to deliver a complete cursorless frame before drawing the dot,
so it can never overlap a pointer baked into an older frame. If macOS has not
sent that frame yet, changing the slide or source content applies the new style.

完全に静止したソースを「通常」から「レーザーポインター」へ変えるときは、古い映像に焼き込まれた
カーソルと重ならないよう、macOSからカーソルなしの完全なフレームが届いてから点を
表示します。まだ届かない場合は、スライドやソース内容を変えると反映されます。

The private Workspace stays visible while the audience Curtain is on, so you can
prepare a layout before revealing it. Dragging or resizing a tile changes only
the Stage composition while **Arrange / 配置** mode is selected. **Crop / 切り抜き**
starts from the button on an individual layer, shows only that layer at full
Canvas size, and drafts the framed part sent to the Stage. The Stage does not
change until Apply Crop; Cancel discards the draft.
Its sidebar contains Canvas, Sources, Stage Settings, Appearance, Permissions,
Privacy, and About.
Toggling the Curtain does not bring the Stage window to the front.
“Keep Private” is guidance, not a technical capture boundary. Application or
full-display sharing can expose the Workspace, and a meeting app may still list
it. Select the exact **StagePane Stage — Share
This Window** window.

観客側のカーテン中も手元のWorkspaceは表示されるため、公開前に準備できます。
**配置** モードでのタイルのドラッグや大きさ変更は、Stage内の配置だけを変えます。
**切り抜き** は各レイヤーのボタンから開始し、そのレイヤーだけを手元に全面表示して、Stageへ出す範囲を下書きします。
「切り抜きを適用」を選ぶまでStageは変わらず、キャンセルすると下書きを破棄します。
Workspaceのサイドバーに、キャンバス、ソース、Stage設定、見た目と動作、アクセス権限、
プライバシー、このアプリについてをまとめています。
カーテンを切り替えてもStageウインドウは前面へ移動しません。
「共有しない」は使い方の案内であり、技術的な共有防止境界ではありません。アプリ全体や
ディスプレイ全体を共有するとWorkspaceが映る可能性があります。会議アプリでは
正確に **StagePane Stage — このウインドウを共有** を選んでください。

The Curtain hides the Stage output, but it does not stop local capture. Use
**Stop All Sources / すべてのソースを停止** when you are finished. Stop All
also deletes disconnected layers whose placement and crop were retained.

If macOS ends sharing for one source outside StagePane, StagePane immediately
removes its renderer and old frame but retains the logical layer's placement,
crop, and stacking order. The private Workspace marks that layer as needing
reselection. Choose **Select Again / 選び直す** to reconnect it through Apple's
picker; use **Remove / 解除** only when you want to delete the retained layer.

StagePaneの外側でmacOSが1件のソース共有を終了した場合、StagePaneはその映像と古いフレームを
すぐに消去しますが、レイヤーの配置、切り抜き、重なり順は保持します。手元のWorkspaceに表示される
**選び直す** からAppleのピッカーを開いて同じレイヤーへ再接続できます。保持したレイヤー自体を
削除する場合だけ **解除** を使ってください。

カーテンはステージの出力を隠しますが、ローカルの画面取得は止めません。終了時は
**すべてのソースを停止** を選んでください。すべて停止は、配置と切り抜きを保持している
再接続待ちのレイヤーも削除します。

## Workspace tools / Workspaceのツール

StagePane provides the global **Arrange / 配置** and **Draw / 手書き** modes, plus
a **Crop / 切り抜き** action owned by every layer. None of these tools sends input to source applications or needs macOS Accessibility or Input
Monitoring permission.

StagePaneではStage全体の **配置** と **手書き** モードに加え、各レイヤーに **切り抜き** 操作があります。いずれも共有元アプリへ入力を
送らず、macOSのアクセシビリティ許可や入力監視許可も必要としません。

- **Arrange / 配置** moves, resizes, and reorders Stage tiles. It never sends
  those editing gestures to a source app.
- **Crop / 切り抜き** starts from the crop button on a Canvas tile or source
  row, then displays only that layer at full Canvas size in the private
  Workspace. Drag inside the bright frame to move it or use its four
  corner handles to resize it. The Stage keeps the previously applied crop while
  you edit. Choose **Apply Crop / 切り抜きを適用** to publish the draft, or
  **Cancel / キャンセル** to discard it. Reset to Full Source changes only the
  draft until you apply it.
- **Draw / 手書き** draws bounded vector ink over the whole Stage. Choose Pen,
  translucent Highlighter, or the size-adjustable partial Eraser. Each eraser
  drag is one vector action, so **Undo / 取り消す** restores exactly what it
  removed. Draw automatically hides the audience pointer; returning to Arrange
  or opening a layer crop restores the selected pointer style. The same ink appears in the private
  Workspace and public Stage, stays only in memory, is hidden from the audience
  by the Curtain, and is cleared by **Stop All** or removal of the final source.
  Use **Undo / 取り消す** or **Clear / すべて消す** to edit it.

- **配置** はStage内のタイルを移動・サイズ変更・並べ替えします。編集ジェスチャーは
  取得元アプリへ送りません。
- **切り抜き** は選択したソース1件だけを手元用WorkspaceのCanvas全面に表示します。
  明るい枠内をドラッグして移動し、四隅のハンドルで範囲を変えます。編集中もStageは
  適用済みの範囲を保ち、**切り抜きを適用** で下書きを反映、**キャンセル** で破棄します。
  「全体表示に戻す」も適用するまでは下書きだけを変えます。
- **手書き** はStage全体に上限付きのベクター線を描きます。ペン、半透明の蛍光ペン、
  大きさを変えられる部分消去の消しゴムを選べます。消しゴムの1ドラッグは1操作として
  **取り消す** で正確に戻せます。手書き中は観客側のポインターを自動で隠し、配置または
  切り抜きへ戻ると選択中のポインター設定を復元します。線は手元のWorkspaceと共有Stageに表示され、
  メモリ内だけに保持されます。カーテン中は相手側から隠れ、**すべて停止** または最後の
  ソース解除で消去されます。**取り消す** と **すべて消す** で編集できます。

Cropping is a local composition mask, not a narrower macOS capture permission.
Whenever the source stream runs, ScreenCaptureKit handles the complete window,
app, or display approved in Apple's picker. Pause stops that stream; Remove or
Stop All ends its capture session. While paused, that layer is transparent in
the Stage, private Workspace, and Audience PNG output; Resume shows it only
after a new complete frame arrives, without changing placement, crop, or
z-order. Keep the Curtain on while
preparing content that is not ready for the audience. Crop edits remain a
private draft until Apply Crop.

切り抜きはStage内の表示マスクであり、macOSの取得許可範囲を狭めるものではありません。
ソースのストリーム動作中、ScreenCaptureKitはAppleのピッカーで許可したウインドウ、
アプリ、または画面全体を扱います。一時停止はストリームを止め、Stage、手元用Workspace、
Audience PNGでそのレイヤーを透明にします。再開後は新しい完全なフレームが届いてから再表示し、
配置・切り抜き・重なり順は保持します。解除またはすべて停止は取得セッションを終了します。
観客へ見せる準備ができていない内容を調整するときはカーテンを
有効にしてください。切り抜きの変更は「切り抜きを適用」まで手元の下書きです。

## Screenshots / スクリーンショット

Use **Copy Audience Image / Audience画像をコピー** or **Save Audience Image… /
Audience画像を保存…** in Stage Workspace only when you want a one-shot image
of the clean audience Stage. The
PNG uses the selected Stage dimensions and includes the exact audience state:
shared content or Curtain, ink, watermark, the safe-area guide when enabled, and
the pointer when visible. It does not include Workspace navigation or controls,
window title-bar chrome, or other app windows.

観客側のきれいなStageを1枚だけ画像にしたいときは、Stage Workspaceの
**Audience画像をコピー** または **Audience画像を保存…** を明示的に選びます。PNGは
選択中のStageサイズで作成され、共有内容
またはカーテン、手書き、ウォーターマーク、有効な場合はセーフエリア、表示中の場合は
ポインターを含みます。Workspaceのナビゲーションや操作UI、ウインドウのタイトルバー、
他アプリのウインドウは含みません。

Copy places that PNG on the macOS clipboard. Save writes it only to the location
you choose, and canceling the save panel writes nothing. StagePane uses the
latest pixels already granted through Apple's picker; it does not ask for a new
screen permission, take screenshots automatically, start a recording, or send
the image over the network.

コピーではPNGをmacOSのクリップボードへ置きます。保存では選んだ場所だけへ書き込み、
保存パネルをキャンセルした場合は何も保存しません。Appleの選択画面ですでに許可された
最新のピクセルを使うため、新しい画面権限は求めません。自動撮影、録画、外部送信も
行いません。

## PowerPoint Presenter View / PowerPoint の発表者ビュー

PowerPoint can [show Presenter View on a single monitor](https://support.microsoft.com/en-US/PowerPoint/training/start-the-presentation-and-see-your-notes-in-presenter-view):
start the slide show, open the controls at the lower left, and choose **Show Presenter View**. Then
choose **Add Source / ソースを追加** in StagePane and select that Presenter
View window. This captures only the window PowerPoint exposes; StagePane does
not need to create a virtual display.

PowerPoint は1台のモニタでも発表者ビューを表示できます。スライドショーを開始し、
左下のコントロールから **発表者ビューを表示** を選びます。その後StagePaneの
**ソースを追加** で、その発表者ビューのウインドウだけを選んでください。
StagePaneが仮想ディスプレイを作る必要はありません。

Keep keyboard, drag, slide-canvas navigation, and presentation-specific controls
in PowerPoint itself. StagePane does not control PowerPoint; Arrange changes
only the audience composition.

キー入力、ドラッグ、スライドキャンバスの移動、PowerPoint固有の操作はPowerPoint側で
行います。StagePaneはPowerPointを操作せず、「配置」で変わるのは相手側の構図だけです。

## Recovery / 困ったとき

- Use the StagePane menu-bar icon to recover Stage Workspace or the Share Stage.
- Press **Shift-Command-H** to toggle the Curtain.
- Press **Shift-Command-P** to add one source.
- Open **Permissions / アクセス権限** in Workspace to review the
  per-selection screen-sharing model. Add Source opens Apple's picker; no
  separate broad Screen Recording permission or settings step is required.
StagePane processes frames locally and does not upload them. When you share the
Stage, transmission is performed by your meeting app under its own privacy
policy. In the Mac App Store build, Apple StoreKit handles the optional Pro
product, purchase, entitlement, and restore flow without receiving screen content.

StagePane自身はフレームをローカル処理し、外部送信しません。ステージ共有時の送信は、
会議アプリ側の機能とプライバシーポリシーに従います。Mac App Store版の任意のPro購入と
購入状態の確認はAppleのStoreKitが処理し、画面内容は購入処理へ渡しません。

## StagePane Pro / 購入と復元

In the Mac App Store build, open **StagePane Pro** in Workspace to see the
localized one-time price. Pro removes StagePane's source-count limit and makes
the StagePane mark optional. The practical source total depends on Mac
performance and operating-system constraints. **Restore Purchases / 購入を復元**
is available on the same screen. A canceled purchase never changes or stops the
current Stage.

Mac App Store版ではWorkspaceの **StagePane Pro** で、App Storeが提供する買い切り価格を
確認できます。無料版は同時に4件まで利用でき、Proではアプリ側のソース件数制限がなくなり、
ロゴ非表示も開放します。実際に利用できる件数はMacの性能とOSの制約に依存します。同じ画面から
**購入を復元** できます。購入をキャンセルしても、現在のStageを変更・停止しません。

## Support / サポート

For support, privacy, security, Code of Conduct, or trademark inquiries, email
[support@hinoshiba.com](mailto:support@hinoshiba.com). Do not include sensitive
information in a public GitHub issue.

サポート、プライバシー、セキュリティ、行動規範、商標に関するお問い合わせは、
[support@hinoshiba.com](mailto:support@hinoshiba.com) へご連絡ください。機密情報は
GitHub の公開 Issue に記載しないでください。
