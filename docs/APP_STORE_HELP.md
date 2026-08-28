# StagePane Help / StagePane の使い方

This help describes StagePane's sandboxed Arrange/Crop/Draw workflow.

このヘルプでは、サンドボックス内で動くStagePaneの配置・切り抜き・手書きワークフローを
説明します。

## Create and share a Stage / Stageを作って共有する

1. In **StagePane Workspace — Keep Private**, choose **Add Source / ソースを追加**.
2. In Apple's picker, choose one window, app, or display. Free supports two simultaneous sources; StagePane Pro supports up to four.
3. Use **Arrange / 配置** to move and resize sources, **Crop / 切り抜き** to choose the framed part shown on Stage, or **Draw / 手書き** to annotate it.
4. In your meeting app, share the exact window named **StagePane Stage — Share This Window / このウインドウを共有**.
5. Check the target, then choose **Reveal Stage / カーテンを開く**.

1. **StagePane Workspace — 共有しない編集画面** で **ソースを追加** を選びます。
2. Appleのピッカーで、ウインドウ、アプリ、または画面を1件選びます。無料版は同時に2件、StagePane Proは最大4件まで追加できます。
3. **配置** で移動・サイズ変更し、**切り抜き** でStageへ見せる枠内を選び、**手書き** で注釈を加えます。
4. 会議アプリでは、正確に **StagePane Stage — このウインドウを共有** を選びます。
5. 共有対象を確認してから **カーテンを開く** を選びます。

Workspace is a private working window, but macOS does not guarantee that it is hidden from full-display or whole-application sharing. Share the exact Stage window when you want only the clean audience output.

Workspaceは手元用ですが、画面全体やアプリ全体の共有から必ず隠れるとは限りません。観客向け出力だけを見せる場合は、正確にStageウインドウを共有してください。

## Manage sources / ソースを管理する

- **Pause / 一時停止** holds the latest displayed frame and stops that source's stream.
- **Resume / 再開** restarts it.
- **Replace / 選び直す** opens Apple's picker for that source.
- **Crop / 切り抜く** opens the selected source alone at full Canvas size with an adjustable crop draft. The Stage changes only when you choose Apply Crop; Cancel discards it.
- **Remove / 解除** asks for confirmation, then ends and removes that source.
- **Stop All / すべて停止** ends every source.
- **Reset Capture / 画面取得をリセット** clears an inactive error state so selection can start again.

- **一時停止** は最後に表示したフレームを保ち、そのソースの取得を停めます。
- **再開** は取得を再開します。
- **選び直す** はそのソース用のAppleピッカーを開きます。
- **切り抜く** は選択したソース1件だけを手元用Canvasへ全面表示し、切り抜き枠を下書きします。「切り抜きを適用」でStageへ反映し、キャンセルすると破棄します。
- **解除** は確認後にそのソースの取得を終了し、一覧から削除します。
- **すべて停止** は全ソースの取得を終了します。
- **画面取得をリセット** はエラー状態を解除し、再度選択できる状態に戻します。

An app selection can include all windows owned by that app. Choose one window when you need the narrowest source.

アプリを選ぶと、そのアプリの複数ウインドウが含まれる場合があります。範囲を限定したい場合は、1つのウインドウを選んでください。

Applying a crop changes only what appears on the Stage and in an Audience PNG. Whenever its stream runs, ScreenCaptureKit handles the complete source selected in macOS. Pause stops that stream; Remove or Stop All ends its capture session. Crop edits remain a private draft until Apply Crop. The complete selected source is visible in the private Workspace while Crop is active, so keep that Workspace private.

切り抜きを適用して変わるのはStageとAudience PNGに表示する範囲だけです。ストリームの動作中、ScreenCaptureKitはmacOSで選択したソース全体を扱います。一時停止はストリームを止め、解除またはすべて停止は取得セッションを終了します。切り抜きの変更は適用まで手元の下書きで、編集中は選択したソース全体をWorkspaceに表示するため、そのWorkspaceは共有しないでください。

## Audience tools / 観客向けツール

- **Curtain / カーテン** instantly covers the audience Stage with your chosen message.
- **Draw / 手書き** provides Pen, translucent Highlighter, and a size-adjustable
  partial Eraser. Draw automatically hides the audience pointer and returning
  to Arrange or Crop restores the selected pointer style. Ink and erase actions stay in
  memory; Undo restores erased areas.
- **Laser pointer / レーザーポインター** can be customized in Appearance.
- The StagePane mark is shown in Free and can be turned off with StagePane Pro.
- **Copy Audience Image** places one Stage PNG on the pasteboard.
- **Save Audience Image…** writes one Stage PNG only to the location you choose.

- **カーテン** は指定した文言で観客向けStageをすぐに覆います。
- **手書き** ではペン、半透明の蛍光ペン、大きさを変えられる部分消去の消しゴムを使えます。
  手書き中は観客側のポインターを自動で隠し、配置または切り抜きへ戻ると選択中の設定を復元します。
  インクと消去操作はメモリ内だけに保持され、取り消すと消した部分も元に戻ります。
- **レーザーポインター** は外観設定で色、大きさ、発光を調整できます。
- StagePaneロゴは無料版で表示され、StagePane Proでは外観設定から無効にできます。
- **Audience画像をコピー** はStageのPNGをペーストボードへ置きます。
- **Audience画像を保存…** は選んだ場所だけへStageのPNGを1枚書き込みます。

Screenshots contain the clean audience composition, not Workspace navigation or controls. StagePane does not record video and never saves images automatically.

スクリーンショットには観客向けの合成結果だけが入り、Workspaceのナビゲーションや操作UIは入りません。動画は録画せず、画像を自動保存することもありません。

## Access and privacy / アクセスとプライバシー

Each source is approved in Apple's content-sharing picker for that capture session. Canceling the picker grants nothing.

各ソースはAppleの共有ピッカーで取得セッションごとに承認されます。キャンセルした場合は取得を始めません。

Arrange, Crop, and Draw stay inside StagePane. StagePane does not forward clicks, keys, or drags to source applications, and it never requests Accessibility or Input Monitoring permission.

配置、切り抜き、手書きはStagePane内だけで動作します。StagePaneは共有元アプリへクリック、キー入力、ドラッグを転送せず、アクセシビリティや入力監視の許可も要求しません。

StagePane has no account, advertising, analytics, microphone/audio capture, publisher server, or screen upload. Apple StoreKit handles the optional Pro product, purchase, entitlement, and restore flow. See the bundled Privacy Policy for the complete data-flow description.

StagePaneには、アカウント、広告、解析、マイク・音声取得、発行者サーバー、画面内容の送信はありません。任意のPro商品・購入・購入状態・復元はAppleのStoreKitが処理します。完全なデータフローは同梱のプライバシーポリシーで確認できます。

## StagePane Pro / 購入と復元

Open **StagePane Pro** in Workspace to see the App Store's localized one-time price. Pro unlocks source three and four and makes the StagePane mark optional on the Stage, Curtain, and Audience PNG. Use **Restore Purchases** on the same screen for a previous purchase. Canceling never changes or stops the current Stage.

Workspaceの **StagePane Pro** で、App Storeが提供する買い切り価格を確認できます。Proは3・4件目のソースを開放し、Stage、カーテン、Audience PNGのロゴを任意にします。同じ画面の **購入を復元** から以前の購入を復元できます。キャンセルしても現在のStageを変更・停止しません。

## If something is wrong / 問題がある場合

- Make sure you shared **StagePane Stage**, not Workspace.
- If selection was canceled, choose **Add Source** again.
- If a source stops, remove it or use **Reset Capture**, then add it again.
- If a saved PNG cannot be written, choose another location in the macOS save panel.
- Keep the Curtain on while you prepare or recover a source.

- 会議アプリでWorkspaceではなく **StagePane Stage** を共有したことを確認します。
- 選択をキャンセルした場合は、もう一度 **ソースを追加** を選びます。
- ソースが停止した場合は、解除するか **画面取得をリセット** してから再度追加します。
- PNGを保存できない場合は、macOSの保存パネルで別の場所を選びます。
- 準備や復旧中はカーテンを有効にします。

Support: [support@hinoshiba.com](mailto:support@hinoshiba.com)
