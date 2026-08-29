import AppKit
import AVFoundation
import CoreImage
import CoreMedia
import QuartzCore
import ScreenCaptureKit
import StagePaneCore

private typealias PointerAvailabilityHandler = @MainActor @Sendable () -> Void

/// A monotonic presentation state delivered to AppKit consumers. Geometry is
/// nil while the renderer is intentionally fail-closed. Consumers retain the
/// revision so a delayed MainActor task from an older frame cannot make a
/// source visible again after a newer suppression boundary.
struct PresentationGeometryUpdate: Sendable {
    let revision: UInt64
    let geometry: SourcePresentationGeometry?
}

typealias PresentationGeometryHandler = @MainActor @Sendable (
    PresentationGeometryUpdate
) -> Void

/// Owns the zero-copy display layer used by the public share stage.
///
/// `AVSampleBufferVideoRenderer` is the macOS 14 API intended for safely
/// enqueueing buffers away from the main thread. All renderer state and all
/// sample-buffer operations are confined to `renderQueue`; AppKit only touches
/// the layer hierarchy on the main thread.
final class SampleBufferRenderer: @unchecked Sendable {
    private typealias GeometryTransitionContext =
        PresentationTransitionGate.Context

    @MainActor
    private static let snapshotImageContext = CIContext(options: [
        .cacheIntermediates: false
    ])

    private struct PendingVideoFrame {
        let sampleBuffer: CMSampleBuffer
        let token: UUID
        let presentationGeneration: UUID
        let presentationGeometry: SourcePresentationGeometry
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
    /// Geometry for the same accepted frame as `snapshotPixelBuffer`. Keeping
    /// the pair under one lock prevents a crop view from combining a new
    /// IOSurface layout with pixels retained from an older presentation.
    private var snapshotPresentationGeometry: SourcePresentationGeometry?
    /// False between geometry publication and the MainActor crop-layout
    /// acknowledgement. Audience PNG must not use or reveal that frame early.
    private var snapshotPresentationIsAcknowledged = false
    /// Incremented under `snapshotFrameLock` for every published geometry or
    /// suppression boundary, including lifecycle changes that are already nil.
    private var snapshotPresentationRevision: UInt64 = 0
    /// Snapshot publication is fenced independently from the render queue so a
    /// teardown caller can revoke an in-flight callback before its queued token
    /// invalidation runs.
    private var snapshotToken: UUID?
    private var snapshotPresentationGeneration: UUID?
    private let presentationGeometryObserverLock = NSLock()
    private var presentationGeometryObservers: [UUID: PresentationGeometryHandler] = [:]
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
    /// Resume can advance to a fresh empty generation while Pause's
    /// remove-image flush is still in flight. The original generation keeps
    /// ownership of that uncancellable completion and reopens only this newer
    /// generation afterward.
    private var deferredPresentationGenerationAfterFlush: UUID?
    /// A decoder-health reset preserves the displayed image and presentation
    /// geometry. Frames arriving before its asynchronous completion replace
    /// `pendingVideoFrame`, so recovery drains only the newest complete frame.
    private var rendererRecoveryFlushID: UUID?
    /// Accessed only on renderQueue.
    private var redDotTransition: RedDotTransition?
    /// Accessed only on renderQueue. Real-time input keeps at most one frame.
    private var pendingVideoFrame: PendingVideoFrame?
    /// Accessed only on renderQueue.
    private var geometryTransitionGate = PresentationTransitionGate()
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
        layer.backgroundColor = NSColor.clear.cgColor
        layer.isOpaque = false
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

    /// Multiple views and the coordinator can independently follow the exact
    /// geometry accepted by this renderer. Observers are always invoked on the
    /// main actor; the current value is delivered immediately on registration.
    @MainActor
    @discardableResult
    func addPresentationGeometryObserver(
        _ observer: @escaping PresentationGeometryHandler
    ) -> UUID {
        let id = UUID()
        presentationGeometryObserverLock.lock()
        presentationGeometryObservers[id] = observer
        presentationGeometryObserverLock.unlock()
        observer(presentationGeometryUpdate())
        return id
    }

    func removePresentationGeometryObserver(_ id: UUID) {
        presentationGeometryObserverLock.lock()
        presentationGeometryObservers.removeValue(forKey: id)
        presentationGeometryObserverLock.unlock()
    }

    /// A lock-backed snapshot suitable for synchronizing a main-thread layout
    /// before a queued observer notification has run.
    func presentationGeometry() -> SourcePresentationGeometry? {
        snapshotFrameLock.lock()
        let geometry = snapshotPresentationGeometry
        snapshotFrameLock.unlock()
        return geometry
    }

    private func presentationGeometryUpdate() -> PresentationGeometryUpdate {
        snapshotFrameLock.lock()
        let update = PresentationGeometryUpdate(
            revision: snapshotPresentationRevision,
            geometry: snapshotPresentationGeometry
        )
        snapshotFrameLock.unlock()
        return update
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
            presentationGeneration: presentationGeneration
        )
        pointerSnapshotLock.lock()
        requestedPointerToken = token
        deferredRedDotToken = nil
        let availabilityHandler = replacePublishedPointerSnapshotLocked(with: nil)
        pointerSnapshotLock.unlock()
        notifyPointerAvailabilityChange(using: availabilityHandler)
        renderQueue.async { [self] in
            cancelGeometryTransitionOnRenderQueue()
            clearPendingVideoFrameOnRenderQueue()
            desiredToken = token
            activeToken = token
            activePresentationGeneration = presentationGeneration
            presentationFlushGeneration = nil
            deferredPresentationGenerationAfterFlush = nil
            rendererRecoveryFlushID = nil
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
            cancelGeometryTransitionOnRenderQueue()
            if desiredToken == token { desiredToken = nil }
            if activeToken == token {
                activeToken = nil
                activePresentationGeneration = nil
                presentationFlushGeneration = nil
                deferredPresentationGenerationAfterFlush = nil
                rendererRecoveryFlushID = nil
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
            cancelGeometryTransitionOnRenderQueue()
            desiredToken = nil
            activeToken = nil
            activePresentationGeneration = nil
            presentationFlushGeneration = nil
            deferredPresentationGenerationAfterFlush = nil
            rendererRecoveryFlushID = nil
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
        cancelGeometryTransitionOnRenderQueue()
        activePresentationGeneration = presentationGeneration
        presentationFlushGeneration = presentationGeneration
        deferredPresentationGenerationAfterFlush = nil
        rendererRecoveryFlushID = nil
        replaceSnapshotAcceptance(
            token: token,
            presentationGeneration: presentationGeneration
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

    /// Advances Resume to a new, still-empty generation without starting a
    /// second remove-image flush. Pause already removed (or is removing) the
    /// old image; complete frames for this generation remain pending until that
    /// original flush barrier has finished.
    func advanceEmptyPresentationGenerationOnRenderQueue(
        token: UUID,
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == token, desiredToken == token else { return }
        cancelGeometryTransitionOnRenderQueue()
        activePresentationGeneration = presentationGeneration
        clearPendingVideoFrameOnRenderQueue(token: token)
        if presentationFlushGeneration != nil {
            deferredPresentationGenerationAfterFlush = presentationGeneration
        } else {
            deferredPresentationGenerationAfterFlush = nil
        }
        replaceSnapshotAcceptance(
            token: token,
            presentationGeneration: presentationGeneration
        )
        displayedFrameIsConfirmedCursorless = false
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
            // Non-pixel lifecycle markers are ignored; explicit Pause performs
            // its own generation invalidation before stopping the stream. Blank
            // or suspended content must remove every presentation copy.
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
        guard let presentationGeometry = CMSampleBufferGetImageBuffer(sampleBuffer).flatMap({
            sourcePresentationGeometry(from: sampleBuffer, imageBuffer: $0)
        }) else {
            // A malformed complete callback has no trustworthy crop geometry.
            // Drop only that callback: the previously accepted, picker-approved
            // frame remains safe and may be the only image a static source sends.
            return
        }
        let incomingVideoFrame = PendingVideoFrame(
            sampleBuffer: sampleBuffer,
            token: token,
            presentationGeneration: presentationGeneration,
            presentationGeometry: presentationGeometry,
            isConfirmedCursorless: isConfirmedCursorless,
            qualifyingRedDotTransitionID: qualifyingRedDotTransitionID
        )
        if presentationFlushGeneration != nil {
            pendingVideoFrame = incomingVideoFrame
            return
        }
        if rendererRecoveryFlushID != nil {
            pendingVideoFrame = incomingVideoFrame
            return
        }
        if case .suppressed = geometryTransitionGate.phase {
            beginGeometryTransition(with: incomingVideoFrame)
            return
        }
        if !geometryTransitionGate.isVisible {
            pendingVideoFrame = incomingVideoFrame
            if case .hidden = geometryTransitionGate.phase {
                drainHiddenGeometryTransitionIfReady()
            }
            return
        }
        if videoRenderer.status == .failed || videoRenderer.requiresFlushToResumeDecoding {
            pendingVideoFrame = incomingVideoFrame
            beginRendererRecoveryOnRenderQueue(pointerToken: token)
            return
        }
        if videoRenderer.isReadyForMoreMediaData {
            clearPendingVideoFrameOnRenderQueue()
            enqueueOrBeginGeometryTransition(incomingVideoFrame)
        } else {
            pendingVideoFrame = incomingVideoFrame
            requestMediaDataWhenReadyIfNeeded()
        }
    }

    private func requestMediaDataWhenReadyIfNeeded() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard !isRequestingMediaData,
              presentationFlushGeneration == nil,
              rendererRecoveryFlushID == nil,
              pendingVideoFrame != nil,
              geometryTransitionGate.canRequestMediaData else { return }
        isRequestingMediaData = true
        videoRenderer.requestMediaDataWhenReady(on: renderQueue) { [weak self] in
            self?.drainPendingVideoFrameIfReady()
        }
    }

    private func drainPendingVideoFrameIfReady() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard isRequestingMediaData else { return }
        guard presentationFlushGeneration == nil else { return }
        guard rendererRecoveryFlushID == nil else { return }
        guard geometryTransitionGate.canRequestMediaData else {
            stopRequestingMediaDataOnRenderQueue()
            return
        }
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
            displayedFrameIsConfirmedCursorless = false
            latestPointerSnapshot = nil
            clearPublishedPointerSnapshot(token: pendingVideoFrame.token)
            return
        }
        if videoRenderer.status == .failed || videoRenderer.requiresFlushToResumeDecoding {
            beginRendererRecoveryOnRenderQueue(
                pointerToken: pendingVideoFrame.token
            )
            return
        }
        guard videoRenderer.isReadyForMoreMediaData else { return }
        self.pendingVideoFrame = nil
        stopRequestingMediaDataOnRenderQueue()
        if case .hidden(let context) = geometryTransitionGate.phase {
            acceptFrameAfterGeometryHide(pendingVideoFrame, context: context)
        } else {
            enqueueOrBeginGeometryTransition(pendingVideoFrame)
        }
    }

    private func enqueueOrBeginGeometryTransition(_ frame: PendingVideoFrame) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard geometryTransitionGate.isVisible else {
            pendingVideoFrame = frame
            return
        }
        guard presentationGeometry() == frame.presentationGeometry else {
            beginGeometryTransition(with: frame)
            return
        }
        enqueueReadyFrame(frame)
    }

    private func beginGeometryTransition(with frame: PendingVideoFrame) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == frame.token,
              desiredToken == frame.token,
              activePresentationGeneration == frame.presentationGeneration else { return }
        let context = geometryTransitionGate.begin(
            token: frame.token,
            presentationGeneration: frame.presentationGeneration
        )
        pendingVideoFrame = frame
        stopRequestingMediaDataOnRenderQueue()

        // The old video may remain in AVFoundation until AppKit confirms that
        // the complete crop wrapper is hidden. Clear every other publication
        // now so neither screenshots nor a laser can bridge the transition.
        latestPointerSnapshot = nil
        clearPublishedPointerSnapshot(token: frame.token)
        let suppression = suppressSnapshotFrameForGeometryTransition()
        notifyPresentationGeometryObservers(
            with: suppression,
            completion: { [weak self] in
                self?.finishGeometryHideOnRenderQueue(context: context)
            }
        )
    }

    private func finishGeometryHideOnRenderQueue(
        context: GeometryTransitionContext
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == context.token,
              desiredToken == context.token,
              activePresentationGeneration == context.presentationGeneration,
              geometryTransitionGate.acknowledgeHide(context) else { return }
        drainHiddenGeometryTransitionIfReady()
    }

    private func drainHiddenGeometryTransitionIfReady() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard case .hidden(let context) = geometryTransitionGate.phase,
              presentationFlushGeneration == nil,
              rendererRecoveryFlushID == nil,
              let frame = pendingVideoFrame else { return }
        guard frame.token == context.token,
              frame.presentationGeneration == context.presentationGeneration,
              activeToken == frame.token,
              desiredToken == frame.token,
              activePresentationGeneration == frame.presentationGeneration else {
            cancelGeometryTransitionOnRenderQueue()
            clearPendingVideoFrameOnRenderQueue(token: frame.token)
            return
        }
        guard frame.sampleBuffer.isValid else {
            cancelGeometryTransitionOnRenderQueue()
            clearPendingVideoFrameOnRenderQueue(token: frame.token)
            return
        }
        if videoRenderer.status == .failed || videoRenderer.requiresFlushToResumeDecoding {
            beginRendererRecoveryOnRenderQueue(pointerToken: frame.token)
            return
        }
        guard videoRenderer.isReadyForMoreMediaData else {
            requestMediaDataWhenReadyIfNeeded()
            return
        }
        pendingVideoFrame = nil
        stopRequestingMediaDataOnRenderQueue()
        acceptFrameAfterGeometryHide(frame, context: context)
    }

    private func acceptFrameAfterGeometryHide(
        _ frame: PendingVideoFrame,
        context: GeometryTransitionContext
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard geometryTransitionGate.phase == .hidden(context) else {
            pendingVideoFrame = frame
            return
        }
        enqueueReadyFrame(frame, geometryTransitionContext: context)
    }

    private func finishGeometryShowOnRenderQueue(
        context: GeometryTransitionContext
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == context.token,
              desiredToken == context.token,
              activePresentationGeneration == context.presentationGeneration,
              geometryTransitionGate.phase == .awaitingShow(context) else { return }
        guard acknowledgeSnapshotPresentation(context: context) else {
            _ = geometryTransitionGate.suppress(context)
            clearPendingVideoFrameOnRenderQueue(token: context.token)
            return
        }
        guard geometryTransitionGate.acknowledgeShow(context) else { return }
        // The frame that completed this geometry transition may remain visible
        // during a decoder recovery, but no newer pending frame may enter AVF
        // until that uncancellable flush has completed. Recovery completion
        // restarts the normal latest-frame drain once this phase is visible.
        guard rendererRecoveryFlushID == nil else { return }
        guard let pendingVideoFrame else { return }
        guard pendingVideoFrame.token == context.token,
              pendingVideoFrame.presentationGeneration == context.presentationGeneration else {
            clearPendingVideoFrameOnRenderQueue(token: pendingVideoFrame.token)
            return
        }
        if videoRenderer.isReadyForMoreMediaData {
            self.pendingVideoFrame = nil
            enqueueOrBeginGeometryTransition(pendingVideoFrame)
        } else {
            requestMediaDataWhenReadyIfNeeded()
        }
    }

    private func cancelGeometryTransitionOnRenderQueue() {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        geometryTransitionGate.cancel()
    }

    private func acknowledgeSnapshotPresentation(
        context: GeometryTransitionContext
    ) -> Bool {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        snapshotFrameLock.lock()
        let mayAcknowledge = snapshotToken == context.token &&
            snapshotPresentationGeneration == context.presentationGeneration &&
            snapshotPixelBuffer != nil && snapshotPresentationGeometry != nil
        if mayAcknowledge {
            snapshotPresentationIsAcknowledged = true
        }
        snapshotFrameLock.unlock()
        return mayAcknowledge
    }

    private func enqueueReadyFrame(
        _ frame: PendingVideoFrame,
        geometryTransitionContext: GeometryTransitionContext? = nil
    ) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard activeToken == frame.token,
              desiredToken == frame.token,
              activePresentationGeneration == frame.presentationGeneration else { return }
        videoRenderer.enqueue(frame.sampleBuffer)
        displayedFrameIsConfirmedCursorless = frame.isConfirmedCursorless
        // Pointer proof belongs to the same frame as the geometry publication.
        // Populate or clear it before a MainActor observer can reveal the view.
        updatePointerSnapshot(for: frame.sampleBuffer, token: frame.token)
        let geometryUpdate = publishSnapshotFrame(
            from: frame.sampleBuffer,
            geometry: frame.presentationGeometry,
            token: frame.token,
            presentationGeneration: frame.presentationGeneration,
            forceGeometryNotification: geometryTransitionContext != nil
        )
        if let geometryTransitionContext {
            guard geometryTransitionGate.beginShow(
                geometryTransitionContext
            ) else { return }
            let update = geometryUpdate ?? presentationGeometryUpdate()
            notifyPresentationGeometryObservers(
                with: update,
                completion: { [weak self] in
                    self?.finishGeometryShowOnRenderQueue(
                        context: geometryTransitionContext
                    )
                }
            )
        } else if let geometryUpdate {
            notifyPresentationGeometryObservers(with: geometryUpdate)
        }
        guard let transition = redDotTransition,
              transition.token == frame.token,
              transition.isConfigurationCommitted,
              (frame.isConfirmedCursorless ||
                frame.qualifyingRedDotTransitionID == transition.id) else { return }
        redDotTransition = nil
        completeDeferredRedDotTransition(token: frame.token)
    }

    private func qualifyingRedDotTransitionID(for token: UUID) -> UUID? {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard let transition = redDotTransition,
              transition.token == token,
              transition.isConfigurationCommitted else { return nil }
        return transition.id
    }

    /// Notifications may arrive without another ScreenCaptureKit sample. A
    /// renderer reset is not a capture-authorization boundary, so preserve the
    /// displayed image, matching screenshot geometry, and newest pending frame.
    /// Static sources may emit only idle callbacks after this point. Pointer
    /// proof is revoked independently until a later complete frame refreshes it.
    private func rendererHealthDidChange() {
        renderQueue.async { [weak self] in
            guard let self,
                  videoRenderer.status == .failed ||
                    videoRenderer.requiresFlushToResumeDecoding else { return }
            if presentationFlushGeneration != nil {
                // Presentation invalidation already owns an uncancellable flush.
                // Its fail-closed boundary and newest pending frame remain in
                // charge; do not start a competing renderer reset.
                displayedFrameIsConfirmedCursorless = false
                latestPointerSnapshot = nil
                clearPublishedPointerSnapshot(token: activeToken)
                return
            }
            beginRendererRecoveryOnRenderQueue(pointerToken: activeToken)
        }
    }

    /// Resets decoder state without treating it as a capture or presentation
    /// invalidation. The displayed image and its acknowledged snapshot geometry
    /// remain valid because the picker-authorized source has not changed.
    private func beginRendererRecoveryOnRenderQueue(pointerToken: UUID?) {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard presentationFlushGeneration == nil,
              rendererRecoveryFlushID == nil else { return }

        displayedFrameIsConfirmedCursorless = false
        latestPointerSnapshot = nil
        clearPublishedPointerSnapshot(token: pointerToken)
        stopRequestingMediaDataOnRenderQueue()

        let recoveryID = UUID()
        rendererRecoveryFlushID = recoveryID
        videoRenderer.flush(removingDisplayedImage: false) { [weak self] in
            self?.renderQueue.async { [weak self] in
                guard let self,
                      rendererRecoveryFlushID == recoveryID else { return }
                rendererRecoveryFlushID = nil
                if pendingVideoFrame != nil {
                    requestMediaDataWhenReadyIfNeeded()
                }
            }
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
    fileprivate func makeBitmapSnapshotImage(
        synchronizeGeometry: (SourcePresentationGeometry?) -> Void
    ) -> CGImage? {
        snapshotFrameLock.lock()
        let pixelBuffer = snapshotPixelBuffer
        let geometry = snapshotPresentationGeometry
        let isPresentationAcknowledged = snapshotPresentationIsAcknowledged
        snapshotFrameLock.unlock()
        guard isPresentationAcknowledged, let pixelBuffer else { return nil }
        // Apply the geometry copied in the same critical section as the pixel
        // buffer. The synchronous Stage snapshot then rasterizes one coherent
        // accepted frame even if the render queue advances again meanwhile.
        synchronizeGeometry(geometry)

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        guard !image.extent.isEmpty,
              image.extent.width.isFinite,
              image.extent.height.isFinite else { return nil }
        return Self.snapshotImageContext.createCGImage(image, from: image.extent)
    }

    private func publishSnapshotFrame(
        from sampleBuffer: CMSampleBuffer,
        geometry: SourcePresentationGeometry?,
        token: UUID,
        presentationGeneration: UUID,
        forceGeometryNotification: Bool
    ) -> PresentationGeometryUpdate? {
        dispatchPrecondition(condition: .onQueue(renderQueue))
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        snapshotFrameLock.lock()
        var update: PresentationGeometryUpdate?
        if snapshotToken == token,
           snapshotPresentationGeneration == presentationGeneration {
            snapshotPixelBuffer = pixelBuffer
            let geometryChanged = snapshotPresentationGeometry != geometry
            snapshotPresentationGeometry = geometry
            if forceGeometryNotification {
                snapshotPresentationIsAcknowledged = false
            }
            if geometryChanged || forceGeometryNotification {
                snapshotPresentationRevision &+= 1
                update = PresentationGeometryUpdate(
                    revision: snapshotPresentationRevision,
                    geometry: geometry
                )
            }
        }
        snapshotFrameLock.unlock()
        return update
    }

    private func replaceSnapshotAcceptance(
        token: UUID,
        presentationGeneration: UUID
    ) {
        snapshotFrameLock.lock()
        snapshotToken = token
        snapshotPresentationGeneration = presentationGeneration
        snapshotPixelBuffer = nil
        snapshotPresentationGeometry = nil
        snapshotPresentationIsAcknowledged = false
        snapshotPresentationRevision &+= 1
        let update = PresentationGeometryUpdate(
            revision: snapshotPresentationRevision,
            geometry: nil
        )
        snapshotFrameLock.unlock()
        notifyPresentationGeometryObservers(with: update)
    }

    private func revokeSnapshotAcceptance(token: UUID) {
        snapshotFrameLock.lock()
        var update: PresentationGeometryUpdate?
        if snapshotToken == token {
            snapshotToken = nil
            snapshotPresentationGeneration = nil
            snapshotPixelBuffer = nil
            snapshotPresentationGeometry = nil
            snapshotPresentationIsAcknowledged = false
            snapshotPresentationRevision &+= 1
            update = PresentationGeometryUpdate(
                revision: snapshotPresentationRevision,
                geometry: nil
            )
        }
        snapshotFrameLock.unlock()
        if let update {
            notifyPresentationGeometryObservers(with: update)
        }
    }

    private func revokeAllSnapshotAcceptance() {
        snapshotFrameLock.lock()
        snapshotToken = nil
        snapshotPresentationGeneration = nil
        snapshotPixelBuffer = nil
        snapshotPresentationGeometry = nil
        snapshotPresentationIsAcknowledged = false
        snapshotPresentationRevision &+= 1
        let update = PresentationGeometryUpdate(
            revision: snapshotPresentationRevision,
            geometry: nil
        )
        snapshotFrameLock.unlock()
        notifyPresentationGeometryObservers(with: update)
    }

    private func clearSnapshotFrame() {
        snapshotFrameLock.lock()
        let hadFrame = snapshotPixelBuffer != nil || snapshotPresentationGeometry != nil
        snapshotPixelBuffer = nil
        snapshotPresentationGeometry = nil
        snapshotPresentationIsAcknowledged = false
        var update: PresentationGeometryUpdate?
        if hadFrame {
            snapshotPresentationRevision &+= 1
            update = PresentationGeometryUpdate(
                revision: snapshotPresentationRevision,
                geometry: nil
            )
        }
        snapshotFrameLock.unlock()
        if let update {
            notifyPresentationGeometryObservers(with: update)
        }
    }

    private func suppressSnapshotFrameForGeometryTransition()
        -> PresentationGeometryUpdate {
        snapshotFrameLock.lock()
        snapshotPixelBuffer = nil
        snapshotPresentationGeometry = nil
        snapshotPresentationIsAcknowledged = false
        snapshotPresentationRevision &+= 1
        let update = PresentationGeometryUpdate(
            revision: snapshotPresentationRevision,
            geometry: nil
        )
        snapshotFrameLock.unlock()
        return update
    }

    private func notifyPresentationGeometryObservers(
        with update: PresentationGeometryUpdate,
        completion: (@Sendable () -> Void)? = nil
    ) {
        presentationGeometryObserverLock.lock()
        let observers = Array(presentationGeometryObservers.values)
        presentationGeometryObserverLock.unlock()
        Task { @MainActor [self, renderQueue] in
            // Unstructured MainActor tasks are not an ordering primitive. If a
            // newer suppression or geometry was published while this task was
            // waiting, deliver that current state instead; an older callback
            // must never reveal a source that is now fail-closed.
            let currentUpdate = presentationGeometryUpdate()
            let deliveredUpdate = currentUpdate.revision > update.revision
                ? currentUpdate
                : update
            for observer in observers {
                observer(deliveredUpdate)
            }
            if let completion {
                // The acknowledgement is a presentation barrier, not merely a
                // Swift callback barrier. Commit AppKit/Core Animation's hide
                // or crop-frame mutations before AVFoundation can receive the
                // corresponding new IOSurface.
                CATransaction.flush()
                renderQueue.async(execute: completion)
            }
        }
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

    private func sourcePresentationGeometry(
        from sampleBuffer: CMSampleBuffer,
        imageBuffer: CVImageBuffer
    ) -> SourcePresentationGeometry? {
        guard let attachments = frameAttachments(for: sampleBuffer),
              let contentRect = frameRect(attachments[.contentRect]),
              let scaleFactor = attachments[.scaleFactor] as? CGFloat,
              scaleFactor.isFinite,
              scaleFactor > 0 else { return nil }
        return SourcePresentationGeometry(
            surfaceSize: CGSize(
                width: CGFloat(CVPixelBufferGetWidth(imageBuffer)) / scaleFactor,
                height: CGFloat(CVPixelBufferGetHeight(imageBuffer)) / scaleFactor
            ),
            contentRect: contentRect
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
    /// Normalized in the full accepted IOSurface. The crop wrapper moves the
    /// entire child view; this rectangle only rejects a dot whose center is not
    /// in the audience-visible source region.
    private var visibleSurfaceCrop: CGRect? = CGRect(x: 0, y: 0, width: 1, height: 1)
    /// The compositor grants pointer ownership to exactly one source view.
    /// This is independent of the renderer's cursor-safety state: inactive
    /// views keep receiving cursorless frames but never draw a local dot.
    private var isPointerOverlayEnabled = false
    private var pointerAppearance: PointerAppearance = .presentationDefault

    override var isOpaque: Bool { false }

    init(renderer: SampleBufferRenderer) {
        self.renderer = renderer
        super.init(frame: .zero)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        layer?.masksToBounds = true
        configurePointerDotLayer()
        layer?.addSublayer(pointerDotLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        if renderer.displayLayer.superlayer === layer {
            renderer.displayLayer.frame = bounds
        }
        updatePointerOverlay()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateWindowStateObservers()
        guard window != nil else {
            // A view leaving its window must never steal the renderer from a
            // newer visible view that has already claimed the single layer.
            stopPointerTimer()
            return
        }
        if renderer.displayLayer.superlayer !== layer {
            renderer.displayLayer.removeFromSuperlayer()
            layer?.insertSublayer(renderer.displayLayer, at: 0)
        }
        if pointerDotLayer.superlayer !== layer {
            pointerDotLayer.removeFromSuperlayer()
            layer?.addSublayer(pointerDotLayer)
        }
        renderer.setPointerAvailabilityHandler { [weak self] in
            guard let self else { return }
            applyPointerAppearance(renderer.pointerAppearance())
            updatePointerTimerState()
        }
        renderer.displayLayer.frame = bounds
        updatePointerTimerState()
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

    func setVisibleSurfaceCrop(_ crop: CGRect?) {
        guard visibleSurfaceCrop != crop else { return }
        visibleSurfaceCrop = crop
        if crop == nil {
            setPointerDotHidden(true)
        }
        updatePointerTimerState()
        updatePointerOverlay()
    }

    /// Commits the media layer's frame before a crop wrapper reveals this
    /// view. The explicit assignment preserves the invariant even when the
    /// view is hidden and currently owns the renderer's single shared display
    /// layer. Do not force an AppKit layout pass here: the geometry observer
    /// can run from its parent's existing `layout()` pass.
    func synchronizePresentationLayoutBeforeReveal() {
        needsLayout = true
        guard renderer.displayLayer.superlayer === layer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        renderer.displayLayer.frame = bounds
        CATransaction.commit()
    }

    /// Prepares an immutable replacement for the media layer, which AppKit's
    /// `cacheDisplay(in:to:)` cannot rasterize directly.
    func makeBitmapSnapshotImage() -> CGImage? {
        renderer.makeBitmapSnapshotImage { [weak self] geometry in
            (self?.superview as? CroppedSampleBufferNSView)?
                .synchronizeSnapshotGeometry(geometry)
        }
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
           !isHiddenOrHasHiddenAncestor,
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
              !isHiddenOrHasHiddenAncestor,
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
              let visibleSurfaceCrop,
              renderer.shouldSamplePointerLocation(),
              let globalPointer = CGEvent(source: nil)?.location,
              let overlay = renderer.pointerOverlaySnapshot(at: globalPointer),
              overlay.normalizedPosition.x >= visibleSurfaceCrop.minX,
              overlay.normalizedPosition.x <= visibleSurfaceCrop.maxX,
              overlay.normalizedPosition.y >= visibleSurfaceCrop.minY,
              overlay.normalizedPosition.y <= visibleSurfaceCrop.maxY,
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
