import Foundation

/// Queue-confined state for a fail-closed presentation geometry transition.
///
/// The context combines a monotonic revision with the capture token and
/// presentation generation. Every asynchronous AppKit acknowledgement must
/// match the complete context, so cancellation, replacement, and resume make
/// retained callbacks harmless.
public struct PresentationTransitionGate: Sendable {
    public struct Context: Equatable, Sendable {
        public let revision: UInt64
        public let token: UUID
        public let presentationGeneration: UUID
    }

    public enum Phase: Equatable, Sendable {
        case visible
        case suppressed
        case awaitingHide(Context)
        case hidden(Context)
        case awaitingShow(Context)
    }

    public private(set) var phase: Phase = .visible
    private var revision: UInt64 = 0

    public init() {}

    public var isVisible: Bool {
        phase == .visible
    }

    public var canRequestMediaData: Bool {
        switch phase {
        case .visible, .hidden:
            true
        case .suppressed, .awaitingHide, .awaitingShow:
            false
        }
    }

    @discardableResult
    public mutating func begin(
        token: UUID,
        presentationGeneration: UUID
    ) -> Context {
        revision &+= 1
        let context = Context(
            revision: revision,
            token: token,
            presentationGeneration: presentationGeneration
        )
        phase = .awaitingHide(context)
        return context
    }

    @discardableResult
    public mutating func acknowledgeHide(_ context: Context) -> Bool {
        guard phase == .awaitingHide(context) else { return false }
        phase = .hidden(context)
        return true
    }

    @discardableResult
    public mutating func beginShow(_ context: Context) -> Bool {
        guard phase == .hidden(context) else { return false }
        phase = .awaitingShow(context)
        return true
    }

    @discardableResult
    public mutating func acknowledgeShow(_ context: Context) -> Bool {
        guard phase == .awaitingShow(context) else { return false }
        phase = .visible
        return true
    }

    @discardableResult
    public mutating func suppress(_ context: Context) -> Bool {
        guard phase == .hidden(context) ||
                phase == .awaitingShow(context) else { return false }
        phase = .suppressed
        return true
    }

    public mutating func cancel() {
        // Advance even when already visible so an acknowledgement retained by
        // a previous lifecycle can never equal the next transition context.
        revision &+= 1
        phase = .visible
    }
}
