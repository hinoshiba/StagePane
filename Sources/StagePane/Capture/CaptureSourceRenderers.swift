import CoreMedia
import Foundation
import StagePaneCore

/// Two zero-copy presentation surfaces fed by the same capture stream.
///
/// One surface belongs to the public Stage window. The other belongs to the
/// private, interactive layout preview in Control Room. Keeping them separate
/// avoids moving one CALayer between two windows while still reusing the same
/// ScreenCaptureKit IOSurface-backed sample buffer.
final class CaptureSourceRenderers: @unchecked Sendable {
    let stage: SampleBufferRenderer
    let preview: SampleBufferRenderer
    private let renderQueue: DispatchQueue

    init(renderQueue: DispatchQueue) {
        let usesSteppedPresentation: Bool
        #if STAGEPANE_APP_STORE
        usesSteppedPresentation = false
        #else
        if #available(macOS 15.2, *) {
            usesSteppedPresentation = true
        } else {
            usesSteppedPresentation = false
        }
        #endif
        self.renderQueue = renderQueue
        self.stage = SampleBufferRenderer(renderQueue: renderQueue)
        self.preview = SampleBufferRenderer(
            renderQueue: renderQueue,
            usesSteppedPresentation: usesSteppedPresentation
        )
    }

    func setPointerStyle(_ value: StagePaneCore.PointerStyle) {
        stage.setPointerStyle(value)
        preview.setPointerStyle(value)
    }

    func setPointerAppearance(_ value: PointerAppearance) {
        stage.setPointerAppearance(value)
        preview.setPointerAppearance(value)
    }

    func requestDeferredRedDot(token: UUID) {
        stage.requestDeferredRedDot(token: token)
        preview.requestDeferredRedDot(token: token)
    }

    /// Marks both presentation surfaces at the same native-cursor boundary in
    /// one serial-queue operation, then starts the ScreenCaptureKit update
    /// before another frame callback can run.
    func prepareCursorVisibilityTransition(
        token: UUID,
        targetShowsCursor: Bool,
        startConfigurationUpdate: @escaping @Sendable () -> Void
    ) {
        renderQueue.async { [self] in
            if targetShowsCursor {
                stage.prepareSystemCursorTransitionOnRenderQueue(token: token)
                preview.prepareSystemCursorTransitionOnRenderQueue(token: token)
            } else {
                stage.prepareRedDotTransitionOnRenderQueue(token: token)
                preview.prepareRedDotTransitionOnRenderQueue(token: token)
            }
            startConfigurationUpdate()
        }
    }

    func commitCursorlessConfiguration(token: UUID) {
        renderQueue.async { [self] in
            stage.commitCursorlessConfigurationOnRenderQueue(token: token)
            preview.commitCursorlessConfigurationOnRenderQueue(token: token)
        }
    }

    func commitSystemCursorConfiguration(token: UUID) {
        renderQueue.async { [self] in
            stage.commitSystemCursorConfigurationOnRenderQueue(token: token)
            preview.commitSystemCursorConfigurationOnRenderQueue(token: token)
        }
    }

    func cancelRedDotTransition(token: UUID) {
        renderQueue.async { [self] in
            stage.cancelRedDotTransitionOnRenderQueue(token: token)
            preview.cancelRedDotTransitionOnRenderQueue(token: token)
        }
    }

    func activate(token: UUID, showsCursor: Bool) {
        stage.activate(token: token, showsCursor: showsCursor)
        preview.activate(token: token, showsCursor: showsCursor)
    }

    func deactivate(token: UUID, completion: (@Sendable () -> Void)? = nil) {
        guard let completion else {
            stage.deactivate(token: token)
            preview.deactivate(token: token)
            return
        }

        let group = DispatchGroup()
        group.enter()
        stage.deactivate(token: token) {
            group.leave()
        }
        group.enter()
        preview.deactivate(token: token) {
            group.leave()
        }
        group.notify(queue: DispatchQueue.global(qos: .userInitiated), execute: completion)
    }

    func flush(completion: (@Sendable () -> Void)? = nil) {
        guard let completion else {
            stage.flush()
            preview.flush()
            return
        }

        let group = DispatchGroup()
        group.enter()
        stage.flush {
            group.leave()
        }
        group.enter()
        preview.flush {
            group.leave()
        }
        group.notify(queue: DispatchQueue.global(qos: .userInitiated), execute: completion)
    }

    func enqueue(
        _ sampleBuffer: CMSampleBuffer,
        token: UUID,
        filterGeneration: Int
    ) {
        stage.enqueue(
            sampleBuffer,
            token: token,
            filterGeneration: filterGeneration
        )
        preview.enqueue(
            sampleBuffer,
            token: token,
            filterGeneration: filterGeneration
        )
    }

    /// Serializes invalidation with frame delivery. The optional operation is
    /// started only after the old preview geometry can no longer be resolved.
    func suspendPreviewInteraction(
        reason: PreviewInteractionSuspensionReason,
        token: UUID,
        then operation: (@Sendable () -> Void)? = nil
    ) {
        renderQueue.async { [self] in
            preview.suspendInteractionOnRenderQueue(reason: reason, token: token)
            operation?()
        }
    }

    /// Used by SCStream callbacks and operation completions that have already
    /// been marshalled onto the shared stream-output/render queue.
    func suspendPreviewInteractionOnRenderQueue(
        reason: PreviewInteractionSuspensionReason,
        token: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        preview.suspendInteractionOnRenderQueue(reason: reason, token: token)
    }

    /// Removes a lifecycle blocker and, when this is the final blocker, records
    /// the host-time PTS boundary that later complete frames must cross.
    func resumePreviewInteractionOnRenderQueue(
        reason: PreviewInteractionSuspensionReason,
        token: UUID,
        filterGeneration: Int
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        preview.resumeInteractionOnRenderQueue(
            reason: reason,
            token: token,
            filterGeneration: filterGeneration
        )
    }
}
