# StagePane Help / StagePane の使い方

This help describes the sandboxed Mac App Store edition of StagePane.

このヘルプは、サンドボックス化されたMac App Store版StagePaneについて説明します。

## Create and share a Stage / Stageを作って共有する

1. In **StagePane Workspace — Keep Private**, choose **Add Source / ソースを追加**.
2. In Apple's picker, choose one window, app, or display. Repeat to add up to four sources.
3. Use **Arrange / 配置** to move and resize sources, or **Draw / 手書き** to annotate the Stage.
4. In your meeting app, share the exact window named **StagePane Stage — Share This Window / このウインドウを共有**.
5. Check the target, then choose **Reveal Stage / カーテンを開く**.

1. **StagePane Workspace — 共有しない編集画面** で **ソースを追加** を選びます。
2. Appleのピッカーで、ウインドウ、アプリ、または画面を1件選びます。最大4件まで繰り返せます。
3. **配置** で移動・サイズ変更し、**手書き** でStageへ注釈を加えます。
4. 会議アプリでは、正確に **StagePane Stage — このウインドウを共有** を選びます。
5. 共有対象を確認してから **カーテンを開く** を選びます。

Workspace and Control Room are private working windows, but macOS does not guarantee that they are hidden from full-display or whole-application sharing. Share the exact Stage window when you want only the clean audience output.

WorkspaceとControl Roomは手元用ですが、画面全体やアプリ全体の共有から必ず隠れるとは限りません。観客向け出力だけを見せる場合は、正確にStageウインドウを共有してください。

## Manage sources / ソースを管理する

- **Pause / 一時停止** holds the latest displayed frame and stops that source's stream.
- **Resume / 再開** restarts it.
- **Replace / 選び直す** opens Apple's picker for that source.
- **Remove / 解除** asks for confirmation, then ends and removes that source.
- **Stop All / すべて停止** ends every source.
- **Reset Capture / 画面取得をリセット** clears an inactive error state so selection can start again.

- **一時停止** は最後に表示したフレームを保ち、そのソースの取得を停めます。
- **再開** は取得を再開します。
- **選び直す** はそのソース用のAppleピッカーを開きます。
- **解除** は確認後にそのソースの取得を終了し、一覧から削除します。
- **すべて停止** は全ソースの取得を終了します。
- **画面取得をリセット** はエラー状態を解除し、再度選択できる状態に戻します。

An app selection can include all windows owned by that app. Choose one window when you need the narrowest source.

アプリを選ぶと、そのアプリの複数ウインドウが含まれる場合があります。範囲を限定したい場合は、1つのウインドウを選んでください。

## Audience tools / 観客向けツール

- **Curtain / カーテン** instantly covers the audience Stage with your chosen message.
- **Draw / 手書き** places in-memory ink over the Stage. Undo or clear it from Workspace.
- **Laser pointer / レーザーポインター** can be customized in Appearance.
- The optional StagePane watermark is enabled by default and can be turned off.
- **Copy Audience Image** places one Stage PNG on the pasteboard.
- **Save Audience Image…** writes one Stage PNG only to the location you choose.

- **カーテン** は指定した文言で観客向けStageをすぐに覆います。
- **手書き** はメモリ内のインクをStageに重ねます。Workspaceから取り消し・全消去できます。
- **レーザーポインター** は外観設定で色、大きさ、発光を調整できます。
- StagePaneロゴはデフォルトで有効で、外観設定から無効にできます。
- **Audience画像をコピー** はStageのPNGをペーストボードへ置きます。
- **Audience画像を保存…** は選んだ場所だけへStageのPNGを1枚書き込みます。

Screenshots contain the clean audience composition, not Workspace or Control Room controls. StagePane does not record video and never saves images automatically.

スクリーンショットには観客向けの合成結果だけが入り、WorkspaceやControl Roomの操作UIは入りません。動画は録画せず、画像を自動保存することもありません。

## Access and privacy / アクセスとプライバシー

Each source is approved in Apple's content-sharing picker for that capture session. Canceling the picker grants nothing. The Mac App Store edition does not request Accessibility or Input Monitoring access and does not include Control mode.

各ソースはAppleの共有ピッカーで取得セッションごとに承認されます。キャンセルした場合は取得を始めません。Mac App Store版はアクセシビリティや入力監視の許可を求めず、操作モードも含みません。

StagePane has no account, advertising, analytics, microphone/audio capture, or network upload. See the bundled Privacy Policy for the complete data-flow description.

StagePaneには、アカウント、広告、解析、マイク・音声取得、ネットワーク送信はありません。完全なデータフローは同梱のプライバシーポリシーで確認できます。

## If something is wrong / 問題がある場合

- Make sure you shared **StagePane Stage**, not Workspace or Control Room.
- If selection was canceled, choose **Add Source** again.
- If a source stops, remove it or use **Reset Capture**, then add it again.
- If a saved PNG cannot be written, choose another location in the macOS save panel.
- Keep the Curtain on while you prepare or recover a source.

- 会議アプリでWorkspaceやControl Roomではなく **StagePane Stage** を共有したことを確認します。
- 選択をキャンセルした場合は、もう一度 **ソースを追加** を選びます。
- ソースが停止した場合は、解除するか **画面取得をリセット** してから再度追加します。
- PNGを保存できない場合は、macOSの保存パネルで別の場所を選びます。
- 準備や復旧中はカーテンを有効にします。

Support: [support@hinoshiba.com](mailto:support@hinoshiba.com)
