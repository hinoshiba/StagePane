/// Separates destructive layer removal from capture-session teardown.
/// Framework and system stops end access to pixels, but only an explicit
/// StagePane Remove or Stop All action is allowed to destroy editor state.
public enum CaptureLayerTeardownDisposition: Equatable, Sendable {
    case removeLayer
    case retainLayerForReselection
}

public enum CaptureBindingEndReason: CaseIterable, Equatable, Sendable {
    case userStoppedStream
    case streamFailure
    case contentUpdateFailure
    case configurationFailure
}

public enum CaptureLayerRetentionPolicy {
    public static func disposition(
        for reason: CaptureBindingEndReason,
        removalWasExplicitlyRequested: Bool
    ) -> CaptureLayerTeardownDisposition {
        switch reason {
        case .userStoppedStream,
             .streamFailure,
             .contentUpdateFailure,
             .configurationFailure:
            break
        }
        return removalWasExplicitlyRequested
            ? .removeLayer
            : .retainLayerForReselection
    }

    /// A failed `stopCapture` call does not change why teardown began. A
    /// reconnect may retry an unexpected/failure detach without destroying the
    /// logical layer; only a later explicit Remove or Stop All may upgrade the
    /// pending intent to removal.
    public static func dispositionAfterStopFailure(
        pendingDisposition: CaptureLayerTeardownDisposition?,
        removalWasExplicitlyRequested: Bool
    ) -> CaptureLayerTeardownDisposition? {
        guard let pendingDisposition else { return nil }
        return removalWasExplicitlyRequested
            ? .removeLayer
            : pendingDisposition
    }

    public static func canRetryRetainedTeardownAfterStopFailure(
        stopCaptureFailed: Bool,
        pendingDisposition: CaptureLayerTeardownDisposition?,
        removalWasExplicitlyRequested: Bool
    ) -> Bool {
        stopCaptureFailed && dispositionAfterStopFailure(
            pendingDisposition: pendingDisposition,
            removalWasExplicitlyRequested: removalWasExplicitlyRequested
        ) == .retainLayerForReselection
    }

    /// A retained layer is recoverable state, not a disposable global error.
    /// Keep Reset Capture for failures that have no logical layer to reconnect.
    public static func canResetCaptureFailure(
        captureIsActive: Bool,
        hasCaptureFailure: Bool,
        hasRetainedLayers: Bool
    ) -> Bool {
        !captureIsActive && hasCaptureFailure && !hasRetainedLayers
    }
}
