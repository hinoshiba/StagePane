# StagePane Privacy Policy / プライバシーポリシー

Updated / 更新日: 2026-11-07

## Data and purpose / データと利用目的

StagePane displays the screen content selected through Apple’s sharing picker
and your drawings on the Stage and Workspace on your Mac. The developer does not
collect screen content or personal data from the app. Your meeting app handles
screen sharing under that provider’s policy.

StagePaneは、Appleの共有ピッカーで選んだ画面と手書きをMac上のStageとWorkspaceへ表示します。
開発者はアプリから画面や個人データを収集しません。画面共有は会議アプリとその提供元のポリシーに従います。

## Storage and control / 保存と管理

Preferences are saved on your Mac: the Stage shape and appearance, window
behavior, the safe-area guide and StagePane mark settings, the pointer style,
size, color, and glow, the Curtain message and its text size, drawing tool
settings, the layer list width, whether Screens and Layers are collapsed, the
last selected Settings pane, and the position and size of the Workspace, Stage,
About, and Pro windows.
The access status itself is read from macOS, not saved by StagePane. The
Mac App Store build additionally saves three local values used only to decide
when to show the App Store rating prompt: a count of successful sessions, the
date of the first one, and the app version in which the prompt was last shown.
Screen content, screen groups and their names, source names, source layouts,
and drawings are not saved. Groups and their names last until you quit. Source
details, crop positions, and drawings remain in memory during use; Stop All or
quitting discards them. Cropping changes the displayed
area while the selected source is still captured in full. The Curtain covers
the Stage; it does not stop capture. Select the Stage window in your meeting
app, because sharing the whole app or display can also reveal the Workspace.

設定はMacに保存します。保存するのはStageの形状と外観、ウインドウの動作、
セーフエリアガイドとStagePaneマークの設定、ポインタのスタイル・大きさ・色・グロー、
カーテンの文言と文字の大きさ、手書きツールの設定、レイヤー一覧の幅、「画面」と「レイヤー」の縮小状態、最後に開いた設定項目、
およびWorkspace・Stage・About・Proの各ウインドウの位置と大きさです。許可状態そのものは保存せず、macOSから確認します。
Mac App Store版はこれに加えて、App Storeの評価依頼を表示する時期の判断にだけ使う
ローカルな3つの値（成功したセッションの回数、その最初の日付、
評価依頼を最後に表示したアプリのバージョン）を保存します。
画面の映像、画面グループとその名前、ソース名、Stage上のソースの配置、手書きは保存しません。ソース情報、切り抜き位置、
手書きは作業中のメモリで扱い、「すべて停止」または終了で破棄します。画面グループとその名前は終了まで保持します。
切り抜きは表示範囲を変えますが、取得対象は選択したソース全体です。
カーテンは表示を覆う機能で、取得は停止しません。会議アプリでアプリ全体や
画面全体を共有するとWorkspaceも見えるため、Stageウインドウを選んでください。

Copy Image places a PNG on the system clipboard, where other apps may access it.
Save PNG writes to your selected location. You can delete saved images and clear
local app data using macOS controls. Removing a layer ends its use of an input;
another layer or screen group using the same input can continue capturing it.
Use Stop All to end capture across all groups. App-wide Mac Screen Recording
Access is optional and is requested directly from Settings → Access & Privacy → Request Screen
Recording Access. macOS presents and manages the permission decision. There
is no launch-time guide or custom pre-permission dialog. You can review or
change your choice in macOS System Settings.

「画像をコピー」は他のアプリからも参照できるシステムのクリップボードへPNGを置きます。
「PNGを保存」は選んだ場所へ書き込みます。保存画像とアプリのローカルデータはmacOSの機能で削除できます。
レイヤーの解除はそのレイヤーによる利用を終了します。同じ入力を別のレイヤーや画面グループが利用している場合、取得は続きます。「すべて停止」で全画面グループの取得を終了できます。
アプリ全体のMacの画面収録アクセスは任意で、「設定 → アクセスとプライバシー →
画面収録アクセスを要求」から直接要求します。許可の選択はmacOSが表示・管理します。
起動時の案内や許可リクエスト前の独自ダイアログはありません。選択はmacOSのシステム設定で変更できます。

## Sharing and retention / 提供と保持期間

StagePane does not transmit screen content, drawings, or any other data to the
developer or to any third party. The app ships without a network entitlement and
cannot open network connections of its own. Screen content is held only in memory
while an input is live. Hide or Remove clears that layer's presentation. If
another active layer or screen group uses the same input, capture and its latest
frame remain available to those layers. The shared input and its retained frame
are cleared when the last active layer stops; Stop All and quitting cover every
screen group. Choosing a different preview or closing the Curtain does not stop
capture. The only screen-derived data that persists is an image
you create yourself with Copy Image or Save PNG, on your clipboard or at the
location you chose. Apple processes Pro purchases and restores; no screen content
is part of that flow.

StagePaneは、画面、手書き、その他のデータを開発者や第三者へ送信しません。このアプリは
ネットワークのエンタイトルメントを持たずに配布されており、アプリ自身がネットワーク接続を
開くことはできません。映像は入力が動作している間だけメモリで保持します。「非表示」や解除はそのレイヤーの表示を消します。同じ入力を別の動作中のレイヤーや画面グループが使っている場合、取得と最新フレームの保持は続きます。最後の動作中のレイヤーが停止すると、共有入力と保持フレームを解放します。「すべて停止」と終了は全画面グループが対象です。プレビューの切り替えやカーテンでは取得を停止しません。
画面に由来するデータで残るのは、利用者自身が「画像をコピー」「PNGを保存」で作成した
画像だけで、クリップボードまたは選択した場所に残ります。Proの購入・復元はAppleが
処理し、その処理に画面は一切含まれません。

## Apple and the website / Appleとウェブサイト

Apple processes Pro purchases and restores under [Apple’s privacy policy](https://www.apple.com/legal/privacy/).
The website is hosted by GitHub Pages, whose connection logs are governed by
[GitHub’s privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).

Proの購入・復元はAppleが処理します。ウェブサイトはGitHub Pagesで配信され、接続情報は上記の
提供元ポリシーに従って処理されます。

## Contact / 連絡先

Purchase, billing, or refund requests / 購入・請求・返金: [Apple Support](https://support.apple.com/billing).
Product and privacy inquiries / 製品・プライバシーの問い合わせ: support@hinoshiba.com.

If you email support, your address and message are used to respond, retained only
as needed to handle the inquiry, and can be deleted on request.
問い合わせメールのアドレスと本文は対応のために必要な期間だけ保管し、削除依頼を受け付けます。
