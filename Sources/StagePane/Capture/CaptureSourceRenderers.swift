import CoreMedia
import Foundation
import StagePaneCore

/// Two zero-copy presentation surfaces fed by the same capture stream.
///
/// One surface belongs to the public Stage window. The other belongs to the
/// private layout preview in Workspace. Keeping them separate
/// avoids moving one CALayer between two windows while still reusing the same
/// ScreenCaptureKit IOSurface-backed sample buffer.
final class CaptureSourceRenderers: @unchecked Sendable {
    private struct PendingDeactivation: Sendable {
        let token: UUID
        let completion: (@Sendable () -> Void)?
    }

    let stage: SampleBufferRenderer
    let preview: SampleBufferRenderer
    private let renderQueue: DispatchQueue
    /// Accessed only on renderQueue. Each generation reopens only after both
    /// presentation surfaces report that their old displayed image is gone.
    private var presentationFlushCounts: [UUID: Int] = [:]
    /// Lifecycle teardown waits behind any in-flight presentation invalidation
    /// so a late, untracked flush can never erase a later reconnection frame.
    private var pendingDeactivations: [PendingDeactivation] = []

    init(renderQueue: DispatchQueue) {
        self.renderQueue = renderQueue
        self.stage = SampleBufferRenderer(renderQueue: renderQueue)
        self.preview = SampleBufferRenderer(renderQueue: renderQueue)
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

    func activate(
        token: UUID,
        showsCursor: Bool,
        presentationGeneration: UUID
    ) {
        stage.activate(
            token: token,
            showsCursor: showsCursor,
            presentationGeneration: presentationGeneration
        )
        preview.activate(
            token: token,
            showsCursor: showsCursor,
            presentationGeneration: presentationGeneration
        )
    }

    func deactivate(token: UUID, completion: (@Sendable () -> Void)? = nil) {
        let request = PendingDeactivation(token: token, completion: completion)
        renderQueue.async { [self] in
            guard presentationFlushCounts.isEmpty else {
                pendingDeactivations.append(request)
                return
            }
            performDeactivationOnRenderQueue(request)
        }
    }

    private func performDeactivationOnRenderQueue(
        _ request: PendingDeactivation
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        let token = request.token
        let completion = request.completion
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
        presentationGeneration: UUID
    ) {
        stage.enqueue(
            sampleBuffer,
            token: token,
            presentationGeneration: presentationGeneration
        )
        preview.enqueue(
            sampleBuffer,
            token: token,
            presentationGeneration: presentationGeneration
        )
    }

    /// Clears both public and private surfaces at one serial-queue boundary.
    func invalidatePresentationOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        if !presentationFlushCounts.isEmpty {
            // A prior remove-image flush already guarantees an empty surface.
            // Do not start overlapping uncancellable AVFoundation flushes;
            // advance both renderers to the newest empty generation and let the
            // existing paired barrier reopen it.
            advanceEmptyPresentationGenerationOnRenderQueue(
                token: token,
                presentationGeneration: presentationGeneration
            )
            return
        }
        presentationFlushCounts[presentationGeneration] = 2
        let didFlush: @Sendable () -> Void = { [weak self] in
            self?.completePresentationRendererFlushOnRenderQueue(
                token: token,
                presentationGeneration: presentationGeneration
            )
        }
        stage.invalidatePresentationOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration,
            completion: didFlush
        )
        preview.invalidatePresentationOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration,
            completion: didFlush
        )
    }

    private func completePresentationRendererFlushOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard let remaining = presentationFlushCounts[presentationGeneration] else { return }
        if remaining > 1 {
            presentationFlushCounts[presentationGeneration] = remaining - 1
            return
        }
        presentationFlushCounts.removeValue(forKey: presentationGeneration)
        stage.finishPresentationInvalidationOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration
        )
        preview.finishPresentationInvalidationOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration
        )
        drainPendingDeactivationsOnRenderQueue()
    }

    private func drainPendingDeactivationsOnRenderQueue() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard presentationFlushCounts.isEmpty,
              !pendingDeactivations.isEmpty else { return }
        let requests = pendingDeactivations
        pendingDeactivations.removeAll()
        for request in requests {
            performDeactivationOnRenderQueue(request)
        }
    }

    /// Moves both surfaces to a fresh, empty Resume generation. If Pause's
    /// old-image flush is still running, both surfaces reopen together only
    /// after that existing barrier completes.
    func advanceEmptyPresentationGenerationOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        stage.advanceEmptyPresentationGenerationOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration
        )
        preview.advanceEmptyPresentationGenerationOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration
        )
    }

}
