/// A layer's user-chosen name, kept independently from its current capture
/// source so replacing or reconnecting that source does not discard the name.
public struct StageLayerName: Equatable, Sendable {
    public var defaultTitle: String
    public private(set) var customName: String?

    public var displayTitle: String { customName ?? defaultTitle }

    public init(defaultTitle: String, customName: String? = nil) {
        self.defaultTitle = defaultTitle
        self.customName = Self.normalized(customName ?? "")
    }

    /// Empty input restores the automatic source title. Names stay on one
    /// line, including when text containing line breaks is pasted into an editor.
    public mutating func rename(to value: String) {
        customName = Self.normalized(value)
    }

    private static func normalized(_ value: String) -> String? {
        let name = value.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return name.isEmpty ? nil : name
    }
}
