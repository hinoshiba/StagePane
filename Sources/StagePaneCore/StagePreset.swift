import Foundation

/// A stable, user-facing shape for the share stage.
///
/// The values are intentionally independent from AppKit so that sizing rules can
/// be tested without launching a window server session.
public enum StagePreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case widescreen
    case standard
    case portrait
    case square

    public var id: String { rawValue }

    public var pixelWidth: Int {
        switch self {
        case .widescreen: 1920
        case .standard: 1440
        case .portrait: 1080
        case .square: 1080
        }
    }

    public var pixelHeight: Int {
        switch self {
        case .widescreen: 1080
        case .standard: 1080
        case .portrait: 1920
        case .square: 1080
        }
    }

    public var aspectRatio: Double {
        Double(pixelWidth) / Double(pixelHeight)
    }

    /// A useful initial content size that fits on a laptop display.
    public var suggestedPointSize: (width: Double, height: Double) {
        let longestSide = 960.0
        if aspectRatio >= 1 {
            return (longestSide, longestSide / aspectRatio)
        }
        return (longestSide * aspectRatio * 0.76, longestSide * 0.76)
    }
}
