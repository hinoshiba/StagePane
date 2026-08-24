import Foundation

/// How the pointer is represented in the share stage.
public enum PointerStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case system = "system"
    case redDot = "redDot"
    case hidden = "hidden"

    public var id: String { rawValue }
    public var showsSystemCursor: Bool { self == .system }

    /// Resolves the current preference while preserving the behavior of builds
    /// that stored pointer visibility as a Boolean.
    public static func resolvePreference(
        storedRawValue: String?,
        legacyShowsCursor: Bool?
    ) -> PointerStyle {
        if let storedRawValue, let storedStyle = PointerStyle(rawValue: storedRawValue) {
            return storedStyle
        }
        return legacyShowsCursor == false ? .hidden : .system
    }
}
