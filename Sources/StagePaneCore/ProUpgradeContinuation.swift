import Foundation

/// A purchase may resume its originating action only while that request is current.
public struct ProUpgradeContinuation: Sendable {
    public enum Action: Equatable, Sendable {
        case addSource
        case hideWatermark
    }

    public private(set) var generation = UUID()
    private var action: Action?
    private var receivedAccess = false

    public init() {}

    public mutating func begin(_ action: Action?) {
        generation = UUID()
        self.action = action
        receivedAccess = false
    }

    public mutating func cancel() {
        begin(nil)
    }

    public mutating func accessChanged(hasAccess: Bool, gainedAccess: Bool) {
        if !hasAccess {
            receivedAccess = false
        } else if gainedAccess, action != nil {
            receivedAccess = true
        }
    }

    public mutating func consume(
        generation expected: UUID,
        isIdle: Bool,
        contextIsValid: Bool
    ) -> Action? {
        guard expected == generation else { return nil }
        guard contextIsValid else {
            cancel()
            return nil
        }
        guard isIdle, receivedAccess, let action else { return nil }
        cancel()
        return action
    }
}
