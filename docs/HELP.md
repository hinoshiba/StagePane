# StagePane Help / StagePane の使い方

## Share safely / 安全に共有する

1. Keep **StagePane Workspace — Keep Private** and **StagePane Control Room —
   Keep Private** on your Mac.<br>
   **StagePane Workspace — 共有しない編集画面** と **StagePane Control Room —
   共有しない操作画面** は手元に置きます。
2. Choose **Add Source / ソースを追加** and approve one window, app, or
   display in the macOS system picker. Repeat to add up to four sources.
3. Open the large private Stage Workspace to arrange, control where available,
   or draw. Drag and resize sources there. Use **Pause / 一時停止**, **Resume /
   再開**, **Replace / 選び直す**, or **Remove / 解除** in Control Room's
   source list for one item, or **Auto Arrange / 自動配置** for an even grid.
4. In your meeting app, share **StagePane Stage — Share This Window / このウインドウを共有**.
5. Confirm the correct share target, then choose **Reveal Stage / カーテンを開く**.

Selecting an app can include every window owned by that app. Select a single
window when you want to limit the source more narrowly.

アプリを選ぶと、そのアプリが持つすべてのウインドウが含まれる場合があります。
共有範囲を狭くしたい場合は、アプリではなく1つのウインドウを選んでください。

## Permissions / アクセス権限

Control Room's persistent **Permissions / アクセス権限** view explains every
access path StagePane can use. Screen sharing is approved one selection at a
time in Apple's `SCContentSharingPicker`: choosing a window, app, or display
authorizes only that content for its capture session. StagePane does not request
separate, broad Screen Recording access, and canceling the picker grants no
source access.

Control Roomの常設 **アクセス権限** 画面では、StagePaneが利用できるアクセス経路を
確認できます。画面共有はAppleの `SCContentSharingPicker` で1件ずつ承認され、選んだ
ウインドウ、アプリ、または画面だけが、その取得セッション中に許可されます。別途、
広範な画面収録許可を求めることはなく、ピッカーをキャンセルした場合はソースへの
アクセスも始まりません。

In the unsandboxed local development build on macOS 15.2 or later, this view
also contains a separate **Accessibility** card for Control mode. Selecting
Control can take you to that card, but it does not itself open the macOS consent
UI. Only choosing **Continue Setup / 設定を続ける** in the card requests
Accessibility access. The Mac App Store build hides the entire Accessibility
card and never requests that access.

macOS 15.2以降の非サンドボックスのローカル開発ビルドでは、この画面に操作モード用の
**アクセシビリティ** カードも表示されます。「操作」を選ぶとカードへ移動できますが、
その時点ではmacOSの確認画面を開きません。カード内の **設定を続ける** を明示的に選んだ場合
だけ、アクセシビリティ許可を求めます。Mac App Store版ではカード自体を表示せず、
この許可も求めません。

In **Appearance / 見た目と動作**, set **Pointer appearance / カーソルの表示方法**
to **System / 通常**, **Laser pointer / レーザーポインター**, or **Hidden /
非表示**. The laser pointer's color, size, and glow are adjustable. Its dot is
drawn only over the frontmost Stage source; it does not replace the pointer you
see locally. If the frontmost source is paused, no dot is shown—StagePane does
not fall back to a source behind it.

「レーザーポインター」は色・サイズ・発光を調整できます。点はStage上の最前面ソース
にだけ表示され、手元で見ているmacOSのカーソルは置き換えません。最前面ソースが
一時停止中なら点は表示せず、背面のソースへは切り替えません。

The translucent **StagePane mark / StagePaneロゴ** is enabled by default in the
lower-right of the holding screen, shared content, and Curtain, and is mirrored
in the private Workspace. It can be disabled in Appearance.

半透明の **StagePaneロゴ** は初期状態で有効になり、待機画面、共有内容、カーテンの右下に
表示され、手元のWorkspaceにも反映されます。見た目と動作から無効にできます。

**Pause / 一時停止** stops only that source's ScreenCaptureKit stream and
keeps its last frame visible in both the Stage and private Workspace. **Resume /
再開** restarts the same source. Use **Remove / 解除** or **Stop All / すべて停止**
to discard the retained frame.

**一時停止** はそのソースのScreenCaptureKitストリームだけを停止し、最後のフレームを
Stageと手元のWorkspaceに保持します。**再開** で同じソースの取得を再開します。保持した
フレームも破棄する場合は **解除** または **すべて停止** を使ってください。

**Remove / 解除** always asks for confirmation because it stops that source and
discards its last frame and layout. Pause and Replace do not show this warning.

**解除** は、そのソースを停止して最後のフレームと配置を破棄するため、
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
the Stage composition while **Arrange / 配置** mode is selected. Control Room
contains sources, status, and settings, but no live editor.
Toggling the Curtain does not bring the Stage window to the front.
“Keep Private” is guidance, not a technical capture boundary. Application or
full-display sharing can expose the Workspace and Control Room, and a meeting
app may still list either window. Select the exact **StagePane Stage — Share
This Window** window.

観客側のカーテン中も手元のWorkspaceは表示されるため、公開前に準備できます。
**配置** モードでのタイルのドラッグや大きさ変更は、Stage内の配置だけを変えます。
Control Roomにはソース、状態、設定を表示し、ライブ編集画面は置きません。
カーテンを切り替えてもStageウインドウは前面へ移動しません。
「共有しない」は使い方の案内であり、技術的な共有防止境界ではありません。アプリ全体や
ディスプレイ全体を共有するとWorkspaceやControl Roomが映る可能性があります。会議アプリでは
正確に **StagePane Stage — このウインドウを共有** を選んでください。

The Curtain hides the Stage output, but it does not stop local capture. Use
**Stop All Sources / すべてのソースを停止** when you are finished.

カーテンはステージの出力を隠しますが、ローカルの画面取得は止めません。終了時は
**すべてのソースを停止** を選んでください。

## Workspace modes / Workspaceのモード

The Mac App Store build provides **Arrange / 配置** and **Draw / 手書き**. It
does not include Control mode and never asks for macOS Accessibility or Input
Monitoring permission. The unsandboxed local development build can additionally
show **Control / 操作** on macOS 15.2 or later.

Mac App Store版で利用できるのは **配置** と **手書き** です。**操作** モードは含まれず、
macOSのアクセシビリティ許可や入力監視許可も求めません。macOS 15.2以降の
非サンドボックスのローカル開発ビルドでは、追加で **操作** を表示できます。

- **Arrange / 配置** moves, resizes, and reorders Stage tiles. It never sends
  those editing gestures to a source app.
- **Control / 操作** (unsandboxed local development build only) uses the
  separate Accessibility access requested only when you choose **Continue Setup**
  in Permissions. Selecting a point in a source added as exactly one
  window performs the supported Press action only when the point maps to a
  pressable accessibility control in that same selected window. StagePane does
  not synthesize arbitrary mouse clicks, move the physical pointer, or
  activate/focus the source app. Application/display sources, black padding,
  paused/stale/ambiguous frames, generic canvas or content regions, keyboard
  input, and drag forwarding are not supported.
- **Draw / 手書き** draws bounded vector ink over the whole Stage. The same ink
  appears in the private Workspace and public Stage, stays only in memory, is
  hidden from the audience by the Curtain, and is cleared by **Stop All** or
  removal of the final source. Use **Undo / 取り消す** or **Clear / すべて消す**
  to edit it.

- **配置** はStage内のタイルを移動・サイズ変更・並べ替えします。編集ジェスチャーは
  取得元アプリへ送りません。
- **操作**（非サンドボックスのローカル開発ビルドのみ）は、**アクセス権限** 画面で
  **設定を続ける** を選んだ場合だけ求める、個別のアクセシビリティ許可を使います。
  「1つのウインドウ」として追加したソース内で、
  同じ選択済みウインドウに属する
  押下対応のアクセシビリティコントロールを選んだ場合だけ、その押下（Press）操作を実行します。
  任意のマウスクリックは合成せず、物理カーソルを動かしたり取得元アプリを前面化・
  フォーカスしたりしません。アプリ／ディスプレイソース、黒帯、一時停止中・古い・曖昧な
  フレーム、一般的なキャンバスや内容領域、キー入力、ドラッグ転送には対応しません。
- **手書き** はStage全体に上限付きのベクター線を描きます。線は手元のWorkspaceと共有Stageに
  表示され、メモリ内だけに保持されます。カーテン中は相手側から隠れ、**すべて停止** または
  最後のソース解除で消去されます。**取り消す** と **すべて消す** で編集できます。

## Screenshots / スクリーンショット

Use **Copy Audience Image / Audience画像をコピー** or **Save Audience Image… /
Audience画像を保存…** in Stage Workspace only when you want a one-shot image
of the clean audience Stage. The
PNG uses the selected Stage dimensions and includes the exact audience state:
shared content or Curtain, ink, watermark, safe-area guide, and pointer. It does
not include the Workspace toolbar, Control Room, window title bar, or other app
windows.

観客側のきれいなStageを1枚だけ画像にしたいときは、Stage Workspaceの
**Audience画像をコピー** または **Audience画像を保存…** を明示的に選びます。PNGは
選択中のStageサイズで作成され、共有内容
またはカーテン、手書き、ウォーターマーク、セーフエリア、ポインターを含みます。
Workspaceのツールバー、Control Room、ウインドウのタイトルバー、他アプリのウインドウは
含みません。

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
in PowerPoint itself. The Mac App Store build does not control PowerPoint; its
Arrange mode changes only the audience composition. On macOS 15.2 or later, an
unsandboxed local development build can invoke only the supported Press action
of a pressable accessibility control in the exact Presenter View window.

キー入力、ドラッグ、スライドキャンバスの移動、PowerPoint固有の操作はPowerPoint側で
行います。Mac App Store版はPowerPointを操作せず、「配置」で変わるのは相手側の構図だけです。
macOS 15.2以降の非サンドボックスのローカル開発ビルドでは、「操作」モードから、
単一の発表者ビューウインドウ内で押下（Press）操作に対応するアクセシビリティコントロール
だけを実行できます。

## Recovery / 困ったとき

- Use the StagePane menu-bar icon to recover Control Room, Stage Workspace, or
  the Share Stage.
- Press **Shift-Command-H** to toggle the Curtain.
- Press **Shift-Command-P** to add one source.
- Open **Permissions / アクセス権限** in Control Room to review the
  per-selection screen-sharing model. Add Source opens Apple's picker; no
  separate broad Screen Recording permission or settings step is required.
- In the unsandboxed local development Control build only, use the Accessibility
  card's **Continue Setup / 設定を続ける** action to request access once. If a
  rebuilt app is still shown as On in System Settings but StagePane reports the
  current build as not allowed, follow the numbered instructions in the card,
  choose **Open Accessibility Settings / アクセシビリティ設定を開く**, remove
  a stale StagePane row with “−” if one exists, and add the exact running app
  shown in the card with “+”. Existing ad-hoc installations migrate directly to this repair
  state instead of presenting one more consent request. The default ad-hoc
  development build has a new macOS identity after each binary update.
  Developers doing repeated permission testing can instead rebuild with the same caller-managed
  `STAGEPANE_LOCAL_SIGNING_IDENTITY`. The Mac App Store build hides this card.

- 非サンドボックスのローカル開発版だけ、アクセシビリティカードの **設定を続ける**
  から許可を一度要求します。システム設定ではStagePaneがONなのに、アプリが
  **現在のビルドは未許可** と表示する場合は、カード内の番号付き手順に従って
  **アクセシビリティ設定を開く** を選び、古いStagePane行がある場合は「−」で削除し、
  「＋」でカードに表示された実行中のアプリを追加してください。既存のad-hoc版からは、
  同じ確認をもう一度出さず、この再登録状態へ移行します。
  デフォルトのad-hoc開発ビルドはバイナリ更新ごとにmacOS上の識別が変わります。
  許可を繰り返し検証する開発者は、呼び出し元で管理する同じ
  `STAGEPANE_LOCAL_SIGNING_IDENTITY` を指定してビルドできます。Mac App Store版は
  このカードを表示しません。

StagePane processes frames locally and does not upload them. When you share the
Stage, transmission is performed by your meeting app under its own privacy
policy.

StagePane自身はフレームをローカル処理し、外部送信しません。ステージ共有時の送信は、
会議アプリ側の機能とプライバシーポリシーに従います。

## Support / サポート

For support, privacy, security, Code of Conduct, or trademark inquiries, email
[support@hinoshiba.com](mailto:support@hinoshiba.com). Do not include sensitive
information in a public GitHub issue.

サポート、プライバシー、セキュリティ、行動規範、商標に関するお問い合わせは、
[support@hinoshiba.com](mailto:support@hinoshiba.com) へご連絡ください。機密情報は
GitHub の公開 Issue に記載しないでください。
