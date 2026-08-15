import Foundation

public enum StageTheme: String, CaseIterable, Codable, Identifiable, Sendable {
    case aurora
    case midnight
    case paper
    case studio

    public var id: String { rawValue }
}
