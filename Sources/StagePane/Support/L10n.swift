import Foundation
import StagePaneCore

enum L10n {
    static var usesJapanese: Bool {
        if let override = ProcessInfo.processInfo.environment["STAGEPANE_LANGUAGE"] {
            return override.lowercased().hasPrefix("ja")
        }
        let preferredLocalization = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? "en"
        return preferredLocalization.lowercased().hasPrefix("ja")
    }

    static func text(_ japanese: String, _ english: String) -> String {
        usesJapanese ? japanese : english
    }

    static var stageWindowTitle: String {
        usesJapanese ? WindowIdentity.stageJapaneseTitle : WindowIdentity.stageEnglishTitle
    }

    static var workspaceWindowTitle: String {
        usesJapanese ? WindowIdentity.workspaceJapaneseTitle : WindowIdentity.workspaceEnglishTitle
    }

    static func presetName(_ preset: StagePreset) -> String {
        switch preset {
        case .widescreen: text("ワイド 16:9", "Wide 16:9")
        case .standard: text("標準 4:3", "Standard 4:3")
        case .portrait: text("縦長 9:16", "Portrait 9:16")
        case .square: text("スクエア 1:1", "Square 1:1")
        }
    }

    static func themeName(_ theme: StageTheme) -> String {
        switch theme {
        case .aurora: text("オーロラ", "Aurora")
        case .midnight: text("ミッドナイト", "Midnight")
        case .paper: text("ペーパー", "Paper")
        case .studio: text("スタジオ", "Studio")
        }
    }

    static func pointerStyleName(_ style: PointerStyle) -> String {
        switch style {
        case .system: text("通常", "System")
        case .redDot: text("レーザーポインター", "Laser pointer")
        case .hidden: text("非表示", "Hidden")
        }
    }

    static func pointerStyleDetail(_ style: PointerStyle) -> String {
        switch style {
        case .system:
            text(
                "macOSの通常のカーソルを表示します。",
                "Show the standard macOS pointer."
            )
        case .redDot:
            text(
                "カーソル位置を見やすい点で表示します。色・サイズ・発光を調整できます。",
                "Show an easy-to-see pointer dot with adjustable color, size, and glow."
            )
        case .hidden:
            text(
                "カーソルを相手に見える画面へ表示しません。",
                "Hide the pointer from the audience view."
            )
        }
    }

    static var requestSourceRemovalTitle: String {
        text("解除…", "Remove…")
    }

    static var confirmSourceRemovalTitle: String {
        text("解除する", "Remove Source")
    }

    static var cancelSourceRemovalTitle: String {
        text("キャンセル", "Cancel")
    }

    static func sourceRemovalConfirmationTitle(_ sourceTitle: String) -> String {
        text(
            "「\(sourceTitle)」を解除しますか？",
            "Remove “\(sourceTitle)”?"
        )
    }

    static var sourceRemovalConfirmationMessage: String {
        text(
            "このソースの画面取得を終了し、Stageとプレビューから最後のフレームと配置を削除します。この操作は取り消せません。",
            "This stops capturing the source and removes its last frame and layout from the Stage and preview. This can’t be undone."
        )
    }

    static func sourceRemovalAccessibilityLabel(_ sourceTitle: String) -> String {
        text(
            "\(sourceTitle)の解除を確認",
            "Confirm removal of \(sourceTitle)"
        )
    }

    static var sourceRemovalAccessibilityHint: String {
        text(
            "画面取得を停止し、最後のフレームと配置を削除する前に確認を表示します。",
            "Opens a confirmation before capture is stopped and the last frame and layout are removed."
        )
    }

    static func sourceRemovedNotice(_ sourceTitle: String) -> String {
        text(
            "「\(sourceTitle)」を解除しました。",
            "Removed “\(sourceTitle)”."
        )
    }

    static var cropApplyTitle: String {
        text("切り抜きを適用", "Apply Crop")
    }

    static var cropCancelTitle: String {
        text("キャンセル", "Cancel")
    }

    static var cropResetDraftTitle: String {
        text("全体表示に戻す", "Reset to Full Source")
    }

    static var cropResetActionTitle: String {
        text("全体表示へ…", "Reset Crop…")
    }

    static var croppedStatusTitle: String {
        text("切り抜き済み", "Cropped")
    }

    static var cropDraftStatusTitle: String {
        text(
            "下書き中 — 適用までStageは変わりません",
            "Draft — Stage changes only when you apply"
        )
    }

    static var cropCaptureScopeCompact: String {
        text(
            "切り抜きは画面取得の範囲を狭めません",
            "Crop does not narrow capture scope"
        )
    }

    static var cropCaptureScopeDetail: String {
        text(
            "切り抜きは適用時にStageの表示だけを変えます。ストリームの動作中、ScreenCaptureKitはmacOSで選択したソース全体を扱います。一時停止はストリームを止め、解除またはすべて停止は取得セッションを終了します。",
            "Applying a crop changes only Stage output. While the stream runs, ScreenCaptureKit handles the complete source selected in macOS. Pause stops the stream; Remove or Stop All ends its capture session."
        )
    }

    static var cropResetDraftHint: String {
        text(
            "下書きだけをソース全体へ戻します。Stageは「適用」まで変わりません。",
            "Reset only the draft to the full source. The Stage does not change until you apply it."
        )
    }

    static var cropEditorAccessibilityHint: String {
        text(
            "矢印キーで移動し、Shift＋矢印で大きく移動、Option＋矢印で拡大または縮小します。Returnで適用、Escapeでキャンセルします。Stageは適用まで変わりません。",
            "Use arrow keys to move, Shift-arrow for a larger step, and Option-arrow to expand or shrink. Press Return to apply or Escape to cancel. The Stage does not change until you apply."
        )
    }

    static var cropMoveLeftAction: String { text("左へ移動", "Move Left") }
    static var cropMoveRightAction: String { text("右へ移動", "Move Right") }
    static var cropMoveUpAction: String { text("上へ移動", "Move Up") }
    static var cropMoveDownAction: String { text("下へ移動", "Move Down") }
    static var cropExpandAction: String { text("切り抜き範囲を広げる", "Expand Crop") }
    static var cropTightenAction: String { text("切り抜き範囲を狭める", "Tighten Crop") }

    static var cropResetDraftNotice: String {
        text(
            "全体表示を下書きしました。「切り抜きを適用」までStageは変わりません。",
            "Full-source view is drafted. The Stage will not change until you apply the crop."
        )
    }

    static var cropDiscardedNotice: String {
        text(
            "切り抜きの変更を破棄しました。Stageは変更していません。",
            "Crop changes were discarded. The Stage was not changed."
        )
    }

    static var cropPreviousDraftDiscardedNotice: String {
        text(
            "別のソースへ切り替えたため、前の切り抜き下書きを破棄しました。Stageは変更していません。",
            "The previous crop draft was discarded when you switched sources. The Stage was not changed."
        )
    }

    static var cropPreviousDraftDiscardedAndResetNotice: String {
        text(
            "前の切り抜き下書きを破棄し、このソースの全体表示を下書きしました。Stageは適用まで変わりません。",
            "The previous crop draft was discarded and a full-source reset was drafted for this source. The Stage does not change until you apply."
        )
    }

    static var cropSourceUnavailableNotice: String {
        text(
            "対象のソースがなくなったため、切り抜きの変更を破棄しました。",
            "Crop changes were discarded because the source is no longer available."
        )
    }

    static func cropAppliedNotice(_ sourceTitle: String) -> String {
        text(
            "「\(sourceTitle)」の切り抜きをStageへ適用しました。",
            "Applied the crop for “\(sourceTitle)” to the Stage."
        )
    }

    static func cropEditActionTitle(isCropped: Bool) -> String {
        isCropped
            ? text("切り抜きを編集…", "Edit Crop…")
            : text("切り抜く…", "Crop…")
    }

    static func cropEditorAccessibilityLabel(_ sourceTitle: String) -> String {
        text(
            "\(sourceTitle)の切り抜き範囲の下書き",
            "Crop draft for \(sourceTitle)"
        )
    }

    static func cropEditAccessibilityLabel(
        _ sourceTitle: String,
        isCropped: Bool
    ) -> String {
        if isCropped {
            return text(
                "\(sourceTitle)の切り抜きを編集",
                "Edit the crop for \(sourceTitle)"
            )
        }
        return text(
            "\(sourceTitle)の表示範囲を切り抜く",
            "Choose the visible area of \(sourceTitle)"
        )
    }

    static func cropResetAccessibilityLabel(_ sourceTitle: String) -> String {
        text(
            "\(sourceTitle)を全体表示へ戻す下書きを開く",
            "Draft a full-source reset for \(sourceTitle)"
        )
    }

    static var cropResetAccessibilityHint: String {
        text(
            "切り抜きエディタを開きます。Stageは適用するまで変わりません。",
            "Opens the crop editor. The Stage does not change until you apply."
        )
    }

    static func cropAccessibilityValue(
        left: Int,
        top: Int,
        width: Int,
        height: Int
    ) -> String {
        text(
            "左\(left)パーセント、上\(top)パーセント、幅\(width)パーセント、高さ\(height)パーセント",
            "Left \(left) percent, top \(top) percent, width \(width) percent, height \(height) percent"
        )
    }

    static func stageInteractionModeName(_ mode: StageInteractionMode) -> String {
        switch mode {
        case .arrange: text("配置", "Arrange")
        case .crop: text("切り抜き", "Crop")
        case .annotate: text("手書き", "Draw")
        }
    }

    static func stageInteractionModeDetail(
        _ mode: StageInteractionMode,
        annotationTool: StageInkTool = .pen
    ) -> String {
        switch mode {
        case .arrange:
            text(
                "ソースの位置・大きさ・重なり順を編集します。",
                "Edit source position, size, and stacking order."
            )
        case .crop:
            text(
                "選択したソースの表示範囲を下書きします。Stageは適用まで変わりません。",
                "Draft the selected source crop. The Stage changes only when you apply it."
            )
        case .annotate:
            if annotationTool == .eraser {
                text(
                    "共有Stageのポインターを隠したまま、手書きを部分消去します。",
                    "Partially erase drawing while the shared Stage pointer stays hidden."
                )
            } else {
                text(
                    "共有Stageのポインターを隠して、線を描きます。",
                    "Hide the shared Stage pointer while drawing lines."
                )
            }
        }
    }
}
