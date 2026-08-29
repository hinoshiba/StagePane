# StagePane Privacy Policy / StagePane プライバシーポリシー

Effective date / 発効日: 2026-08-28
Product / 製品: StagePane for macOS (Mac App Store edition / Mac App Store版)

## Summary / 概要

StagePane does not collect personal data, create accounts, show advertising, run analytics, or send telemetry. It has no third-party SDKs or publisher-operated server. Apple StoreKit handles the optional StagePane Pro product, purchase, entitlement, and restore flow.

StagePaneは、個人データの収集、アカウント作成、広告表示、解析、テレメトリ送信を行いません。第三者SDKや発行者運用サーバーはなく、任意のStagePane Pro商品・購入・購入状態・復元はAppleのStoreKitが処理します。

Every StagePane build provides Arrange, Crop, and Draw, requests no Accessibility or Input Monitoring permission, and does not forward input to other applications.

StagePaneのすべてのビルドは配置、切り抜き、手書きを提供し、アクセシビリティや入力監視の許可を求めず、他のアプリへ入力を転送しません。

## Screen content / 画面内容

StagePane accesses screen content only after you open Apple's system content-sharing picker and explicitly choose a window, application, or display. Choosing an application can include multiple windows owned by it; choose one window for the narrowest scope. Free supports two independently pausable and removable sources; StagePane Pro supports up to four. Each choice authorizes only the selected content for that capture session. Canceling grants no source access; removing a source or stopping all sources ends the corresponding streams.

StagePaneは、Appleの共有ピッカーを開き、ウインドウ、アプリ、または画面を明示的に選んだ後にだけ画面内容へアクセスします。アプリを選ぶと、そのアプリが持つ複数のウインドウが含まれる場合があります。最も狭い範囲にする場合は1つのウインドウを選んでください。無料版は2件、StagePane Proは最大4件まで個別に一時停止・解除できます。各選択は、その取得セッション中の選択対象だけを許可します。キャンセルした場合は取得せず、解除またはすべて停止すると対応するストリームを終了します。

Selected frames are rendered locally in parallel in the clean Stage window and the private Workspace. StagePane does not record or encode video, capture system or microphone audio, perform OCR or AI processing, transmit frames, or save them automatically.

選択したフレームは、クリーンなStageウインドウと手元用Workspaceへローカルで並列に表示します。動画の録画・エンコード、システム音声やマイク音声の取得、OCRやAI処理、フレーム送信、自動保存は行いません。

Crop changes only the part included in the local Stage composition and Audience PNG. It does not narrow Apple's picker approval or the stream: whenever that stream runs, ScreenCaptureKit handles the complete selected source. Pause stops the stream and makes that layer transparent in the Stage, private Workspace, and Audience PNG output. Resume reveals it only after a new complete frame arrives; placement, crop, and z-order remain unchanged. Remove or Stop All ends its capture session, discards its pixels, and deletes its retained layer state. The complete source appears in the private Workspace while its crop is edited. Crop rectangles remain only in app memory, including while a disconnected layer waits for Select Again, until you Remove that layer, choose Stop All, or quit StagePane.

切り抜きで変わるのはローカルのStage合成とAudience PNGに含める範囲だけです。Appleのピッカー許可やストリームの範囲は狭まらず、ストリームの動作中、ScreenCaptureKitは選択したソース全体を扱います。一時停止はストリームを止め、Stage、手元用Workspace、Audience PNGでそのレイヤーを透明にします。再開後は新しい完全なフレームが届いてから再表示し、配置・切り抜き・重なり順は保持します。解除またはすべて停止は取得セッションを終了し、映像と保持中のレイヤー状態を削除します。切り抜き編集中はソース全体を手元用Workspaceに表示します。切り抜き枠は、共有終了後に「選び直す」を待つレイヤーを含めてアプリ内メモリだけに保持し、そのレイヤーを解除するか、すべて停止するか、StagePaneを終了すると破棄します。

## One-shot Audience PNG / 1枚のAudience PNG

Only your explicit **Copy Audience Image** or **Save Audience Image…** action creates one lossless PNG of the audience Stage. It includes the currently visible composition, Curtain, ink, watermark, safe-area guide when enabled, and pointer when visible, while excluding Workspace navigation and controls and unrelated windows.

明示的に **Audience画像をコピー** または **Audience画像を保存…** を選んだ場合だけ、観客向けStageのPNGを1枚作成します。現在の合成結果、カーテン、手書き、ウォーターマーク、有効な場合はセーフエリア、表示中の場合はポインターを含み、Workspaceのナビゲーションや操作UI、無関係なウインドウは含みません。

Copy places the PNG on the macOS general pasteboard, where other local apps or clipboard managers may access it. Save opens the macOS save panel and writes only to the location you choose. Canceling Save writes nothing. StagePane keeps no separate screenshot history or hidden copy.

コピーはmacOSの一般ペーストボードへ置くため、他のローカルアプリやクリップボード管理アプリがアクセスする場合があります。保存はmacOSの保存パネルを開き、選んだ場所だけへ書き込みます。キャンセル時は書き込みません。StagePaneはスクリーンショット履歴や隠しコピーを保持しません。

## Pointer and drawings / ポインターと手書き

Laser pointer mode reads only the current pointer position needed to draw one dot over the frontmost Stage source. It does not retain pointer history. Draw mode hides the audience pointer and stops pointer-location sampling until Arrange or Crop resumes. Draw keeps a bounded vector document in memory. Ink is cleared when the final source is removed or all sources stop, unless it has already been included in a user-created Audience PNG.

レーザーポインターは、Stageの最前面ソースへ点を描くために必要な現在位置だけを読み、履歴を保持しません。手書き中は観客側のポインターを隠し、配置または切り抜きへ戻るまで位置の読み取りも停止します。手書きは上限付きのベクターデータとしてメモリ内に保持します。最後のソースを解除またはすべて停止すると消去されます（利用者が作成済みのAudience PNGに含まれたものを除きます）。

## Settings stored on this Mac / このMacに保存する設定

StagePane stores interface preferences such as Stage preset, theme, pointer appearance, drawing tool/color/ink width/eraser size, watermark and safe-area visibility, Curtain message, and window behavior in the app's sandboxed preferences. It does not persist selected source content, source titles, application names, screenshot history, screenshot destinations, or meeting information.

StagePaneは、Stageプリセット、テーマ、ポインター表示、手書きツール・色・インクの太さ・消しゴムの大きさ、ウォーターマークとセーフエリアの表示、カーテン文言、ウインドウ動作などのUI設定をサンドボックス内に保存します。選択したソース内容、ソース名、アプリ名、スクリーンショット履歴、保存先、会議情報は保存しません。

## Permissions / アクセス許可

Screen access is granted per selection and per capture session through Apple's picker. Removing a source or choosing Stop All ends that session-scoped access.

画面アクセスはAppleのピッカーで選択ごと・取得セッションごとに許可されます。ソースの解除または「すべて停止」で、そのセッションのアクセスを終了します。

## Network, retention, sale, and tracking / 通信・保持・販売・トラッキング

StagePane does not upload screen content or screenshots. It has no server-side retention, disclosure, sale, cross-context behavioral advertising, or tracking. The privacy manifest declares tracking false and collected data types empty. A meeting app that transmits the Stage is separate software governed by that provider's terms and privacy information.

StagePaneは画面内容やスクリーンショットをアップロードしません。サーバー側の保持、開示、販売、行動ターゲティング広告、トラッキングはありません。プライバシーマニフェストではトラッキングなし、収集データなしを宣言します。Stageを送信する会議アプリは別製品であり、その提供者の規約とプライバシー情報が適用されます。

For optional StagePane Pro commerce, StoreKit may contact Apple's App Store to load localized product information, complete a purchase, verify current entitlement, listen for transaction changes, or restore a purchase. Apple handles Apple Account credentials. StagePane receives product and verified transaction status needed to unlock Pro; it does not send screen content, source names, screenshots, pointer data, drawings, or usage analytics through StoreKit and has no commerce server of its own.

任意のStagePane Pro購入では、StoreKitがローカライズ済み商品情報の取得、購入、現在の購入状態の検証、取引変更の反映、購入の復元のためAppleのApp Storeへ接続する場合があります。Apple Accountの認証情報はAppleが処理します。StagePaneはPro開放に必要な商品・検証済み取引状態を受け取りますが、画面内容、ソース名、スクリーンショット、ポインターデータ、手書き、利用解析をStoreKitへ送らず、独自の課金サーバーも持ちません。

## Changes and contact / 変更と連絡先

Any future network service, analytics, recording, account, cloud sync, or support-upload feature requires updated disclosures and this policy before release.

将来、ネットワークサービス、解析、録画、アカウント、クラウド同期、サポートへのアップロードを追加する場合は、リリース前に開示と本ポリシーを更新します。

Contact / 連絡先: [support@hinoshiba.com](mailto:support@hinoshiba.com)
