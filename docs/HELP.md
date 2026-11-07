# StagePane Help / StagePane の使い方

## Share safely / 安全に共有する

1. Keep **StagePane Workspace — Keep Private** on your Mac.<br>
   **StagePane Workspace — 共有しない編集画面** は手元に置きます。
2. Choose **Add Source / ソースを追加** and approve one window, app, or
   display in the macOS system picker. Free supports four sources per group;
   the one-time StagePane Pro purchase removes StagePane's source-count limit.
   The number that can run in practice depends on Mac performance and
   operating-system constraints.
3. Use the Canvas and the persistent layer list together in the private
   **Workspace / ワークスペース**. Select a layer, then move, resize, or crop it;
   use **Hide / 非表示**, **Show / 再表示**, **Replace / 選び直す**, or
   **Remove / 解除** beside that layer. **Layout → Grid / レイアウト → グリッド** makes an even grid.
   In Arrange mode, **Layout / レイアウト** also offers Side by
   Side, Stacked, and Picture in Picture without changing source order.
4. To use a separate full-screen Space, choose **Enter Stage Full Screen / Stageをフルスクリーンにする** in the **Stage** menu before starting your meeting share. Press **Command-1** to return to the private Workspace.
5. In your meeting app, share only the exact **StagePane Stage** window.
6. Confirm the correct share target, then choose **Open Curtain / カーテンを開く**.

Selecting an app can include every window owned by that app. Select a single
window when you want to limit the source more narrowly.

アプリを選ぶと、そのアプリが持つすべてのウインドウが含まれる場合があります。
共有範囲を狭くしたい場合は、アプリではなく1つのウインドウを選んでください。

## Screen groups / 画面グループ

Use the vertical **Screens** tabs at the far left of Workspace to select the
composition you want to edit. The blue selection is your editor; the red frame
and **On Stage** label mark the composition routed to the audience window.
Select another tab to prepare it privately, then choose **Send to Stage** to
switch the contents of **the same Stage window**. The meeting app does not need
to select another window. The Curtain stays open or closed as it was.

Free includes up to **2 groups** with **4 sources per group**; Pro includes up to
**10 groups** with no app-imposed source-count limit. The initial group counts
toward the limit. Use **+** at the bottom of Screens to add one, and its context menu or
**…** menu to rename or delete it. Up/Down moves between focused tabs. The last
group cannot be deleted. The small tab images show layer placement, not live
captured pixels.

Use the chevron beside **Screens** or **Layers** to collapse either column to a
narrow strip. Screens keep small layout thumbnails and the red Stage-output
frame; layers keep source icons, numbers, and hidden/attention indicators.
Hover to read names, click to select, and right-click for the usual actions.
The right chevron expands that column again. Both choices are remembered across
groups and app launches, and expanding Layers restores its previous width.
Collapsing changes only the private Workspace, without switching Stage output
or stopping capture.

Each group keeps its sources, placement, stacking, crops, drawing, shape, and
background for the current app session. Selecting a tab never changes the Stage
output. **Editing the red-framed output group applies changes immediately**;
select another group to prepare changes privately. Switching editor tabs ends
gestures and discards an unapplied crop draft. Apply or cancel a crop before
sending a preview to Stage. The red frame stays in Workspace and is not included
in audience output. It indicates Stage routing, not whether a meeting app is
actually sharing; the shield indicates that the Curtain is hiding the content.

Inactive groups continue capturing. Use **Stop All and Remove Layers** to end
capture and remove layers and drawings in **every group**. Deleting one group
stops only that group's capture. Deleting the output group closes the Curtain
and routes Stage to an available group. Deleting a preview-only group leaves
the Stage output and Curtain unchanged.

Groups and their content are held in memory for this app session, not restored
after quitting. If Pro access ends, groups beyond the first two are locked and
their capture is ended; their layout and drawings remain in memory. If the
output group becomes unavailable, the Curtain closes before Stage is routed to
the first group. Restore Pro and explicitly reselect sources to use locked
groups again. Performance depends on the total sources and the Mac's resources.

On macOS 15.2 or later, the same selected window shares one capture input across
layers and groups. Capture uses the largest size needed by active layers; crop,
placement, and color inversion remain independent. Different native-cursor
settings need separate inputs. Earlier macOS versions and selections whose
identity cannot be confirmed reuse only the same selection filter. Hiding,
removing, or replacing one layer does not interrupt others using that input.
Stopping sharing in macOS ends that input for all its layers.

Workspaceの一番左にある**画面**タブで、編集する画面を選びます。青は編集中、
赤枠と**Stage出力**は観客向けStageに出している画面です。別のタブを選んで手元で
準備し、**Stageに出す**で**同じStageウインドウの内容**を切り替えます。
会議アプリで共有ウインドウを選び直す必要はありません。カーテンの開閉状態は保ちます。

無料版は**2グループ・各4ソースまで**、Proは**10グループ・各グループのソース数は
アプリ側の上限なし**です。最初の画面も個数に含みます。画面欄の下の**＋**で追加し、
タブの右クリックまたは**…**メニューから名前変更・削除ができます。
上下キーでもタブを選べます。最後の1個は削除できません。
タブの小さな画像は配置の見本で、実際の取得映像ではありません。

**画面**・**レイヤー**の見出しにある左向き矢印で、それぞれを細い欄に縮小できます。
画面は小さな配置サムネイルと赤いStage出力枠、レイヤーは種類のアイコン・番号・
非表示や問題の目印を残します。名前はホバーで確認でき、クリックで選択、右クリックで
通常の操作メニューを開けます。右向き矢印で展開します。縮小状態は画面の切り替えや
アプリ再起動後も保ち、レイヤー欄を展開すると以前の幅へ戻します。
変わるのは手元のWorkspaceだけで、Stage出力の切り替えや画面取得の停止は行いません。

ソース、配置、重なり順、切り抜き、手書き、形、背景は画面ごとに保持します。
タブを選ぶだけではStage出力は変わりません。**赤枠の画面を編集すると、変更は
Stage出力にすぐ反映されます**。手元で準備するときは別の画面を選んでください。
タブを移ると操作中のジェスチャーを終了し、未適用の切り抜きは破棄します。
切り抜きを適用またはキャンセルしてから「Stageに出す」を押してください。
赤枠はWorkspaceだけの目印で、観客向けStageには表示しません。
会議アプリが実際に共有しているかは検知しません。盾の印はカーテン中を表します。

非選択の画面も取得を続けます。**すべて停止してレイヤーを削除**は全グループの
取得・レイヤー・手書きが対象です。削除はその画面だけを停止します。
Stage出力中の画面を削除するとカーテンを閉じ、利用できる別の画面に切り替えます。
プレビューだけの画面を削除しても、Stage出力とカーテンは変わりません。

グループはメモリ内だけに保持し、終了後は復元しません。Proが無効になった場合、
3個目以降をロックして取得を終了しますが、配置と手書きは起動中に保持します。
Stage出力が対象の場合は、カーテンを閉じて最初の画面に切り替えます。
Proを復元し、ソースを明示的に選び直すと再開できます。取得性能は
全グループの合計ソース数とMacのリソースに依存します。

macOS 15.2以降では、同じウインドウの取得をレイヤー・グループ間で再利用します。
取得サイズは表示中のレイヤーが必要とする最大サイズにまとめ、切り抜き・配置・色反転は
それぞれ独立して扱います。OSのカーソルを映像に含める設定が異なる場合は別の入力です。
古いmacOSや同一性を確認できない選択では、同じ選択フィルターだけを再利用します。
1つのレイヤーを非表示・解除・差し替えしても、同じ入力を使う他のレイヤーは続行します。
macOS側で共有を停止すると、その入力を使うすべてのレイヤーが停止します。

## Settings / 設定

Choose **StagePane → Settings…** or press **Command-,**. **Settings…** in the
StagePane icon on the right side of the menu bar opens the same window.
Its panes are **Pointer**, **Stage**, **Window**, **Access & Privacy**, and **Pro**.
The first visit opens Pointer; later visits return to the last pane. Workspace
keeps the Canvas and layer list for composition.

**StagePane → 設定…** または **⌘,** で開きます。メニューバー右側のStagePaneアイコンにある
**設定…** も同じウインドウを開きます。項目は **ポインタ**、**ステージ**、**ウインドウ**、
**アクセスとプライバシー**、**Pro** です。初回はポインタ、次回からは前回の項目を表示します。
Workspaceには構図を編集するキャンバスとレイヤー一覧を残します。

Changes apply immediately. Opening or closing Settings preserves the selected
layer, tool, and crop draft; closing it does not apply the draft or undo settings.
**Command-W** closes the active Settings window.

変更はすぐに反映されます。設定の開閉では選択レイヤー・ツール・切り抜きの下書きを保持し、
閉じるだけで下書きを適用したり設定を取り消したりしません。**⌘W** は手前の設定ウインドウを閉じます。

## Stage size and sharing quality / Stageサイズと共有画質

The Stage has no title bar. In windowed mode, drag its displayed content to move the window;
composition editing stays in the private Workspace. The intended initial size
or saved window size is preserved when the Stage opens. Double-click its displayed
content to maximize the window within the current screen while preserving its
aspect ratio. The menu bar and Dock remain available. Double-click again to
restore its previous size and position.

In **Settings → Stage → Output Details**, **Stage rendering size** shows the Stage
canvas's drawing pixel dimensions and updates when its size or display changes.
Audience PNG exports use the selected Stage shape preset's dimensions instead.
A small Stage
can reduce sharing quality. Choose **Enlarge Stage for Sharing** to grow it
toward a sharing size that fits the current screen, keeping its shape. An
already larger Stage is not reduced. This keeps the same Stage window, so it
does not replace the share target. You can keep the
Stage large and use the smaller Workspace Canvas as your editing preview.
Your meeting app controls the resolution it captures and transmits; the
Stage size and PNG dimensions do not guarantee the resolution your audience receives.

Stageにはタイトルバーがありません。通常表示では、表示内容をドラッグするとウインドウを移動できます。
構図の編集は手元用のWorkspaceで行います。Stageを開く際は、初期サイズまたは保存済みの
ウインドウサイズを保持します。表示内容をダブルクリックすると、縦横比を保ったまま
現在の画面内で最大化します。メニューバーとDockは利用できます。もう一度ダブルクリックすると、
元の大きさと位置へ戻ります。

**設定 → ステージ → 出力の詳細** の **Stageの描画サイズ** はStageキャンバスの描画ピクセル数で、
大きさや表示先の画面が変わると更新されます。Audience PNGの書き出しには、選択した
Stageの形状プリセットの寸法を使います。Stageが小さいと、共有画質が低下することがあります。
**共有向けにStageを拡大** を選ぶと、形を保ちながら現在の画面に収まる共有向けサイズへ
近づけます。すでに大きいStageを縮小することはありません。
同じStageウインドウを使うため、共有対象を別のウインドウへ置き換えません。
Stageは大きく保ち、手元の編集にはWorkspace内の小さなキャンバスを使えます。
取得・送信する解像度は会議アプリが決めます。StageやPNGのサイズは、相手に届く解像度を
保証するものではありません。

## Stage context menu / Stageのコンテキストメニュー

Right-click or Control-click the Stage's displayed content to open its menu.
**Maximize Stage / Restore Stage Size** matches the double-click action, keeping
the Stage's aspect ratio and the menu bar and Dock available. You can also choose
**Enlarge Stage for Sharing** or **Enter / Exit Stage Full Screen**.
**Keep Stage in Front**, **Show Stage on Every Space**, and **Protect Stage
Window** show checkmarks for their current settings. **Show Stage Workspace**
opens the Workspace; **Stage Settings…** opens **Settings → Stage**.
Maximize and sharing enlargement are unavailable in full screen; size changes
are disabled during full-screen transitions. All of these actions are also in
the **Stage** and **Window** menus for keyboard and VoiceOver access.

Stageの表示内容を右クリックまたはControlクリックすると、メニューを開けます。
**Stageを最大化／Stageを元のサイズに戻す** はダブルクリックと同じ操作で、縦横比を保ち、
メニューバーとDockも利用できます。**共有向けにStageを拡大** や
**Stageをフルスクリーンにする／Stageのフルスクリーンを終了** も選べます。
**Stageを常に手前に表示**、**StageをすべてのSpaceに表示**、**Stageウインドウを保護** は
現在の設定をチェックマークで示します。**ステージワークスペースを表示** は編集画面を、
**ステージ設定…** は **設定 → ステージ** を開きます。フルスクリーン中は最大化と共有向けの拡大が無効になり、
切り替え中はサイズの変更が無効になります。同じ操作は **ステージ** と **ウインドウ** メニューから
キーボードやVoiceOverでも利用できます。

## Full-screen Stage / Stageのフルスクリーン

**Enter Stage Full Screen** places only the Stage in its own macOS Space.
The composition keeps the selected shape, with black margins when the display
has a different aspect ratio. Workspace stays separate and private. Set this up
before sharing, then press **Command-1** to return to Workspace and choose only
**StagePane Stage** in your meeting app. Full-display or whole-app sharing can
still include private content.

Press **Control-Command-F** or choose **Exit Stage Full Screen** in the Stage
menu to return to a regular window. Presentation Lock does not block this exit.
**Enlarge Stage for Sharing** is available in windowed mode; full screen uses
the display area instead. Audience PNG exports retain the selected preset
dimensions and clean composition, without the full-screen margins.
Full screen does not guarantee the meeting app's transmitted resolution or
continued sharing through a Space change; confirm its selected target.

**Stageをフルスクリーンにする** を選ぶと、Stageだけを専用のmacOS Spaceに表示します。
構図は選択した形を保ち、画面の縦横比が異なる場合は黒い余白が入ります。
Workspaceは別の手元用ウインドウです。共有前にフルスクリーンへ切り替え、
**Command-1** でWorkspaceに戻ってから、会議アプリで **StagePane Stage** だけを選びます。
画面全体やアプリ全体の共有には、私用の内容が入る場合があります。

**Control-Command-F** またはステージメニューの **Stageのフルスクリーンを終了** で
通常のウインドウへ戻ります。プレゼンテーションロック中も終了できます。
**共有向けにStageを拡大** は通常表示用で、フルスクリーンでは画面の領域を使います。
Audience PNGはプリセットのサイズを保ち、フルスクリーンの余白を含めずに構図だけを書き出します。
フルスクリーンでも送信解像度やSpace切替後の共有継続は会議アプリによって異なるため、
選択した共有対象を確認してください。

## Work with overlapping layers / 重なったレイヤーを編集する

The layer list stays beside the Canvas, with the frontmost layer at the top.
Select a covered or hidden layer from this list. Selecting a layer, or moving
and resizing it on the Canvas, preserves its stacking order. Only the selected Canvas tile shows
its editing outline and handles; Crop and the selected layer's More menu stay
in the fixed tools below the Canvas.

Drag a layer's grip in the list to change stacking order: higher rows are in
front. The new order takes effect when you drop; canceling the drag leaves it
unchanged. Reordering keeps every layer's placement and crop, and keeps the
current selection. Finish Crop or close Apple's source picker before reordering.
The More menu in the layer's row or selected-layer tools also works without dragging.

To name a layer, open its **…** menu in the list, choose **Rename…**, enter a
name, and choose **Save**. **Cancel** discards the edit; an empty or whitespace-only
name restores the automatic title. The name appears in the list, Canvas, and
crop controls, never on the audience Stage or in Audience PNG output. It stays
with the layer when hidden, shown, replaced, reconnected, or arranged with a
preset. Names live only in memory and are discarded when the layer is removed,
on **Stop All**, or when StagePane quits.

For a selected rear or hidden layer, drag its private title badge or focus the Canvas and use arrow
keys to move it. Up and Down in the layer list change selection without moving content. Its resize handle remains accessible above overlapping layers.
Clicking visible foreground content selects that foreground layer; the empty
interior of the selected editing outline does not block that click.

The outline and handles follow the visible source or applied crop, without the
empty margins around it. Move the visible content up to the Stage edges; click
through its empty margins to select content underneath. Resizing keeps its
proportions and holds its visible upper-left corner in place. Keyboard and
VoiceOver actions use the same bounds. A hidden layer keeps its last bounds.

レイヤー一覧はキャンバスの横に常設され、最前面のレイヤーが上に並びます。
重なって見えないレイヤーや非表示のレイヤーも一覧から選べます。選択と、キャンバス上の移動・サイズ変更では
重なり順は変わりません。キャンバスの編集枠とハンドルは、選択中のレイヤーだけに表示します。
切り抜きと選択レイヤーのその他メニューは、キャンバス下の固定ツールに表示します。

一覧のつまみをドラッグすると、上のレイヤーほど手前になるよう重なり順を変更できます。
ドロップした時点で順序を確定し、ドラッグをキャンセルすれば元の順序を保ちます。
各レイヤーの配置・切り抜きと、現在の選択は変わりません。切り抜き編集中やAppleの
ソース選択画面を表示している間は、それを終えてから並べ替えてください。ドラッグを
使わず、レイヤー行や選択レイヤー用ツールのその他メニューからも操作できます。

名前を付けるには、一覧の各行の **…** メニューから **名前を変更…** を選び、入力して
**保存** します。**キャンセル** で変更を破棄し、空欄または空白だけで保存すると自動のタイトルへ
戻ります。名前は一覧・キャンバス・切り抜き操作に表示され、観客向けStageやAudience PNGには
含まれません。非表示・再表示、ソースの選び直しや再接続、配置プリセットの適用後も同じレイヤーに
保持されます。名前はメモリ内だけに残り、レイヤーの解除、**すべて停止**、アプリ終了で消えます。

背面や非表示のレイヤーを選んだら、手元のタイトル表示をドラッグするか、キャンバスにフォーカスして矢印キーで移動します。一覧の上下キーは選択だけを変えます。
サイズ変更ハンドルは重なりの上から操作できます。前面に見えている映像をクリックすると
そのレイヤーを選べるため、選択枠の内側が前面の映像へのクリックを遮ることはありません。

編集枠とハンドルは、余白を除いた映像や適用済みの切り抜き範囲に沿って表示されます。
見えている端をStageの端まで移動でき、余白の部分からは下のレイヤーを選べます。
サイズ変更では左上の位置と縦横比を保ちます。キーボードやVoiceOverでも同じ範囲を
操作でき、非表示中は最後の範囲を保ちます。

In a layer's **More / その他** menu, use **Move Forward / ひとつ前面へ** or
**Move Backward / ひとつ背面へ** to move one position in the stack, and **Bring to Front / 最前面へ** or
**Send to Back / 最背面へ** to move to an end. The list updates to match the
Stage. These actions preserve placement and crop.

各レイヤーの **その他** メニューにある **ひとつ前面へ**・**ひとつ背面へ** は重なり順を1段変え、**最前面へ**・**最背面へ** は
一番手前・一番奥へ移します。一覧はStageの順番に合わせて更新され、配置と切り抜きは保ちます。

Use the direct **Hide / 非表示** control when a layer should disappear
temporarily. Its row remains available; **Show / 再表示** brings it back after a
fresh frame arrives, with the same placement, crop, and order.

一時的に消したいレイヤーは **非表示** を選びます。一覧には残り、**再表示** を選ぶと
新しい完全なフレームが届いてから、同じ配置・切り抜き・重なり順で映像が戻ります。

## Invert a layer's colors / レイヤーの色を反転する

Select a layer and turn on **Invert Colors / 色を反転** in the tools below the
Canvas or its **More / その他** menu. White becomes black and black becomes
white, making bright documents easier to project. All source colors are
inverted, including photos. Other layers, the Stage background, annotations,
and the laser pointer keep their colors.

The Workspace preview, Stage, magnifier, and Audience PNG use the same setting.
It stays with the layer when you rearrange, crop, hide/show, or replace its
source. Turn the switch off to restore the original colors.

レイヤーを選び、キャンバス下のツールまたは **その他** メニューで **色を反転** を
オンにします。白は黒に、黒は白になり、明るい資料をプロジェクターで見やすくできます。
写真を含め、そのソースのすべての色が反転します。ほかのレイヤー・Stageの背景・手書き・
レーザーポインターの色は変わりません。

手元のプレビュー・Stage・虫眼鏡・Audience PNGに同じ設定が反映されます。
配置・切り抜き・非表示／再表示・ソースの選び直しでも設定を保持します。
スイッチをオフにすると元の色に戻ります。

## About screen sharing / 画面共有について

**Settings → Access & Privacy** explains source access. Apple's sharing picker
authorizes the window, app, or display you select for that capture session; canceling grants no new source access.

StagePane opens the Workspace at launch without a permission guide or request.
**Add Source** opens Apple's sharing picker directly. For optional app-wide
access, open **Settings → Access & Privacy → Request Screen Recording Access…**.
That action goes directly to macOS; make the permission decision in the system
dialog. Declining does not trigger another request automatically. The same
Settings pane shows the current status and, after a request, offers
**Open System Settings** to review your choice.

**設定 → アクセスとプライバシー** で、取得への同意について確認できます。
Appleの共有ピッカーで選んだウインドウ、アプリ、
または画面が、その取得セッション中に許可されます。キャンセルでは新しいアクセスを始めません。

起動時は許可の案内や要求を表示せず、Workspaceを開きます。**ソースを追加** は
Appleの共有ピッカーを直接開きます。任意のアプリ全体のアクセスは **設定 →
アクセスとプライバシー → 画面収録アクセスを要求…** から要求できます。この操作は
macOSの許可リクエストを直接開き、許可するかどうかはシステムの画面で選びます。
拒否しても自動では再要求しません。同じ設定項目で現在の状態を確認でき、要求後は
**システム設定を開く** から選択を見直せます。

In **Settings → Pointer / 設定 → ポインタ**, set the pointer type
to **System / 通常**, **Laser pointer / レーザーポインター**, or **Hidden /
非表示**. The laser pointer's color, size, and glow are adjustable. Its dot is
drawn only over the frontmost Stage source; it does not replace the pointer you
see locally. If the frontmost source is paused, no dot is shown—StagePane does
not fall back to a source behind it.

Use **Stage → Pointer** to switch the type quickly. **Pointer Settings…** opens
the Pointer pane. The checkmark is the saved preference; Draw and Magnify hide
the audience pointer temporarily. Returning to Arrange or Crop uses that choice.

使用中の種類切替は **ステージ → ポインタ**、詳しい調整はその中の **ポインタ設定…** から行えます。
チェックは保存した種類を示し、手書き・虫眼鏡中は一時的に非表示になります。
配置または切り抜きへ戻ると、その時点の保存値を使います。

「レーザーポインター」は色・サイズ・発光を調整できます。点はStage上の最前面ソース
にだけ表示され、手元で見ているmacOSのカーソルは置き換えません。最前面ソースが
一時停止中なら点は表示せず、背面のソースへは切り替えません。

The translucent **StagePane mark / StagePaneロゴ** appears in the lower-right of
the holding screen, shared content, and Curtain, and is mirrored in the private
Workspace. It is always shown in Free and can be disabled with StagePane Pro.

半透明の **StagePaneロゴ** は待機画面、共有内容、カーテンの右下に表示され、手元の
Workspaceにも反映されます。無料版では常に表示され、StagePane Proでは無効にできます。

**Hide / 非表示** pauses only that layer and
makes its layer transparent in the Stage, private Workspace, and Audience PNG
output. Other layers using the input continue; the last active layer stops
capture. **Show / 再表示** uses the running input's current complete frame, or
waits for a new frame if capture had stopped. Placement, crop, and z-order remain unchanged.

**非表示** はStage、手元用Workspace、Audience PNGでそのレイヤーを透明にします。
同じ入力を使う他のレイヤーがあれば取得を続け、最後の利用を止めたときに取得を停止します。
**再表示** は動作中の入力の現在の完全なフレームを使い、取得を停止していた場合は
新しいフレームを待ちます。配置・切り抜き・重なり順は保持します。

**Remove / 解除** always asks for confirmation because it disconnects that layer
and discards its pixels and retained layer state. Hide and Replace do not show
this warning.

**解除** は、そのレイヤーを入力から外して映像と保持中のレイヤー状態を破棄するため、
必ず確認を表示します。非表示と選び直しではこの警告は表示しません。

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
starts from the selected-layer tools below the Canvas or a layer's More menu, shows only that layer at full
Canvas size, and drafts the framed part sent to the Stage. The Stage does not
change until Apply Crop; Cancel discards the draft.
The Canvas and layer list stay together, including at the minimum window size.
Use **Settings → Stage** for appearance and output, and **Settings → Window**
for window behavior. **About StagePane** is available in the app menu.
Workspace and Settings automatically follow macOS Light or Dark appearance.
This is independent of the audience Stage theme and needs no app appearance setting.
Toggling the Curtain does not bring the Stage window to the front.
Under **Settings → Stage → Curtain message**, use **Text size** to make the message
smaller or larger. Changes apply immediately and the size is saved for next time.
“Keep Private” is guidance, not a technical capture boundary. Application or
full-display sharing can expose the Workspace, and a meeting app may still list
it. Select the exact **StagePane Stage — Share
This Window** window.

観客側のカーテン中も手元のWorkspaceは表示されるため、公開前に準備できます。
**配置** モードでのタイルのドラッグや大きさ変更は、Stage内の配置だけを変えます。
**切り抜き** はキャンバス下の選択レイヤー用ツールや各レイヤーのその他メニューから開始し、そのレイヤーだけを手元に全面表示して、Stageへ出す範囲を下書きします。
「切り抜きを適用」を選ぶまでStageは変わらず、キャンセルすると下書きを破棄します。
キャンバスとレイヤー一覧は、最小ウインドウサイズでも並べて表示します。見た目や出力は **設定 → ステージ**、ウインドウの動作は **設定 → ウインドウ** で調整します。**StagePaneについて** はアプリメニューから開けます。
Workspaceと設定画面はmacOSのライト／ダークの外観に自動で追従します。
観客向けStageのテーマとは独立しており、アプリ内で外観を設定する必要はありません。
カーテンを切り替えてもStageウインドウは前面へ移動しません。
**設定 → ステージ → カーテンのメッセージ** の **文字の大きさ** でサイズを調整できます。
変更はすぐに反映され、文字の大きさは次回起動時も維持されます。
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

StagePane provides the global **Arrange / 配置**, **Draw / 手書き**, and **Magnify / 虫眼鏡** modes, plus
a **Crop / 切り抜き** action owned by every layer. None of these tools sends input to source applications or needs macOS Accessibility or Input
Monitoring permission.

StagePaneではStage全体の **配置**・**手書き**・**虫眼鏡** モードに加え、各レイヤーに **切り抜き** 操作があります。いずれも共有元アプリへ入力を
送らず、macOSのアクセシビリティ許可や入力監視許可も必要としません。

- **Arrange / 配置** moves and proportionally resizes the selected content while preserving
  its order; explicit ordering actions change the stack. It never sends those
  editing gestures to a source app.
- **Crop / 切り抜き** starts from the selected-layer tools below the Canvas or the
  layer's More menu, then displays only that layer at full Canvas size in the private
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
- **Magnify / 虫眼鏡** sits beside Arrange and Draw. Move the cursor over the
  private Canvas to show a circular lens in both the preview and shared Stage.
  Choose **2×**, **3×**, or **4×** magnification without changing layout or crop.
  The lens disappears when the cursor leaves the Canvas. With the Canvas
  focused, arrow keys also move it. Press **Escape** or choose **Exit Magnify /
  虫眼鏡を終了** to return to Arrange and restore your pointer preference.
  Magnify hides the audience pointer while active; the Curtain hides the
  audience lens.

- **配置** は選択中の映像の重なり順を保って移動し、縦横比を保ってサイズ変更します。重なり順は
  前面・背面への操作で明示的に変更し、編集ジェスチャーは取得元アプリへ送りません。
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
- **虫眼鏡** は配置・手書きの隣から選べます。手元のキャンバス上でカーソルを動かすと、
  プレビューと共有Stageの両方に円形レンズを表示します。倍率は **2×**・**3×**・**4×** から選べ、
  配置と切り抜きは変わりません。カーソルをキャンバスの外へ移すとレンズは消えます。
  キャンバスにフォーカスがある間は矢印キーでも動かせます。**Escape** または **虫眼鏡を終了** で
  配置へ戻り、選択中のポインター設定を復元します。虫眼鏡中は観客側のポインターを自動で隠し、
  カーテン中は観客側のレンズも隠します。

Cropping is a local composition mask, not a narrower macOS capture permission.
Whenever the source stream runs, ScreenCaptureKit handles the complete window,
app, or display approved in Apple's picker. Hide and Remove affect that layer;
other layers using the same input continue. The last active layer stops its
input, and Stop All stops all inputs. While hidden, that layer is transparent in
the Stage, private Workspace, and Audience PNG output. Show uses a complete
frame from the running input or waits for a new frame after restarting it,
without changing placement, crop, or z-order. Keep the Curtain on while
preparing content that is not ready for the audience. Crop edits remain a
private draft until Apply Crop.

切り抜きはStage内の表示マスクであり、macOSの取得許可範囲を狭めるものではありません。
ソースのストリーム動作中、ScreenCaptureKitはAppleのピッカーで許可したウインドウ、
アプリ、または画面全体を扱います。非表示と解除はそのレイヤーに作用し、同じ入力を
使う他のレイヤーは続行します。最後の利用を止めると入力を停止し、すべて停止は
全入力を停止します。非表示中のレイヤーはStage、手元用Workspace、Audience PNGで
透明です。再表示では動作中の入力の現在の映像を使い、入力を停止していた場合は
新しい完全なフレームを待ちます。配置・切り抜き・重なり順は保持します。
観客へ見せる準備ができていない内容を調整するときはカーテンを
有効にしてください。切り抜きの変更は「切り抜きを適用」まで手元の下書きです。

## Screenshots / スクリーンショット

Use **Copy Audience Image / Audience画像をコピー** or **Save Audience Image… /
Audience画像を保存…** in the menu beside **Show Stage** (or the File menu) only when you want a one-shot image
of the clean audience Stage. The
PNG uses the selected preset's Audience PNG dimensions regardless of the Stage
window size and includes the exact audience state:
shared content or Curtain, ink, watermark, the safe-area guide when enabled, and
the pointer when visible. It does not include Workspace navigation or controls,
window title-bar chrome, or other app windows.
The StagePane menu-bar icon also provides these actions under **Stage Image**.

観客側のきれいなStageを1枚だけ画像にしたいときは、**Stageを表示** の横のメニュー（またはファイルメニュー）の
**Audience画像をコピー** または **Audience画像を保存…** を明示的に選びます。PNGは
Stageウインドウの大きさにかかわらず、選択中のプリセットのAudience PNGサイズで作成され、共有内容
またはカーテン、手書き、ウォーターマーク、有効な場合はセーフエリア、表示中の場合は
ポインターを含みます。Workspaceのナビゲーションや操作UI、ウインドウのタイトルバー、
他アプリのウインドウは含みません。
メニューバーのStagePaneアイコンにある **Stage画像** からもコピー・保存できます。

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
- Press **Command-1** to return to the private Workspace, **Command-2** to show
  Stage, and **Control-Command-F** to toggle Stage full screen.
- Open **Settings → Access & Privacy / 設定 → アクセスとプライバシー** to review
  the per-selection screen-sharing model or recheck optional Mac Screen Recording
  Access. Add Source works through Apple's picker without this app-wide access.
- If source selection or capture cannot start, read the error in Workspace. It
  remains until dismissed or the issue is resolved; use **Try Again** to retry.
  No separate error window opens, and canceling the picker does not create an
  error. Hide and Stop failures remain in the layer and capture status.

ソースの選択画面や取得を開始できない場合は、Workspace内のエラー表示を確認します。
**閉じる** を押すか問題が解消するまで表示を保持し、**もう一度試す** から再試行できます。
独立したエラーウインドウは開かず、ピッカーのキャンセルもエラー扱いしません。
非表示や停止の失敗は、レイヤーと画面取得の状態表示で確認できます。

If video stops while layer controls still work, check whether the source image
also stops inside StagePane. For a stopped local source, **Hide → Show** restarts
its capture while keeping placement and crop. To collect diagnostic events
while reproducing the problem, run this command in Terminal:

```sh
log stream --level info --style compact --predicate 'subsystem == "com.hinoshiba.stagepane" AND category == "CaptureProgress"'
```

These events contain frame counts, renderer state, and temporary identifiers,
not images or window titles. A “Frame delivery quiet” event can also mean a
normal static source; it does not by itself identify a fault. Note whether the
Stage and Workspace both stop, roughly how long capture ran, and whether
Hide → Show restores the image.

レイヤー操作はできるのに映像が止まった場合は、StagePane内の映像も止まるか確認します。
手元の映像も止まる場合、対象レイヤーの **非表示 → 表示** で配置と切り抜きを保ったまま
取得を再開できます。再現中に上記コマンドをターミナルで実行すると、フレーム数・描画状態・
一時的な識別子だけの診断情報を確認できます。画像やウインドウ名は含みません。
`Frame delivery quiet` は静止画でも出るため、それだけでは故障を意味しません。
StageとWorkspaceの両方で止まるか、利用時間、非表示→表示で戻るかを併せて確認してください。

StagePane processes frames locally and does not upload them. When you share the
Stage, transmission is performed by your meeting app under its own privacy
policy. In the Mac App Store build, Apple StoreKit handles the optional Pro
product, purchase, entitlement, and restore flow without receiving screen content.

StagePane自身はフレームをローカル処理し、外部送信しません。ステージ共有時の送信は、
会議アプリ側の機能とプライバシーポリシーに従います。Mac App Store版の任意のPro購入と
購入状態の確認はAppleのStoreKitが処理し、画面内容は購入処理へ渡しません。

## StagePane Pro / 購入と復元

In the Mac App Store build, choose **StagePane → StagePane Pro…** to see the
localized one-time price. Pro removes StagePane's source-count limit and makes
the StagePane mark optional. The practical source total depends on Mac
performance and operating-system constraints. **Restore Purchases / 購入を復元**
is available on the same screen. A canceled purchase never changes or stops the
current Stage. **Settings → Pro** shows purchase status and opens the same window.

Mac App Store版では **StagePane → StagePane Pro…** で、App Storeが提供する買い切り価格を
確認できます。無料版は各グループ4件まで利用でき、Proではアプリ側のソース件数制限がなくなり、
ロゴ非表示も開放します。実際に利用できる件数はMacの性能とOSの制約に依存します。同じ画面から
**購入を復元** できます。**設定 → Pro** からも購入状態を確認し、同じウインドウを開けます。購入をキャンセルしても、現在のStageを変更・停止しません。

## Support / サポート

For support, privacy, security, Code of Conduct, or trademark inquiries, email
[support@hinoshiba.com](mailto:support@hinoshiba.com). Do not include sensitive
information in a public GitHub issue.

サポート、プライバシー、セキュリティ、行動規範、商標に関するお問い合わせは、
[support@hinoshiba.com](mailto:support@hinoshiba.com) へご連絡ください。機密情報は
GitHub の公開 Issue に記載しないでください。
