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

    static var controlWindowTitle: String {
        usesJapanese ? WindowIdentity.controlJapaneseTitle : WindowIdentity.controlEnglishTitle
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
}
