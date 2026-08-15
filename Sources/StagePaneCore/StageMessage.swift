import Foundation

public enum StageMessage {
    public static let characterLimit = 80

    public static func normalized(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.isEmpty ? fallback : trimmed
        return String(source.prefix(characterLimit))
    }
}
