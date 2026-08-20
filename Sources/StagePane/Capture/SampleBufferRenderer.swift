import AppKit
import AVFoundation
import CoreImage
import CoreMedia
import ScreenCaptureKit
import StagePaneCore

private typealias PointerAvailabilityHandler = @MainActor @Sendable () -> Void

/// Owns the zero-copy display layer used by the public share stage.
///
/// `AVSampleBufferVideoRenderer` is the macOS 14 API intended for safely
/// enqueueing buffers away from the main thread. All renderer state and all
/// sample-buffer operations are confined to `renderQueue`; AppKit only touches
/// the layer hierarchy on the main thread.
final class SampleBufferRenderer: @unchecked Sendable {
    @MainActor
    private static let snapshotImageContext = CIContext(options: [
        .cacheIntermediates: false
    ])

    private struct PendingVideoFrame {
        let sampleBuffer: CMSampleBuffer
        let token: UUID
        let presentationGeneration: UUID
        /// Captured when ScreenCaptureKit delivers the frame, before a later
        /// configuration completion can change the stream's cursor state.
        let isConfirmedCursorless: Bool
        /// Only a frame received after this exact transition was committed may
        /// enable the overlay when the renderer eventually becomes ready.
        let qualifyingRedDotTransitionID: UUID?
    }

    private struct RedDotTransition {
        let id: UUID
        let token: UUID
        var isConfigurationCommitted = false
    }

    let displayLayer: AVSampleBufferDisplayLayer

    private let videoRenderer: AVSampleBufferVideoRenderer
    private let renderQueue: DispatchQueue
    /// Retains the exact complete frame most recently accepted by the live
    /// renderer. AppKit view caching does not rasterize
    /// `AVSampleBufferDisplayLayer`, so the Stage screenshot path converts
    /// this already-authorized source frame to an immutable `CGImage` only
    /// when the user asks for a screenshot.
    private let snapshotFrameLock = NSLock()
    private var snapshotPixelBuffer: CVPixelBuffer?
    /// Snapshot publication is fenced independently from the render queue so a
    /// teardown caller can revoke an in-flight callback before its queued token
    /// invalidation runs.
    private var snapshotToken: UUID?
    private var snapshotPresentationGeneration: UUID?
    private var rendererNotificationObservers: [NSObjectProtocol] = []
    private let pointerSnapshotLock = NSLock()
    private var desiredToken: UUID?
    private var activeToken: UUID?
    /// Accessed only on renderQueue. A retained callback or pending frame from
    /// an earlier source presentation must never repopulate a cleared surface.
    private var activePresentationGeneration: UUID?
    /// New-generation frames are retained, not enqueued, until both source
    /// renderers have completed removal of their previous displayed images.
    private var presentationFlushGeneration: UUID?
    /// A Resume may advance the presentation while an earlier remove-image
    /// flush is still running. The original generation continues to own that
    /// uncancellable completion; this records the newest generation that the
    /// completion may safely reopen afterward.
    private var deferredPresentationGenerationAfterFlush: UUID?
    /// Accessed only on renderQueue.
    private var redDotTransition: RedDotTransition?
    /// Accessed only on renderQueue. Real-time input keeps at most one frame.
    private var pendingVideoFrame: PendingVideoFrame?
    /// Accessed only on renderQueue.
    private var isRequestingMediaData = false
    /// Cursor state accepted by ScreenCaptureKit for newly delivered frames.
    /// Accessed only on renderQueue.
    private var nativeCursorIsHidden = false
    /// Whether the image currently enqueued in the layer was received after a
    /// cursorless configuration boundary. Accessed only on renderQueue.
    private var displayedFrameIsConfirmedCursorless = false
    /// Accessed only on renderQueue.
    private var latestPointerSnapshot: PointerOverlaySnapshot?
    /// Accessed only while holding pointerSnapshotLock.
    private var requestedPointerStyle: StagePaneCore.PointerStyle = .system
    /// Accessed only while holding pointerSnapshotLock. This is visual state
    /// only and deliberately does not participate in cursor-safety transitions.
    private var requestedPointerAppearance: PointerAppearance = .presentationDefault
    /// Accessed only while holding pointerSnapshotLock.
    private var requestedPointerToken: UUID?
    /// Accessed only while holding pointerSnapshotLock.
    private var deferredRedDotToken: UUID?
    /// Accessed only while holding pointerSnapshotLock.
    private var publishedPointerSnapshot: PointerOverlaySnapshot?
    /// Accessed only while holding pointerSnapshotLock.
    private var pointerAvailabilityHandler: PointerAvailabilityHandler?

    init(renderQueue: DispatchQueue) {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = NSColor.black.cgColor
        layer.preventsCapture = false

        let renderer = layer.sampleBufferRenderer
        self.displayLayer = layer
        self.videoRenderer = renderer
        self.renderQueue = renderQueue
        let notificationCenter = NotificationCenter.default
        rendererNotificationObservers = [
            notificationCenter.addObserver(
                forName: AVSampleBufferVideoRenderer.didFailToDecodeNotification,
                object: renderer,
                queue: nil
            ) { [weak self] _ in
                self?.rendererHealthDidChange()
            },
            notificationCenter.addObserver(
                forName: AVSampleBufferVideoRenderer
                    .requiresFlushToResumeDecodingDidChangeNotification,
                object: renderer,
                queue: nil
            ) { [weak self] _ in
                self?.rendererHealthDidChange()
            }
        ]
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        for observer in rendererNotificationObservers {
            notificationCenter.removeObserver(observer)
        }
    }

    @MainActor
    fileprivate func setPointerAvailabilityHandler(_ handler: PointerAvailabilityHandler?) {
        pointerSnapshotLock.lock()
        pointerAvailabilityHandler = handler
        pointerSnapshotLock.unlock()
        handler?()
    }

    func setPointerStyle(_ value: StagePaneCore.PointerStyle) {
        pointerSnapshotLock.lock()
        if value == .redDot, deferredRedDotToken != nil {
            pointerSnapshotLock.unlock()
            return
        }
        requestedPointerStyle = value
        deferredRedDotToken = nil
        var availabilityHandler: PointerAvailabilityHandler?
        if value != .redDot {
            availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        }
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)

        renderQueue.async { [self] in
            redDotTransition = nil
            publishPointerSnapshot(latestPointerSnapshot)
        }
    }

    func setPointerAppearance(_ value: PointerAppearance) {
        pointerSnapshotLock.lock()
        guard requestedPointerAppearance != value else {
            pointerSnapshotLock.unlock()
            return
        }
        requestedPointerAppearance = value
        let handler = pointerAvailabilityHandler
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: handler)
    }

    func pointerAppearance() -> PointerAppearance {
        pointerSnapshotLock.lock()
        let value = requestedPointerAppearance
        pointerSnapshotLock.unlock()
        return value
    }

    /// Records that an active stream should become red-dot mode without
    /// reusing its currently displayed frame. The coordinator follows this by
    /// either updating ScreenCaptureKit or committing an already-cursorless
    /// configuration. A proven cursorless displayed frame can be reused;
    /// otherwise the renderer waits for a later complete frame.
    func requestDeferredRedDot(token: UUID) {
        pointerSnapshotLock.lock()
        guard requestedPointerToken == token else {
            pointerSnapshotLock.unlock()
            return
        }
        requestedPointerStyle = .redDot
        deferredRedDotToken = token
        let availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)
    }

    /// Called on renderQueue immediately before the configuration update starts.
    func prepareRedDotTransitionOnRenderQueue(token: UUID) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        pointerSnapshotLock.lock()
        guard requestedPointerToken == token else {
            pointerSnapshotLock.unlock()
            return
        }
        if requestedPointerStyle == .redDot {
            deferredRedDotToken = token
        }
        pointerSnapshotLock.unlock()
        // Keep an already retained frame: it can still replace stale video,
        // but its missing transition ID prevents it from enabling the overlay.
        redDotTransition = RedDotTransition(id: UUID(), token: token)
    }

    /// Marks every frame delivered after a cursor-visible update begins as
    /// unsafe for red-dot reuse. The currently displayed cursorless proof is
    /// retained until an actual replacement frame is enqueued.
    func prepareSystemCursorTransitionOnRenderQueue(token: UUID) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token, desiredToken == token else { return }
        nativeCursorIsHidden = false
        if redDotTransition?.token == token { redDotTransition = nil }
    }

    /// Called on renderQueue after ScreenCaptureKit reports that a cursorless
    /// configuration was applied, or when red dot is requested while that
    /// configuration is already active. A previously confirmed cursorless image
    /// can be reused; otherwise only a later complete frame may enable the dot.
    func commitCursorlessConfigurationOnRenderQueue(token: UUID) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token, desiredToken == token else { return }
        nativeCursorIsHidden = true

        pointerSnapshotLock.lock()
        let wantsRedDot = requestedPointerToken == token &&
            requestedPointerStyle == .redDot &&
            deferredRedDotToken == token
        if !wantsRedDot, deferredRedDotToken == token {
            deferredRedDotToken = nil
        }
        pointerSnapshotLock.unlock()
        guard wantsRedDot else {
            if redDotTransition?.token == token { redDotTransition = nil }
            return
        }

        if displayedFrameIsConfirmedCursorless,
           pendingVideoFrame?.isConfirmedCursorless != false,
           latestPointerSnapshot?.token == token {
            if redDotTransition?.token == token { redDotTransition = nil }
            completeDeferredRedDotTransition(token: token)
            return
        }

        if var transition = redDotTransition, transition.token == token {
            transition.isConfigurationCommitted = true
            redDotTransition = transition
        } else {
            // The prepared transition can disappear during a rapid
            // Red Dot -> Off -> Red Dot sequence. Recreate a committed
            // generation and wait for the next complete frame rather than
            // enabling the overlay over a possibly native-cursor frame.
            redDotTransition = RedDotTransition(
                id: UUID(),
                token: token,
                isConfigurationCommitted: true
            )
        }
    }

    /// Records a successful cursor-visible configuration. Frames already
    /// delivered before this boundary keep their captured cursorless proof, but
    /// newly delivered frames are no longer eligible for a red-dot overlay.
    func commitSystemCursorConfigurationOnRenderQueue(token: UUID) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token, desiredToken == token else { return }
        nativeCursorIsHidden = false
        if redDotTransition?.token == token { redDotTransition = nil }
    }

    func cancelRedDotTransitionOnRenderQueue(token: UUID) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        if redDotTransition?.token == token { redDotTransition = nil }
        pointerSnapshotLock.lock()
        if deferredRedDotToken == token { deferredRedDotToken = nil }
        pointerSnapshotLock.unlock()
    }

    func pointerOverlaySnapshot(at globalPointer: CGPoint) -> PointerOverlayPosition? {
        pointerSnapshotLock.lock()
        let snapshot = publishedPointerSnapshot
        pointerSnapshotLock.unlock()

        guard let snapshot,
              let normalizedPosition = snapshot.geometry.normalizedPosition(
                  for: globalPointer
              ) else { return nil }
        return PointerOverlayPosition(
            normalizedPosition: normalizedPosition,
            surfaceSize: snapshot.geometry.surfacePointSize
        )
    }

    func shouldSamplePointerLocation() -> Bool {
        pointerSnapshotLock.lock()
        let shouldSample = publishedPointerSnapshot != nil
        pointerSnapshotLock.unlock()
        return shouldSample
    }

    /// Makes a stream's frames eligible for display. Initial activation uses an
    /// empty layer; every later activation follows a completed `deactivate`, so
    /// another asynchronous flush here would only create a frame-drop window.
    func activate(
        token: UUID,
        showsCursor: Bool,
        presentationGeneration: UUID
    ) {
        replaceSnapshotAcceptance(
            token: token,
            presentationGeneration: presentationGeneration,
            retainingFrame: false
        )
        pointerSnapshotLock.lock()
        requestedPointerToken = token
        deferredRedDotToken = nil
        let availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)
        renderQueue.async { [self] in
            clearPendingVideoFrameOnRenderQueue()
            desiredToken = token
            activeToken = token
            activePresentationGeneration = presentationGeneration
            presentationFlushGeneration = nil
            deferredPresentationGenerationAfterFlush = nil
            redDotTransition = nil
            nativeCursorIsHidden = !showsCursor
            displayedFrameIsConfirmedCursorless = false
            latestPointerSnapshot = nil
        }
    }

    /// Invalidates a stream before asynchronous ScreenCaptureKit teardown.
    /// The callback runs only after queued frame callbacks have drained and the
    /// displayed image has been removed.
    func deactivate(token: UUID, completion: (@Sendable () -> Void)? = nil) {
        revokeSnapshotAcceptance(token: token)
        pointerSnapshotLock.lock()
        var availabilityHandler: PointerAvailabilityHandler?
        if requestedPointerToken == token {
            requestedPointerToken = nil
            deferredRedDotToken = nil
            availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        }
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)
        renderQueue.async { [self] in
            if desiredToken == token { desiredToken = nil }
            if activeToken == token {
                activeToken = nil
                activePresentationGeneration = nil
                presentationFlushGeneration = nil
                deferredPresentationGenerationAfterFlush = nil
                displayedFrameIsConfirmedCursorless = false
                latestPointerSnapshot = nil
            }
            if redDotTransition?.token == token { redDotTransition = nil }
            clearPendingVideoFrameOnRenderQueue(token: token)
            // A callback that was already executing could race the synchronous
            // revocation above. Re-clear after queue-confined token invalidation.
            clearSnapshotFrame()
            videoRenderer.flush(removingDisplayedImage: true) {
                completion?()
            }
        }
    }

    func flush(completion: (@Sendable () -> Void)? = nil) {
        revokeAllSnapshotAcceptance()
        pointerSnapshotLock.lock()
        requestedPointerToken = nil
        deferredRedDotToken = nil
        let availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)
        renderQueue.async { [self] in
            desiredToken = nil
            activeToken = nil
            activePresentationGeneration = nil
            presentationFlushGeneration = nil
            deferredPresentationGenerationAfterFlush = nil
            redDotTransition = nil
            nativeCursorIsHidden = false
            displayedFrameIsConfirmedCursorless = false
            clearPendingVideoFrameOnRenderQueue()
            latestPointerSnapshot = nil
            clearSnapshotFrame()
            videoRenderer.flush(removingDisplayedImage: true) {
                completion?()
            }
        }
    }

    /// Fails a presentation closed while keeping the capture stream alive.
    /// Both display and screenshot state stay empty until a complete frame for
    /// this exact generation is accepted.
    func invalidatePresentationOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID,
        completion: @escaping @Sendable () -> Void
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token, desiredToken == token else {
            completion()
            return
        }
        activePresentationGeneration = presentationGeneration
        presentationFlushGeneration = presentationGeneration
        deferredPresentationGenerationAfterFlush = nil
        replaceSnapshotAcceptance(
            token: token,
            presentationGeneration: presentationGeneration,
            retainingFrame: false
        )
        clearPendingVideoFrameOnRenderQueue(token: token)
        displayedFrameIsConfirmedCursorless = false
        latestPointerSnapshot = nil
        clearPublishedPointerSnapshot(token: token)
        videoRenderer.flush(removingDisplayedImage: true) { [weak self] in
            self?.renderQueue.async(execute: completion)
        }
    }

    /// Called only after both display renderers have completed their old-image
    /// flush, so the public Stage and private preview reopen together.
    func finishPresentationInvalidationOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token,
              desiredToken == token,
              presentationFlushGeneration == presentationGeneration else { return }
        let generationToReopen =
            deferredPresentationGenerationAfterFlush ?? presentationGeneration
        presentationFlushGeneration = nil
        deferredPresentationGenerationAfterFlush = nil
        guard activePresentationGeneration == generationToReopen else {
            clearPendingVideoFrameOnRenderQueue(token: token)
            return
        }
        if pendingVideoFrame != nil {
            requestMediaDataWhenReadyIfNeeded()
        }
    }

    /// Resume keeps the intentionally paused image and screenshot, but moves
    /// every future publication to a new generation. Pointer proof is not
    /// retained because it describes the pre-resume frame.
    func advancePresentationGenerationPreservingFrameOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token, desiredToken == token else { return }
        activePresentationGeneration = presentationGeneration
        if presentationFlushGeneration != nil {
            // A regular presentation invalidation already owns an
            // uncancellable remove-image flush. Keep its original completion
            // identity, retain only the latest resumed frame, and reopen that
            // newer generation when the old flush actually completes.
            retagPendingVideoFrameOnRenderQueue(
                token: token,
                presentationGeneration: presentationGeneration
            )
            deferredPresentationGenerationAfterFlush = presentationGeneration
        } else {
            presentationFlushGeneration = nil
            deferredPresentationGenerationAfterFlush = nil
            clearPendingVideoFrameOnRenderQueue(token: token)
        }
        replaceSnapshotAcceptance(
            token: token,
            presentationGeneration: presentationGeneration,
            retainingFrame: true
        )
        latestPointerSnapshot = nil
        clearPublishedPointerSnapshot(token: token)
    }

    /// Called synchronously by a per-stream output proxy on `renderQueue`.
    /// Real-time input never grows a backlog: if AVF is temporarily not ready,
    /// only the newest complete frame is retained and drained when readiness
    /// returns. This matters for static sources that may send no later frame.
    func enqueue(
        _ sampleBuffer: CMSampleBuffer,
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token,
              activePresentationGeneration == presentationGeneration else { return }
        guard sampleBuffer.isValid,
              let attachments = frameAttachments(for: sampleBuffer),
              let status = frameStatus(in: attachments) else { return }

        guard status == .complete else {
            // An idle frame means the pixels did not change, so the most recent
            // geometry remains valid while the independent pointer ticker moves.
            // Pause lifecycle markers are also intentionally retained. Blank or
            // suspended content, however, must remove every presentation copy.
            if status == .blank || status == .suspended {
                invalidatePresentationOnRenderQueue(
                    token: token,
                    presentationGeneration: presentationGeneration
                ) { [weak self] in
                    self?.finishPresentationInvalidationOnRenderQueue(
                        token: token,
                        presentationGeneration: presentationGeneration
                    )
                }
            }
            return
        }

        let isConfirmedCursorless = nativeCursorIsHidden
        let qualifyingRedDotTransitionID = qualifyingRedDotTransitionID(for: token)
        let incomingVideoFrame = PendingVideoFrame(
            sampleBuffer: sampleBuffer,
            token: token,
            presentationGeneration: presentationGeneration,
            isConfirmedCursorless: isConfirmedCursorless,
            qualifyingRedDotTransitionID: qualifyingRedDotTransitionID
        )
        if presentationFlushGeneration != nil {
            pendingVideoFrame = incomingVideoFrame
            return
        }
        if videoRenderer.status == .failed || videoRenderer.requiresFlushToResumeDecoding {
            clearSnapshotFrame()
            displayedFrameIsConfirmedCursorless = false
            latestPointerSnapshot = nil
            clearPublishedPointerSnapshot(token: token)
            videoRenderer.flush()
        }
        if videoRenderer.isReadyForMoreMediaData {
            clearPendingVideoFrameOnRenderQueue()
            enqueueReadyFrame(
                sampleBuffer,
                token: token,
                presentationGeneration: presentationGeneration,
                isConfirmedCursorless: isConfirmedCursorless,
                qualifyingRedDotTransitionID: qualifyingRedDotTransitionID
            )
        } else {
            pendingVideoFrame = incomingVideoFrame
            requestMediaDataWhenReadyIfNeeded()
        }
    }

    private func requestMediaDataWhenReadyIfNeeded() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard !isRequestingMediaData,
              presentationFlushGeneration == nil,
              pendingVideoFrame != nil else { return }
        isRequestingMediaData = true
        videoRenderer.requestMediaDataWhenReady(on: renderQueue) { [weak self] in
            self?.drainPendingVideoFrameIfReady()
        }
    }

    private func drainPendingVideoFrameIfReady() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard isRequestingMediaData else { return }
        guard presentationFlushGeneration == nil else { return }
        guard let pendingVideoFrame else {
            clearPendingVideoFrameOnRenderQueue()
            return
        }
        guard activeToken == pendingVideoFrame.token,
              desiredToken == pendingVideoFrame.token,
              activePresentationGeneration ==
                pendingVideoFrame.presentationGeneration else {
            clearPendingVideoFrameOnRenderQueue(token: pendingVideoFrame.token)
            return
        }
        guard pendingVideoFrame.sampleBuffer.isValid else {
            clearPendingVideoFrameOnRenderQueue(token: pendingVideoFrame.token)
            clearSnapshotFrame()
            displayedFrameIsConfirmedCursorless = false
            latestPointerSnapshot = nil
            clearPublishedPointerSnapshot(token: pendingVideoFrame.token)
            return
        }
        if videoRenderer.status == .failed || videoRenderer.requiresFlushToResumeDecoding {
            clearSnapshotFrame()
            displayedFrameIsConfirmedCursorless = false
            latestPointerSnapshot = nil
            clearPublishedPointerSnapshot(token: pendingVideoFrame.token)
            videoRenderer.flush()
        }
        guard videoRenderer.isReadyForMoreMediaData else { return }
        self.pendingVideoFrame = nil
        enqueueReadyFrame(
            pendingVideoFrame.sampleBuffer,
            token: pendingVideoFrame.token,
            presentationGeneration: pendingVideoFrame.presentationGeneration,
            isConfirmedCursorless: pendingVideoFrame.isConfirmedCursorless,
            qualifyingRedDotTransitionID: pendingVideoFrame.qualifyingRedDotTransitionID
        )
        stopRequestingMediaDataOnRenderQueue()
    }

    private func enqueueReadyFrame(
        _ sampleBuffer: CMSampleBuffer,
        token: UUID,
        presentationGeneration: UUID,
        isConfirmedCursorless: Bool,
        qualifyingRedDotTransitionID: UUID?
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token,
              desiredToken == token,
              activePresentationGeneration == presentationGeneration else { return }
        videoRenderer.enqueue(sampleBuffer)
        publishSnapshotFrame(
            from: sampleBuffer,
            token: token,
            presentationGeneration: presentationGeneration
        )
        displayedFrameIsConfirmedCursorless = isConfirmedCursorless
        updatePointerSnapshot(for: sampleBuffer, token: token)
        guard let transition = redDotTransition,
              transition.token == token,
              transition.isConfigurationCommitted,
              (isConfirmedCursorless ||
                qualifyingRedDotTransitionID == transition.id) else { return }
        redDotTransition = nil
        completeDeferredRedDotTransition(token: token)
    }

    private func qualifyingRedDotTransitionID(for token: UUID) -> UUID? {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard let transition = redDotTransition,
              transition.token == token,
              transition.isConfigurationCommitted else { return nil }
        return transition.id
    }

    /// Notifications may arrive without another ScreenCaptureKit sample. Clear
    /// retained screenshot and pointer proof immediately when decoding becomes
    /// unhealthy; the next complete frame safely republishes both.
    private func rendererHealthDidChange() {
        renderQueue.async { [weak self] in
            guard let self,
                  videoRenderer.status == .failed ||
                    videoRenderer.requiresFlushToResumeDecoding else { return }
            if presentationFlushGeneration != nil {
                // Presentation invalidation already owns an uncancellable flush.
                // Preserve its newest pending frame for the generation barrier.
                clearSnapshotFrame()
                displayedFrameIsConfirmedCursorless = false
                latestPointerSnapshot = nil
                clearPublishedPointerSnapshot(token: activeToken)
                return
            }
            clearPendingVideoFrameOnRenderQueue()
            clearSnapshotFrame()
            displayedFrameIsConfirmedCursorless = false
            latestPointerSnapshot = nil
            clearPublishedPointerSnapshot(token: activeToken)
            videoRenderer.flush()
        }
    }

    private func updatePointerSnapshot(
        for sampleBuffer: CMSampleBuffer,
        token: UUID
    ) {
        guard let attachments = frameAttachments(for: sampleBuffer),
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let geometry = pointerGeometry(
                  from: attachments,
                  imageBuffer: imageBuffer
              ) else {
            latestPointerSnapshot = nil
            clearPublishedPointerSnapshot(token: token)
            return
        }
        let snapshot = PointerOverlaySnapshot(token: token, geometry: geometry)
        latestPointerSnapshot = snapshot
        publishPointerSnapshot(snapshot)
    }

    /// Returns an immutable copy suitable for a synchronous AppKit view
    /// snapshot. Reading is lock-backed because ScreenCaptureKit publishes
    /// frames on `renderQueue` while screenshot capture runs on the main actor.
    @MainActor
    fileprivate func makeBitmapSnapshotImage() -> CGImage? {
        snapshotFrameLock.lock()
        let pixelBuffer = snapshotPixelBuffer
        snapshotFrameLock.unlock()
        guard let pixelBuffer else { return nil }

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        guard !image.extent.isEmpty,
              image.extent.width.isFinite,
              image.extent.height.isFinite else { return nil }
        return Self.snapshotImageContext.createCGImage(image, from: image.extent)
    }

    private func publishSnapshotFrame(
        from sampleBuffer: CMSampleBuffer,
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        snapshotFrameLock.lock()
        if snapshotToken == token,
           snapshotPresentationGeneration == presentationGeneration {
            snapshotPixelBuffer = pixelBuffer
        }
        snapshotFrameLock.unlock()
    }

    private func replaceSnapshotAcceptance(
        token: UUID,
        presentationGeneration: UUID,
        retainingFrame: Bool
    ) {
        snapshotFrameLock.lock()
        snapshotToken = token
        snapshotPresentationGeneration = presentationGeneration
        if !retainingFrame { snapshotPixelBuffer = nil }
        snapshotFrameLock.unlock()
    }

    private func revokeSnapshotAcceptance(token: UUID) {
        snapshotFrameLock.lock()
        if snapshotToken == token {
            snapshotToken = nil
            snapshotPresentationGeneration = nil
            snapshotPixelBuffer = nil
        }
        snapshotFrameLock.unlock()
    }

    private func revokeAllSnapshotAcceptance() {
        snapshotFrameLock.lock()
        snapshotToken = nil
        snapshotPresentationGeneration = nil
        snapshotPixelBuffer = nil
        snapshotFrameLock.unlock()
    }

    private func clearSnapshotFrame() {
        snapshotFrameLock.lock()
        snapshotPixelBuffer = nil
        snapshotFrameLock.unlock()
    }

    private func retagPendingVideoFrameOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard let pendingVideoFrame, pendingVideoFrame.token == token else { return }
        self.pendingVideoFrame = PendingVideoFrame(
            sampleBuffer: pendingVideoFrame.sampleBuffer,
            token: token,
            presentationGeneration: presentationGeneration,
            isConfirmedCursorless: pendingVideoFrame.isConfirmedCursorless,
            qualifyingRedDotTransitionID: nil
        )
    }

    private func clearPendingVideoFrameOnRenderQueue(token: UUID? = nil) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        if token == nil || pendingVideoFrame?.token == token {
            pendingVideoFrame = nil
        }
        if pendingVideoFrame == nil {
            stopRequestingMediaDataOnRenderQueue()
        }
    }

    private func stopRequestingMediaDataOnRenderQueue() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard isRequestingMediaData else { return }
        videoRenderer.stopRequestingMediaData()
        isRequestingMediaData = false
    }

    /// Called on renderQueue after the target frame is enqueued.
    private func completeDeferredRedDotTransition(token: UUID) {
        pointerSnapshotLock.lock()
        guard deferredRedDotToken == token,
              requestedPointerToken == token,
              requestedPointerStyle == .redDot else {
            pointerSnapshotLock.unlock()
            return
        }
        deferredRedDotToken = nil
        requestedPointerStyle = .redDot
        pointerSnapshotLock.unlock()
        publishPointerSnapshot(latestPointerSnapshot)
    }

    private func frameAttachments(
        for sampleBuffer: CMSampleBuffer
    ) -> [SCStreamFrameInfo: Any]? {
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer,
            createIfNecessary: false
        ) as? [[SCStreamFrameInfo: Any]],
        let attachments = attachmentsArray.first else { return nil }
        return attachments
    }

    private func frameStatus(
        in attachments: [SCStreamFrameInfo: Any]
    ) -> SCFrameStatus? {
        guard
        let rawStatus = attachments[.status] as? Int,
        let status = SCFrameStatus(rawValue: rawStatus) else { return nil }
        return status
    }

    private func pointerGeometry(
        from attachments: [SCStreamFrameInfo: Any],
        imageBuffer: CVImageBuffer
    ) -> PointerFrameGeometry? {
        guard let screenRect = frameRect(attachments[.screenRect]),
              let contentRect = frameRect(attachments[.contentRect]),
              let scaleFactor = attachments[.scaleFactor] as? CGFloat,
              scaleFactor.isFinite,
              scaleFactor > 0 else { return nil }

        let surfacePointSize = CGSize(
            width: CGFloat(CVPixelBufferGetWidth(imageBuffer)) / scaleFactor,
            height: CGFloat(CVPixelBufferGetHeight(imageBuffer)) / scaleFactor
        )
        return PointerFrameGeometry(
            screenRect: screenRect,
            contentRect: contentRect,
            surfacePointSize: surfacePointSize,
            boundingRect: frameRect(attachments[.boundingRect])
        )
    }

    private func frameRect(_ value: Any?) -> CGRect? {
        guard let dictionary = value as? NSDictionary else { return nil }
        return CGRect(dictionaryRepresentation: dictionary)
    }

    private func publishPointerSnapshot(_ snapshot: PointerOverlaySnapshot?) {
        pointerSnapshotLock.lock()
        let availabilityHandler: PointerAvailabilityHandler?
        if requestedPointerStyle == .redDot,
           deferredRedDotToken == nil,
           snapshot?.token == requestedPointerToken {
            availabilityHandler = replacePublishedPointerSnapshotLocked(with: snapshot)
        } else {
            availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        }
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)
    }

    private func clearPublishedPointerSnapshot(token: UUID? = nil) {
        pointerSnapshotLock.lock()
        var availabilityHandler: PointerAvailabilityHandler?
        if token == nil || publishedPointerSnapshot?.token == token {
            availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        }
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)
    }

    /// Must be called while holding `pointerSnapshotLock`.
    private func replacePublishedPointerSnapshotLocked(
        with snapshot: PointerOverlaySnapshot?
    ) -> PointerAvailabilityHandler? {
        let availabilityChanged =
            (publishedPointerSnapshot == nil) != (snapshot == nil)
        publishedPointerSnapshot = snapshot
        return availabilityChanged ? pointerAvailabilityHandler : nil
    }

    private func notifyPointerAvailabilityChange(
        using handler: PointerAvailabilityHandler?
    ) {
        guard let handler else { return }
        Task { @MainActor in
            handler()
        }
    }
}

private struct PointerOverlaySnapshot: Sendable {
    let token: UUID
    let geometry: PointerFrameGeometry
}

struct PointerOverlayPosition: Sendable {
    let normalizedPosition: CGPoint
    let surfaceSize: CGSize
}

/// The minimal layer state changed while AppKit rasterizes a Stage screenshot.
/// The live display layer is never removed or reparented; restoration happens
/// synchronously on the main actor before the snapshot call returns.
@MainActor
struct SampleBufferBitmapSnapshotLayerState {
    let backingLayer: CALayer
    let displayLayer: AVSampleBufferDisplayLayer
    let previousContents: Any?
    let previousContentsGravity: CALayerContentsGravity
    let displayLayerWasHidden: Bool

    func restore() {
        backingLayer.contents = previousContents
        backingLayer.contentsGravity = previousContentsGravity
        displayLayer.isHidden = displayLayerWasHidden
    }
}

final class SampleBufferNSView: NSView {
    private let renderer: SampleBufferRenderer
    private let pointerDotLayer = CAShapeLayer()
    private var pointerTimer: Timer?
    /// The compositor grants pointer ownership to exactly one source view.
    /// This is independent of the renderer's cursor-safety state: inactive
    /// views keep receiving cursorless frames but never draw a local dot.
    private var isPointerOverlayEnabled = false
    private var pointerAppearance: PointerAppearance = .presentationDefault

    init(renderer: SampleBufferRenderer) {
        self.renderer = renderer
        super.init(frame: .zero)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.masksToBounds = true
        layer?.addSublayer(renderer.displayLayer)
        configurePointerDotLayer()
        layer?.addSublayer(pointerDotLayer)
        renderer.setPointerAvailabilityHandler { [weak self] in
            guard let self else { return }
            applyPointerAppearance(renderer.pointerAppearance())
            updatePointerTimerState()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        renderer.displayLayer.frame = bounds
        updatePointerOverlay()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateWindowStateObservers()
        if renderer.displayLayer.superlayer !== layer {
            renderer.displayLayer.removeFromSuperlayer()
            layer?.insertSublayer(renderer.displayLayer, at: 0)
        }
        if pointerDotLayer.superlayer !== layer {
            pointerDotLayer.removeFromSuperlayer()
            layer?.addSublayer(pointerDotLayer)
        }
        renderer.displayLayer.frame = bounds
        if window == nil {
            stopPointerTimer()
        } else {
            updatePointerTimerState()
        }
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        pointerDotLayer.contentsScale = window?.backingScaleFactor ?? 2
    }

    func setPointerOverlayEnabled(_ enabled: Bool) {
        guard isPointerOverlayEnabled != enabled else { return }
        isPointerOverlayEnabled = enabled
        if enabled {
            updatePointerTimerState()
        } else {
            stopPointerTimer()
        }
    }

    /// Prepares an immutable replacement for the media layer, which AppKit's
    /// `cacheDisplay(in:to:)` cannot rasterize directly.
    func makeBitmapSnapshotImage() -> CGImage? {
        renderer.makeBitmapSnapshotImage()
    }

    /// Installs the replacement behind existing pointer artwork. The caller
    /// owns one outer disabled-actions transaction and must restore the
    /// returned state in `defer` before yielding the main actor.
    func installBitmapSnapshotImage(
        _ image: CGImage
    ) -> SampleBufferBitmapSnapshotLayerState? {
        guard let backingLayer = layer else { return nil }
        let state = SampleBufferBitmapSnapshotLayerState(
            backingLayer: backingLayer,
            displayLayer: renderer.displayLayer,
            previousContents: backingLayer.contents,
            previousContentsGravity: backingLayer.contentsGravity,
            displayLayerWasHidden: renderer.displayLayer.isHidden
        )
        backingLayer.contents = image
        backingLayer.contentsGravity = .resizeAspect
        renderer.displayLayer.isHidden = true
        return state
    }

    private func configurePointerDotLayer() {
        pointerDotLayer.isHidden = true
        pointerDotLayer.contentsScale = 2
        applyPointerAppearance(.presentationDefault)
    }

    private func applyPointerAppearance(_ appearance: PointerAppearance) {
        guard pointerAppearance != appearance || pointerDotLayer.path == nil else { return }
        pointerAppearance = appearance

        let diameter = CGFloat(appearance.diameter)
        let lineWidth = max(1, diameter * 0.075)
        let inset = max(1, lineWidth * 0.65)
        let dotPath = CGPath(
            ellipseIn: CGRect(
                x: inset,
                y: inset,
                width: diameter - (inset * 2),
                height: diameter - (inset * 2)
            ),
            transform: nil
        )
        let color = NSColor(
            srgbRed: CGFloat(appearance.color.red),
            green: CGFloat(appearance.color.green),
            blue: CGFloat(appearance.color.blue),
            alpha: 1
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointerDotLayer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        pointerDotLayer.path = dotPath
        pointerDotLayer.fillColor = color.cgColor
        pointerDotLayer.strokeColor = NSColor.white.withAlphaComponent(0.74).cgColor
        pointerDotLayer.lineWidth = lineWidth
        pointerDotLayer.shadowPath = dotPath
        pointerDotLayer.shadowColor = color.cgColor
        pointerDotLayer.shadowOpacity = Float(appearance.glow * 0.88)
        pointerDotLayer.shadowRadius = diameter * CGFloat(0.10 + (appearance.glow * 0.28))
        pointerDotLayer.shadowOffset = .zero
        CATransaction.commit()
    }

    private func startPointerTimer() {
        guard isPointerOverlayEnabled, pointerTimer == nil else { return }
        let timer = Timer(
            timeInterval: 1.0 / 60.0,
            target: self,
            selector: #selector(pointerTimerDidFire),
            userInfo: nil,
            repeats: true
        )
        pointerTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        updatePointerOverlay()
    }

    private func updatePointerTimerState() {
        if isPointerOverlayEnabled,
           let window,
           window.isVisible,
           !window.isMiniaturized,
           !NSApp.isHidden,
           renderer.shouldSamplePointerLocation() {
            startPointerTimer()
        } else {
            stopPointerTimer()
        }
    }

    private func stopPointerTimer() {
        pointerTimer?.invalidate()
        pointerTimer = nil
        setPointerDotHidden(true)
    }

    @objc private func pointerTimerDidFire() {
        guard isPointerOverlayEnabled,
              let window,
              window.isVisible,
              !window.isMiniaturized,
              !NSApp.isHidden else {
            stopPointerTimer()
            return
        }
        updatePointerOverlay()
    }

    private func updateWindowStateObservers() {
        NotificationCenter.default.removeObserver(self)
        guard let window else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
        for name in [
            NSWindow.didBecomeKeyNotification,
            NSWindow.didMiniaturizeNotification,
            NSWindow.didDeminiaturizeNotification
        ] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowVisibilityDidChange(_:)),
                name: name,
                object: window
            )
        }
        for name in [NSApplication.didHideNotification, NSApplication.didUnhideNotification] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowVisibilityDidChange(_:)),
                name: name,
                object: NSApp
            )
        }
    }

    @objc private func windowWillClose(_ notification: Notification) {
        stopPointerTimer()
    }

    @objc private func windowVisibilityDidChange(_ notification: Notification) {
        updatePointerTimerState()
    }

    private func updatePointerOverlay() {
        guard isPointerOverlayEnabled,
              renderer.shouldSamplePointerLocation(),
              let globalPointer = CGEvent(source: nil)?.location,
              let overlay = renderer.pointerOverlaySnapshot(at: globalPointer),
              let stagePoint = PointerProjection.stagePoint(
                  normalizedPosition: overlay.normalizedPosition,
                  surfaceSize: overlay.surfaceSize,
                  stageSize: bounds.size
              ) else {
            setPointerDotHidden(true)
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointerDotLayer.position = CGPoint(
            x: stagePoint.x,
            y: bounds.height - stagePoint.y
        )
        pointerDotLayer.isHidden = false
        CATransaction.commit()
    }

    private func setPointerDotHidden(_ hidden: Bool) {
        guard pointerDotLayer.isHidden != hidden else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointerDotLayer.isHidden = hidden
        CATransaction.commit()
    }
}
