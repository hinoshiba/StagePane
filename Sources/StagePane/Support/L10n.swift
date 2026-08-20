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

    static func stageInteractionModeName(_ mode: StageInteractionMode) -> String {
        switch mode {
        case .arrange: text("配置", "Arrange")
        case .control: text("ボタン操作", "Press Buttons")
        case .annotate: text("手書き", "Draw")
        }
    }

    static func stageInteractionModeDetail(_ mode: StageInteractionMode) -> String {
        switch mode {
        case .arrange:
            text(
                "ソースの位置・大きさ・重なり順を編集します。",
                "Edit source position, size, and stacking order."
            )
        case .control:
            text(
                "単一ウインドウ内の対応ボタンだけを押します。",
                "Press supported buttons only in a single-window source."
            )
        case .annotate:
            text(
                "共有Stageへ線を描きます。",
                "Draw lines on the shared Stage."
            )
        }
    }
}
