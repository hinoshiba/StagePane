/// A snapshot of the capture lifecycle facts that decide whether one layer's
/// pixels may be presented.
///
/// `hasFreshFrame` records that a complete presentation candidate exists.
/// `awaitsFreshFrame` is the generation fence: it remains true until that
/// candidate belongs to the current presentation generation. Consequently, a
/// retained or stale frame may set `hasFreshFrame` without becoming visible.
public struct CapturePresentationVisibilityInput: Equatable, Sendable {
    public let outputSuppressed: Bool
    public let needsReselection: Bool
    public let isPaused: Bool
    public let isPauseTransitioning: Bool
    public let isStreamRunning: Bool
    public let awaitsFreshFrame: Bool
    public let hasFreshFrame: Bool

    public init(
        outputSuppressed: Bool,
        needsReselection: Bool,
        isPaused: Bool,
        isPauseTransitioning: Bool,
        isStreamRunning: Bool,
        awaitsFreshFrame: Bool,
        hasFreshFrame: Bool
    ) {
        self.outputSuppressed = outputSuppressed
        self.needsReselection = needsReselection
        self.isPaused = isPaused
        self.isPauseTransitioning = isPauseTransitioning
        self.isStreamRunning = isStreamRunning
        self.awaitsFreshFrame = awaitsFreshFrame
        self.hasFreshFrame = hasFreshFrame
    }
}

/// Fail-closed visibility shared by the Stage, private Workspace, pointer
/// overlay, crop editor, and explicit Audience image path.
public enum CapturePresentationVisibilityPolicy {
    /// A layer becomes visible only after capture is running and a complete
    /// frame for the current presentation generation has been accepted.
    /// Pause and Resume transitions remain transparent regardless of callback
    /// ordering.
    public static func shouldPresent(
        _ input: CapturePresentationVisibilityInput
    ) -> Bool {
        !input.outputSuppressed &&
            !input.needsReselection &&
            !input.isPaused &&
            !input.isPauseTransitioning &&
            input.isStreamRunning &&
            !input.awaitsFreshFrame &&
            input.hasFreshFrame
    }
}
