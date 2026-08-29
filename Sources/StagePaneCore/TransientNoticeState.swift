import Foundation

/// Identifies the one transient Workspace notice that may currently be shown.
///
/// Timed dismissal is asynchronous, so every presentation receives a fresh ID.
/// A stale timer or close action can then attempt to dismiss its own notice
/// without clearing a newer replacement, including one with identical text.
public struct TransientNoticeState: Equatable, Sendable {
    public struct Notice: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let message: String

        fileprivate init(id: UUID = UUID(), message: String) {
            self.id = id
            self.message = message
        }
    }

    public private(set) var notice: Notice?

    public init() {}

    @discardableResult
    public mutating func present(_ message: String) -> Notice {
        let notice = Notice(message: message)
        self.notice = notice
        return notice
    }

    /// Dismisses only the presentation that owns `id`.
    @discardableResult
    public mutating func dismiss(id: UUID) -> Bool {
        guard notice?.id == id else { return false }
        notice = nil
        return true
    }

    public mutating func dismissCurrent() {
        notice = nil
    }
}
