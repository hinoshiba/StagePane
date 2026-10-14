import Foundation

public enum StageMessage {
    public static let characterLimit = 80
    public static let defaultTextSize = 100
    public static let textSizeRange = 50...200
    public static let textSizeStep = 25

    /// A percentage of the curtain's adaptive base font size, in coarse steps.
    public static func normalizedTextSize(_ value: Int) -> Int {
        let clamped = min(max(value, textSizeRange.lowerBound), textSizeRange.upperBound)
        return Int((Double(clamped) / Double(textSizeStep)).rounded()) * textSizeStep
    }

    public static func normalized(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.isEmpty ? fallback : trimmed
        return String(source.prefix(characterLimit))
    }
}
