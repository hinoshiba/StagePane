# StagePane Help / StagePane の使い方

This help describes StagePane's sandboxed Arrange/Crop/Draw/Magnify workflow.

このヘルプでは、サンドボックス内で動くStagePaneの配置・切り抜き・手書き・虫眼鏡ワークフローを
説明します。

## Create and share a Stage / Stageを作って共有する

1. In **StagePane Workspace — Keep Private**, choose **Add Source / ソースを追加**.
2. In Apple's picker, choose one window, app, or display. Free supports four simultaneous sources. StagePane Pro removes StagePane's source-count limit; the number that can run in practice depends on Mac performance and operating-system constraints.
3. Keep the Canvas and its layer list together in **Workspace / ワークスペース**. Select a layer and use **Arrange / 配置** to move or resize it, its crop button to choose its framed Stage area, or **Draw / 手書き** to annotate the Stage.
4. To use a separate full-screen Space, choose **Enter Stage Full Screen** in the menu beside **Show Stage** before starting your meeting share, then press **Command-1** to return to the private Workspace.
5. In your meeting app, share only the exact **StagePane Stage** window.
6. Check the target, then choose **Open Curtain / カーテンを開く**.

1. **StagePane Workspace — 共有しない編集画面** で **ソースを追加** を選びます。
2. Appleのピッカーで、ウインドウ、アプリ、または画面を1件選びます。無料版は同時に4件まで追加できます。StagePane Proにはアプリ側の件数制限がなく、実際に利用できる件数はMacの性能とOSの制約に依存します。
3. **ワークスペース** のキャンバスとレイヤー一覧を見ながらレイヤーを選びます。**配置** で移動・サイズ変更し、切り抜きボタンでStageへ見せる枠内を選び、**手書き** でStageへ注釈を加えます。
4. 専用Spaceで使う場合は、会議での共有前に **Stageを表示** の横のメニューから **Stageをフルスクリーンにする** を選び、**Command-1** で手元用のWorkspaceへ戻ります。
5. 会議アプリでは、正確に **StagePane Stage** だけを選びます。
6. 共有対象を確認してから **カーテンを開く** を選びます。

Workspace is a private working window, but macOS does not guarantee that it is hidden from full-display or whole-application sharing. Share the exact Stage window when you want only the clean audience output.

Workspaceは手元用ですが、画面全体やアプリ全体の共有から必ず隠れるとは限りません。観客向け出力だけを見せる場合は、正確にStageウインドウを共有してください。

## Stage size and sharing quality / Stageサイズと共有画質

In windowed mode, drag the Stage's displayed content to move its titleless window.
Double-click the content to maximize the window within the current screen while
preserving its aspect ratio and leaving the menu bar and Dock available.
Double-click again to restore its previous size and position. Use the
Workspace to edit the composition. In **Stage Settings → Output Details**,
**Stage rendering size** is the Stage canvas's drawing pixel size. Audience PNG
exports use the selected Stage shape preset's dimensions instead. A small Stage
can reduce sharing quality. Choose
**Enlarge Stage for Sharing** to grow the same window toward a sharing size
that fits the current screen, keeping its shape. An already larger Stage is
not reduced. Keep the Stage large and edit using the smaller Workspace Canvas.
Your meeting app determines the resolution it captures and transmits; neither
the PNG size nor Stage rendering size guarantees the resolution received.

通常表示では、タイトルバーのないStageの表示内容をドラッグすると移動できます。
表示内容をダブルクリックすると、縦横比を保ったまま現在の画面内で最大化し、
もう一度ダブルクリックすると元の大きさと位置へ戻ります。メニューバーとDockは利用できます。
構図の編集はWorkspaceで行います。**Stage設定 → 出力の詳細** の **Stageの描画サイズ** は
Stageキャンバスの描画ピクセル数です。Audience PNGの書き出しには、選択したStageの
形状プリセットの寸法を使います。Stageが小さいと、
共有画質が低下することがあります。**共有向けにStageを拡大** を選ぶと、同じウインドウの
形を保ちながら、現在の画面に収まる共有向けサイズへ近づけます。すでに大きいStageは
縮小しません。Stageは大きく保ち、編集にはWorkspace内の小さなキャンバスを使えます。
取得・送信する解像度は会議アプリが決めます。PNGやStageの描画サイズは、相手に届く
解像度を保証するものではありません。

## Full-screen Stage / Stageのフルスクリーン

**Enter Stage Full Screen** places only Stage in its own macOS Space; Workspace
stays separate and private. The selected shape is preserved, with black margins
when the display has a different aspect ratio. Enter full screen before sharing,
press **Command-1** to return to Workspace, then share only **StagePane Stage**
in your meeting app. Use **Control-Command-F** or **Exit Stage Full Screen** in
the Stage menu to return to a regular window, even with Presentation Lock on.
Enlarge Stage for Sharing is available in windowed mode. Audience PNG keeps its
preset dimensions and clean composition without full-screen margins. Confirm
the meeting app's selected target; full screen does not guarantee transmitted
resolution or sharing continuity through a Space change.

**Stageをフルスクリーンにする** を選ぶとStageだけを専用Spaceに表示し、Workspaceは
別の手元用ウインドウに保ちます。選択した形を保ち、画面の縦横比が異なる場合は黒い余白が
入ります。共有前に切り替え、**Command-1** でWorkspaceへ戻ってから、会議アプリでは
**StagePane Stage** だけを選びます。**Control-Command-F** またはステージメニューの
**Stageのフルスクリーンを終了** で通常表示へ戻り、プレゼンテーションロック中も終了できます。
共有向けの拡大は通常表示用です。Audience PNGはプリセットのサイズを保ち、フルスクリーンの
余白を含めずに構図だけを書き出します。送信解像度やSpace切替後の共有継続は保証されないため、
会議アプリで選択した共有対象を確認してください。

## Arrange layers and manage sources / レイヤーを配置しソースを管理する

The layer list stays beside the Canvas, even at the minimum Workspace size.
Its top row is the frontmost layer. Select covered or hidden layers from this
list; selection and Canvas movement or resizing preserve their order. Only the selected
Canvas tile shows its outline and handles. The fixed tools below the Canvas offer
Crop and the selected layer's More menu. Drag a layer's grip in the list to change the stack;
higher rows are in front. The order changes when you drop, and canceling the
drag keeps the original order. Placement, crop, and the selected layer stay
unchanged. Finish Crop or close Apple's source picker before reordering.
The More menu in the layer's row or selected-layer tools retains **Move Forward**,
**Move Backward**, **Bring to Front**, and **Send to Back** as alternatives.

To move a selected rear or hidden layer, drag its private title badge or use
arrow keys. Its resize handle stays accessible above overlapping layers.
Click visible foreground content to select that layer; the selected outline's
transparent interior does not block it.

The editing outline and handles fit the visible source or applied crop,
excluding empty margins. Movement uses those visible edges, and resizing
preserves proportions with the upper-left corner fixed. Empty margins let you
select content underneath. Keyboard and VoiceOver use the same bounds; hidden
layers retain their last bounds.

レイヤー一覧は、最小サイズでもキャンバスの横に表示され、最前面のレイヤーが上に並びます。
重なって見えないレイヤーや非表示のレイヤーも一覧から選べます。選択と、キャンバス上の移動・サイズ変更では
重なり順は変わらず、編集枠とハンドルは選択中のタイルだけに表示します。
切り抜きと選択レイヤーのその他メニューはキャンバス下の固定ツールに表示します。一覧のつまみを
ドラッグすると、上のレイヤーほど手前になるよう重なり順を変更できます。ドロップで
順序を確定し、キャンセルすれば元の順序を保ちます。配置・切り抜きと現在の選択は
変わりません。切り抜き編集中やAppleのソース選択画面を表示している間は、それを
終えてから並べ替えてください。レイヤー行や選択レイヤー用ツールのその他メニューにある
**ひとつ前面へ**・**ひとつ背面へ**・**最前面へ**・**最背面へ** も引き続き使えます。

背面や非表示のレイヤーを移動するときは、一覧で選んでから手元のタイトル表示をドラッグするか、
矢印キーを使います。サイズ変更ハンドルは重なりの上から操作できます。前面の映像を
クリックすればそのレイヤーを選べ、選択枠の透明な内側はクリックを遮りません。

編集枠とハンドルは余白を除いた映像や適用済みの切り抜き範囲に沿い、見えている端を
基準に移動できます。サイズ変更では左上の位置と縦横比を保ちます。余白の部分からは
下のレイヤーを選べます。キーボードやVoiceOverでも同じ範囲を操作でき、非表示中は
最後の範囲を保ちます。

- **Hide / 非表示** pauses that source's stream and makes its layer transparent in the Stage, private Workspace, and Audience PNG output while preserving placement, crop, and z-order. Its row remains in the list.
- **Show / 再表示** resumes it and reveals the layer only after a new complete frame arrives.
- **Replace / 選び直す** opens Apple's picker for that source.
- If macOS ends a source's sharing session, its layer remains without the old frame. **Select Again** reconnects that same layer while preserving its placement and crop; only Remove deletes them.
- **Crop / 切り抜く** in the selected-layer tools below the Canvas or the layer's More menu opens that layer alone at full Canvas size with an adjustable crop draft. The Stage changes only when you choose Apply Crop; Cancel discards it.
- **Remove / 解除** asks for confirmation, then ends and removes that source.
- **Stop All / すべて停止** ends every source and removes every retained layer.
- **Reset Capture / 画面取得をリセット** appears only for an inactive error that has no retained layer. A disconnected layer uses its own **Select Again** action instead.

- **非表示** はそのソースの取得を一時停止し、配置・切り抜き・重なり順を保持したまま、Stage・手元用Workspace・Audience PNGでレイヤーを透明にします。一覧の行は残ります。
- **再表示** は取得を再開し、新しい完全なフレームが届いた時点でレイヤーを再表示します。
- **選び直す** はそのソース用のAppleピッカーを開きます。
- macOS側でソースの共有が終了しても、古い映像を消したうえでレイヤー自体は残ります。**選び直す** と配置と切り抜きを保った同じレイヤーへ再接続し、**解除** を選んだ場合だけ削除します。
- キャンバス下の選択レイヤー用ツールや各レイヤーのその他メニューから **切り抜く** を選ぶと、そのレイヤーだけを手元用Canvasへ全面表示し、切り抜き枠を下書きします。「切り抜きを適用」でStageへ反映し、キャンセルすると破棄します。
- **解除** は確認後にそのソースの取得を終了し、一覧から削除します。
- **すべて停止** は全ソースの取得を終了し、保持中のレイヤーもすべて削除します。
- **画面取得をリセット** は、保持中のレイヤーがない停止済みエラーの場合だけ表示されます。共有が終了したレイヤーは、そのレイヤーの **選び直す** を使います。

An app selection can include all windows owned by that app. Choose one window when you need the narrowest source.

アプリを選ぶと、そのアプリの複数ウインドウが含まれる場合があります。範囲を限定したい場合は、1つのウインドウを選んでください。

Applying a crop changes only what appears on the Stage and in an Audience PNG. Whenever its stream runs, ScreenCaptureKit handles the complete source selected in macOS. Hide pauses that stream and makes its layer transparent everywhere StagePane presents or exports it; Show resumes it and waits for a new complete frame before showing it again. Placement, crop, and z-order remain unchanged. Remove or Stop All ends its capture session and deletes its retained layer state. Crop edits remain a private draft until Apply Crop. The complete selected source is visible in the private Workspace while Crop is active, so keep that Workspace private.

切り抜きを適用して変わるのはStageとAudience PNGに表示する範囲だけです。ストリームの動作中、ScreenCaptureKitはmacOSで選択したソース全体を扱います。非表示はストリームを一時停止し、StagePane内の表示とAudience PNGでそのレイヤーを透明にします。再表示を選ぶと取得を再開しますが、新しい完全なフレームが届くまでは透明のままで、配置・切り抜き・重なり順は変わりません。解除またはすべて停止は取得セッションを終了し、保持しているレイヤー状態を削除します。切り抜きの変更は適用まで手元の下書きで、編集中は選択したソース全体をWorkspaceに表示するため、そのWorkspaceは共有しないでください。

## Audience tools / 観客向けツール

- **Curtain / カーテン** instantly covers the audience Stage with your chosen message.
  In **Stage Settings → Curtain**, use the size stepper to make the message smaller
  or larger. Changes apply immediately and the size is saved for next time.
- **Draw / 手書き** provides Pen, translucent Highlighter, and a size-adjustable
  partial Eraser. Draw automatically hides the audience pointer; returning to
  Arrange or opening a layer crop restores the selected pointer style. Ink and
  erase actions stay in memory; Undo restores erased areas.
- **Magnify / 虫眼鏡**, beside Arrange and Draw, follows the cursor over the
  private Canvas with a circular lens in both the preview and shared Stage.
  Choose **2×**, **3×**, or **4×** magnification; layout and crop stay unchanged.
  The lens disappears when the cursor leaves the Canvas, and arrow keys move
  it when the Canvas has focus. Press **Escape** or choose **Exit Magnify /
  虫眼鏡を終了** to return to Arrange and restore your pointer preference.
  Magnify hides the audience pointer while active; the Curtain hides the
  audience lens.
- **Laser pointer / レーザーポインター** can be customized in Stage Settings.
- The StagePane mark is shown in Free and can be turned off with StagePane Pro.
- **Copy Audience Image** places one Stage PNG on the pasteboard.
- **Save Audience Image…** writes one Stage PNG only to the location you choose.

- **カーテン** は指定した文言で観客向けStageをすぐに覆います。
  **Stage設定 → カーテン** の文字サイズステッパーで文字を小さく・大きくできます。
  変更はすぐに反映され、文字の大きさは次回起動時も維持されます。
- **手書き** ではペン、半透明の蛍光ペン、大きさを変えられる部分消去の消しゴムを使えます。
  手書き中は観客側のポインターを自動で隠し、配置へ戻るかレイヤーの切り抜きを開くと選択中の設定を復元します。
  インクと消去操作はメモリ内だけに保持され、取り消すと消した部分も元に戻ります。
- **虫眼鏡** は配置・手書きの隣から選べます。手元のキャンバス上でカーソルを動かすと、
  プレビューと共有Stageの両方に円形レンズを表示します。倍率は **2×**・**3×**・**4×** から選べ、
  配置と切り抜きは変わりません。カーソルをキャンバスの外へ移すとレンズは消えます。
  キャンバスにフォーカスがある間は矢印キーでも動かせます。**Escape** または **虫眼鏡を終了** で
  配置へ戻り、選択中のポインター設定を復元します。虫眼鏡中は観客側のポインターを自動で隠し、
  カーテン中は観客側のレンズも隠します。
- **レーザーポインター** はStage設定で色、大きさ、発光を調整できます。
- StagePaneロゴは無料版で表示され、StagePane ProではStage設定から無効にできます。
- **Audience画像をコピー** はStageのPNGをペーストボードへ置きます。
- **Audience画像を保存…** は選んだ場所だけへStageのPNGを1枚書き込みます。

Screenshots use the preset's Audience PNG dimensions regardless of the Stage
window size and contain the clean audience composition, not Workspace
navigation or controls. StagePane does not record video and never saves images automatically.
The StagePane menu-bar icon also provides copy and save actions under **Stage Image**.

スクリーンショットはStageウインドウの大きさにかかわらず、プリセットのAudience PNGサイズで
作成します。観客向けの合成結果だけが入り、Workspaceのナビゲーションや操作UIは入りません。
動画は録画せず、画像を自動保存することもありません。
メニューバーのStagePaneアイコンにある **Stage画像** からもコピー・保存できます。

## Access and privacy / アクセスとプライバシー

**Settings** (Command-comma) has **General** and **About**. About includes a privacy
summary and expandable **Privacy and Data** details; **About StagePane** in the
app menu opens the same page. **About Screen Sharing** in About or the Stage menu
opens a separate guide.
Workspace and Settings automatically follow macOS Light or Dark appearance,
independently of the audience Stage theme. No separate app appearance setting is needed.

**設定**（⌘,）は **一般** と **このアプリについて** の2項目です。
**このアプリについて** にプライバシーの要約と展開式の **プライバシーとデータ** をまとめ、
アプリメニューの **StagePaneについて** からも同じ画面を開けます。
**このアプリについて** やステージメニューの **画面共有について** は、別の案内ウインドウを開きます。
Workspaceと設定画面はmacOSのライト／ダークの外観に自動で追従します。観客向けStageの
テーマとは独立しており、アプリ内で外観を設定する必要はありません。

Each source is approved in Apple's content-sharing picker for that capture session.
Canceling the picker grants no new access. StagePane does not request separate broad
Screen Recording access or show a permission warning at launch.

各ソースはAppleの共有ピッカーで取得セッションごとに承認されます。キャンセルした場合は
新しい取得を始めません。別途広範な画面収録許可は要求せず、起動時の権限警告も表示しません。

Arrange, Crop, Draw, and Magnify stay inside StagePane. StagePane does not forward clicks, keys, or drags to source applications, and it never requests Accessibility or Input Monitoring permission.

配置、切り抜き、手書き、虫眼鏡はStagePane内だけで動作します。StagePaneは共有元アプリへクリック、キー入力、ドラッグを転送せず、アクセシビリティや入力監視の許可も要求しません。

StagePane has no account, advertising, analytics, microphone/audio capture, publisher server, or screen upload. Apple StoreKit handles the optional Pro product, purchase, entitlement, and restore flow. See the bundled Privacy Policy for the complete data-flow description.

StagePaneには、アカウント、広告、解析、マイク・音声取得、発行者サーバー、画面内容の送信はありません。任意のPro商品・購入・購入状態・復元はAppleのStoreKitが処理します。完全なデータフローは同梱のプライバシーポリシーで確認できます。

## StagePane Pro / 購入と復元

Open **StagePane Pro** from Settings or the StagePane menu to see the App Store's localized one-time price. Pro removes StagePane's source-count limit and makes the StagePane mark optional on the Stage, Curtain, and Audience PNG. The practical source total depends on Mac performance and operating-system constraints. Use **Restore Purchases** on the same screen for a previous purchase. Canceling never changes or stops the current Stage.

設定またはStagePaneメニューの **StagePane Pro** で、App Storeが提供する買い切り価格を確認できます。無料版は同時に4件まで利用でき、Proではアプリ側のソース件数制限がなくなり、Stage、カーテン、Audience PNGのロゴを任意にできます。実際に利用できる件数はMacの性能とOSの制約に依存します。同じ画面の **購入を復元** から以前の購入を復元できます。キャンセルしても現在のStageを変更・停止しません。

## If something is wrong / 問題がある場合

- Make sure you shared **StagePane Stage**, not Workspace.
- If selection was canceled, choose **Add Source** again.
- If source selection or capture cannot start, read the separate message window;
  the editor remains usable. Canceling selection does not show this message.
  Hide and Stop failures remain in the layer and capture status.
- If a source stops, use **Select Again** on that retained layer. Its placement and crop remain in place.
- If a saved PNG cannot be written, choose another location in the macOS save panel.
- Keep the Curtain on while you prepare or recover a source.

- 会議アプリでWorkspaceではなく **StagePane Stage** を共有したことを確認します。
- 選択をキャンセルした場合は、もう一度 **ソースを追加** を選びます。
- ソースの選択画面や取得を開始できない場合は、別ウインドウの短い説明を確認します。
  編集は引き続き操作でき、選択のキャンセルではこの案内を表示しません。
  非表示や停止の失敗は、レイヤーと画面取得の状態表示で確認できます。
- ソースが停止した場合は、保持されたレイヤーの **選び直す** を使います。配置と切り抜きはそのまま残ります。
- PNGを保存できない場合は、macOSの保存パネルで別の場所を選びます。
- 準備や復旧中はカーテンを有効にします。

Support: [support@hinoshiba.com](mailto:support@hinoshiba.com)
