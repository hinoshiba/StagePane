import AppKit
import Combine
import CoreMedia
import CoreVideo
import ScreenCaptureKit
import StagePaneCore

enum CapturePhase: Equatable, Sendable {
    case idle
    case choosing
    case preparing
    case previewing
    case failed(String)

    var isPreviewing: Bool {
        self == .previewing
    }
}

enum CaptureSourceKind: String, Sendable {
    case window
    case application
    case display
    case unknown

    var symbolName: String {
        switch self {
        case .window: "macwindow"
        case .application: "app.fill"
        case .display: "display"
        case .unknown: "rectangle.dashed"
        }
    }
}

enum CaptureSourcePhase: Equatable {
    case preparing
    case active
    case pausing
    case paused
    case resuming
    case stopping
    case needsAttention(String)
}

@MainActor
final class CaptureSource: ObservableObject, Identifiable {
    let id: StageSourceID
    let ordinal: Int
    let renderers: CaptureSourceRenderers

    @Published fileprivate(set) var title: String
    @Published fileprivate(set) var kind: CaptureSourceKind
    @Published fileprivate(set) var phase: CaptureSourcePhase = .preparing
    @Published fileprivate(set) var isPaused = false
    @Published fileprivate(set) var isOutputSuppressed = false

    var stageRenderer: SampleBufferRenderer { renderers.stage }
    var previewRenderer: SampleBufferRenderer { renderers.preview }

    fileprivate init(
        id: StageSourceID,
        ordinal: Int,
        title: String,
        kind: CaptureSourceKind,
        renderers: CaptureSourceRenderers
    ) {
        self.id = id
        self.ordinal = ordinal
        self.title = title
        self.kind = kind
        self.renderers = renderers
    }
}

private final class SendableBox<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}

private struct StreamStopFailure: Sendable {
    let message: String
    let domain: String
    let code: Int

    init(_ error: Error) {
        let nsError = error as NSError
        self.message = nsError.localizedDescription
        self.domain = nsError.domain
        self.code = nsError.code
    }

    var isUserStopped: Bool {
        domain == SCStreamError.errorDomain && code == SCStreamError.Code.userStopped.rawValue
    }
}

private enum CapturePresentationUpdate: Sendable {
    case unavailable(previous: UUID, current: UUID)
    case ready(UUID)
}

/// A stream-specific output/delegate prevents callbacks from one source or an
/// old stream generation from being routed into another source tile.
private final class CaptureStreamProxy: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    typealias StopHandler = @Sendable (UUID, SendableBox<SCStream>, StreamStopFailure) -> Void
    typealias GeometryHandler = @Sendable (UUID, Int, CaptureSourceGeometry) -> Void
    typealias PresentationHandler = @Sendable (UUID, CapturePresentationUpdate) -> Void

    private enum PresentationState: Equatable {
        case awaitingFreshFrame
        case ready
        case replacingContent
    }

    private enum ExplicitPauseState: Equatable {
        case none
        case paused
        case resuming
    }

    let token: UUID
    private let renderers: CaptureSourceRenderers
    private let outputQueue: DispatchQueue
    private let stopHandler: StopHandler
    private let geometryHandler: GeometryHandler
    private let presentationHandler: PresentationHandler
    /// Screen callbacks are delivered serially on CaptureCoordinator.outputQueue.
    private var lastGeometry: CaptureSourceGeometry?
    /// Advanced on the same serial queue only after a content-filter update has
    /// completed, so callbacks already queued for the previous filter cannot be
    /// relabeled as geometry from its replacement.
    private var geometryGeneration = 0
    /// Presentation generations are independent from geometry generations: an
    /// unavailable source can return with unchanged dimensions but must not
    /// republish any retained pixels from before the boundary.
    private var presentationGeneration: UUID
    private var presentationState: PresentationState = .awaitingFreshFrame
    private var explicitPauseState: ExplicitPauseState = .none
    /// Resume deliberately keeps the paused image until either a fresh complete
    /// frame replaces it or an unavailable marker proves it is no longer valid.
    private var isRetainingPausedPresentationDuringResume = false
    /// Unavailable markers observed during an intentional Pause do not remove
    /// its held image, but they must invalidate that image when Resume begins.
    private var didObserveUnavailablePresentationWhilePaused = false
    private var presentationUnavailableInteractionIsSuspended = false

    init(
        token: UUID,
        renderers: CaptureSourceRenderers,
        outputQueue: DispatchQueue,
        initialPresentationGeneration: UUID,
        geometryHandler: @escaping GeometryHandler,
        presentationHandler: @escaping PresentationHandler,
        stopHandler: @escaping StopHandler
    ) {
        self.token = token
        self.renderers = renderers
        self.outputQueue = outputQueue
        self.presentationGeneration = initialPresentationGeneration
        self.geometryHandler = geometryHandler
        self.presentationHandler = presentationHandler
        self.stopHandler = stopHandler
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }
        guard let status = frameStatus(from: sampleBuffer) else { return }

        switch status {
        case .blank, .suspended:
            beginUnavailablePresentationOnOutputQueue()
            return
        case .idle:
            guard presentationState == .ready else { return }
        case .complete:
            guard presentationState != .replacingContent,
                  explicitPauseState != .paused else { return }
            if explicitPauseState == .resuming {
                explicitPauseState = .none
                isRetainingPausedPresentationDuringResume = false
                didObserveUnavailablePresentationWhilePaused = false
            }
            if let geometry = completeFrameGeometry(from: sampleBuffer),
               geometryDiffersMeaningfully(geometry, from: lastGeometry) {
                lastGeometry = geometry
                geometryHandler(token, geometryGeneration, geometry)
            }
        default:
            // Start/stop lifecycle markers carry no replacement pixels. In
            // particular, an explicit Pause must retain its last complete frame.
            return
        }

        let becameReady = presentationState == .awaitingFreshFrame
        if becameReady {
            presentationState = .ready
            presentationUnavailableInteractionIsSuspended = false
            renderers.resumePreviewInteractionForFreshPresentationFrameOnRenderQueue(
                token: token,
                filterGeneration: geometryGeneration,
                presentationTimeStamp:
                    CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            )
        }
        renderers.enqueue(
            sampleBuffer,
            token: token,
            filterGeneration: geometryGeneration,
            presentationGeneration: presentationGeneration
        )
        if becameReady {
            presentationHandler(token, .ready(presentationGeneration))
        }
    }

    /// Begins a fail-closed replacement on the stream-output queue. The caller
    /// has already installed the matching preview-interaction suspension.
    func beginContentReplacementOnOutputQueue(
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        explicitPauseState = .none
        isRetainingPausedPresentationDuringResume = false
        didObserveUnavailablePresentationWhilePaused = false
        if presentationUnavailableInteractionIsSuspended {
            presentationUnavailableInteractionIsSuspended = false
            renderers.resumePreviewInteractionOnRenderQueue(
                reason: .presentationUnavailable,
                token: token,
                filterGeneration: geometryGeneration
            )
        }
        self.presentationGeneration = presentationGeneration
        presentationState = .replacingContent
        renderers.invalidatePresentationOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration
        )
    }

    /// Must run after ScreenCaptureKit accepts the replacement filter. Queued
    /// callbacks from before this point were discarded as replacing content.
    func finishContentReplacementOnOutputQueue(
        presentationGeneration: UUID,
        geometryGeneration: Int
    ) {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        guard self.presentationGeneration == presentationGeneration,
              presentationState == .replacingContent else { return }
        self.geometryGeneration = geometryGeneration
        lastGeometry = nil
        presentationState = .awaitingFreshFrame
    }

    func beginExplicitPauseOnOutputQueue() {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        explicitPauseState = .paused
        isRetainingPausedPresentationDuringResume = false
        didObserveUnavailablePresentationWhilePaused = false
    }

    func cancelExplicitPauseOnOutputQueue() {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        guard explicitPauseState == .paused else { return }
        explicitPauseState = .none
        if didObserveUnavailablePresentationWhilePaused {
            didObserveUnavailablePresentationWhilePaused = false
            beginUnavailablePresentationOnOutputQueue()
        }
    }

    func beginExplicitResumeOnOutputQueue(
        presentationGeneration: UUID
    ) {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        explicitPauseState = .resuming
        isRetainingPausedPresentationDuringResume = true
        self.presentationGeneration = presentationGeneration
        presentationState = .awaitingFreshFrame
        renderers.advancePresentationGenerationPreservingFrameOnRenderQueue(
            token: token,
            presentationGeneration: presentationGeneration
        )
        if didObserveUnavailablePresentationWhilePaused {
            didObserveUnavailablePresentationWhilePaused = false
            isRetainingPausedPresentationDuringResume = false
            suspendForUnavailablePresentationIfNeededOnOutputQueue()
            renderers.invalidatePresentationOnRenderQueue(
                token: token,
                presentationGeneration: presentationGeneration
            )
        }
    }

    func cancelExplicitResumeOnOutputQueue() {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        if explicitPauseState == .resuming {
            explicitPauseState = .paused
            isRetainingPausedPresentationDuringResume = false
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        let streamBox = SendableBox(stream)
        let failure = StreamStopFailure(error)
        outputQueue.async { [self] in
            renderers.suspendPreviewInteractionOnRenderQueue(
                reason: .streamStopped,
                token: token
            )
            stopHandler(token, streamBox, failure)
        }
    }

    @available(macOS 15.2, *)
    func streamDidBecomeInactive(_ stream: SCStream) {
        outputQueue.async { [self] in
            renderers.suspendPreviewInteractionOnRenderQueue(
                reason: .streamInactive,
                token: token
            )
            beginUnavailablePresentationOnOutputQueue()
        }
    }

    @available(macOS 15.2, *)
    func streamDidBecomeActive(_ stream: SCStream) {
        outputQueue.async { [self] in
            renderers.resumePreviewInteractionOnRenderQueue(
                reason: .streamInactive,
                token: token,
                filterGeneration: geometryGeneration
            )
        }
    }

    private func beginUnavailablePresentationOnOutputQueue() {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        guard presentationState != .replacingContent else { return }
        if explicitPauseState == .paused {
            didObserveUnavailablePresentationWhilePaused = true
            return
        }

        suspendForUnavailablePresentationIfNeededOnOutputQueue()
        let hasPresentationToInvalidate = presentationState == .ready ||
            (explicitPauseState == .resuming &&
                isRetainingPausedPresentationDuringResume)
        guard hasPresentationToInvalidate else { return }

        let previousGeneration = presentationGeneration
        let nextGeneration = UUID()
        isRetainingPausedPresentationDuringResume = false
        presentationGeneration = nextGeneration
        presentationState = .awaitingFreshFrame
        lastGeometry = nil
        renderers.invalidatePresentationOnRenderQueue(
            token: token,
            presentationGeneration: nextGeneration
        )
        presentationHandler(
            token,
            .unavailable(previous: previousGeneration, current: nextGeneration)
        )
    }

    private func suspendForUnavailablePresentationIfNeededOnOutputQueue() {
        dispatchPrecondition(condition: .onQueue(outputQueue))
        guard !presentationUnavailableInteractionIsSuspended else { return }
        presentationUnavailableInteractionIsSuspended = true
        renderers.suspendPreviewInteractionOnRenderQueue(
            reason: .presentationUnavailable,
            token: token
        )
    }

    private func frameStatus(from sampleBuffer: CMSampleBuffer) -> SCFrameStatus? {
        guard sampleBuffer.isValid,
              let attachmentArray = CMSampleBufferGetSampleAttachmentsArray(
                  sampleBuffer,
                  createIfNecessary: false
              ) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentArray.first,
              let rawStatus = attachments[.status] as? Int else { return nil }
        return SCFrameStatus(rawValue: rawStatus)
    }

    private func completeFrameGeometry(
        from sampleBuffer: CMSampleBuffer
    ) -> CaptureSourceGeometry? {
        guard sampleBuffer.isValid,
              let attachmentArray = CMSampleBufferGetSampleAttachmentsArray(
                  sampleBuffer,
                  createIfNecessary: false
              ) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentArray.first,
              let rawStatus = attachments[.status] as? Int,
              SCFrameStatus(rawValue: rawStatus) == .complete,
              let contentRectDictionary = attachments[.contentRect] as? NSDictionary,
              let contentRect = CGRect(dictionaryRepresentation: contentRectDictionary),
              let contentScale = (attachments[.contentScale] as? NSNumber)?.doubleValue,
              let pointPixelScale = (attachments[.scaleFactor] as? NSNumber)?.doubleValue else {
            return nil
        }
        return CaptureSourceGeometry(
            surfaceContentPointWidth: Double(contentRect.width),
            surfaceContentPointHeight: Double(contentRect.height),
            contentScale: contentScale,
            pointPixelScale: pointPixelScale
        )
    }

    private func geometryDiffersMeaningfully(
        _ geometry: CaptureSourceGeometry,
        from previous: CaptureSourceGeometry?
    ) -> Bool {
        guard let previous else { return true }
        return abs(geometry.pointWidth - previous.pointWidth) >= 0.5 ||
            abs(geometry.pointHeight - previous.pointHeight) >= 0.5 ||
            abs(geometry.pointPixelScale - previous.pointPixelScale) >= 0.01
    }
}

@MainActor
private final class CaptureSession {
    enum TeardownOutcome: Sendable {
        case removed
        case failed(String)
    }

    enum ActiveAttention {
        case stopFailure(String)
        case pickerFailure(String)
        case pauseFailure(String)

        var message: String {
            switch self {
            case let .stopFailure(message),
                 let .pickerFailure(message),
                 let .pauseFailure(message): message
            }
        }

        var clearsAfterSuccessfulContentUpdate: Bool {
            if case .pickerFailure = self { return true }
            return false
        }
    }

    enum PauseTransition: Equatable {
        case pausing
        case resuming
    }

    let source: CaptureSource
    let token: UUID
    let stream: SCStream
    let proxy: CaptureStreamProxy
    var filter: SCContentFilter
    var isStarted = false
    var isStreamRunning = false
    /// True only after a complete frame for the current presentation generation
    /// has been accepted. Delegate activity alone is not sufficient proof.
    var isStreamContentActive = false
    var awaitsFreshPresentationFrame = true
    var presentationGeneration: UUID
    var startDidFail = false
    var isStopping = false
    var isFinalizing = false
    var isTeardownStopRequested = false
    var isUpdatingContent = false
    var isUpdatingConfiguration = false
    var pauseTransition: PauseTransition?
    /// Delegate stops can race the completion of a pause or resume request.
    /// Preserve the first one until that in-flight operation settles so a late
    /// start completion cannot mark a user-stopped stream as running.
    var pendingUnexpectedStop: StreamStopFailure?
    var appliedConfigurationRevision: Int
    var appliedShowsCursor: Bool
    var appliedSurfaceWidth: Int
    var appliedSurfaceHeight: Int
    var teardownOutcome: TeardownOutcome?
    var activeAttention: ActiveAttention?
    var stopCompletions: [(String?) -> Void] = []
    /// Once removal starts, no delayed stream operation may make this source
    /// visible again. A failed stop keeps capture alive but intentionally leaves
    /// both local presentation surfaces suppressed until removal is retried.
    var outputSuppressed = false
    var requestedSourceConfigurationRevision = 0
    var appliedSourceConfigurationRevision = 0
    var pendingFilter: SCContentFilter?
    var sourceGeometry: CaptureSourceGeometry?
    var pendingSourceGeometry: CaptureSourceGeometry?
    var sourceGeometryGeneration = 0
    var sourceGeometryDebounceTask: Task<Void, Never>?

    init(
        source: CaptureSource,
        token: UUID,
        stream: SCStream,
        proxy: CaptureStreamProxy,
        filter: SCContentFilter,
        presentationGeneration: UUID,
        appliedConfigurationRevision: Int,
        appliedShowsCursor: Bool,
        appliedSurfaceWidth: Int,
        appliedSurfaceHeight: Int
    ) {
        self.source = source
        self.token = token
        self.stream = stream
        self.proxy = proxy
        self.filter = filter
        self.presentationGeneration = presentationGeneration
        self.appliedConfigurationRevision = appliedConfigurationRevision
        self.appliedShowsCursor = appliedShowsCursor
        self.appliedSurfaceWidth = appliedSurfaceWidth
        self.appliedSurfaceHeight = appliedSurfaceHeight
    }
}

@MainActor
private final class CaptureStopBatch {
    private var remaining: Int
    private var firstError: String?
    private let completion: (String?) -> Void

    init(count: Int, completion: @escaping (String?) -> Void) {
        self.remaining = count
        self.completion = completion
    }

    func finish(error: String?) {
        if firstError == nil { firstError = error }
        remaining -= 1
        if remaining == 0 { completion(firstError) }
    }
}

/// Bridges Apple's consent-preserving picker to a local multi-source stage.
///
/// Each source owns one filter and one stream. StagePane never enumerates all
/// screen content to implement its own picker, and it never records, encodes,
/// persists, or transmits captured frames.
@MainActor
final class CaptureCoordinator: NSObject, ObservableObject {
    static let maximumSources = 4

    @Published private(set) var phase: CapturePhase = .idle
    @Published private(set) var statusDetail = ""
    @Published private(set) var isCaptureActive = false
    @Published private(set) var isPickerPresented = false
    @Published private(set) var sources: [CaptureSource] = []
    @Published private(set) var layout = StageLayout()

    var canAddSource: Bool {
        sessions.count < Self.maximumSources && !isPickerPresented
    }

    // SCStreamConfiguration does not retain its backgroundColor. Keep this
    // object alive while any stream configuration can refer to it.
    private static let streamBackgroundColor = CGColor(gray: 0, alpha: 1)

    private enum PickerIntent: Equatable {
        case add
        case replace(StageSourceID)
        /// The system picker cannot be dismissed programmatically. Keep its
        /// single-flight slot occupied, but discard the next callback after a
        /// Stop All or removal invalidates the request.
        case invalidated
    }

    private let outputQueue: DispatchQueue
    private var sessions: [StageSourceID: CaptureSession] = [:]
    private var pickerIntent: PickerIntent?
    private var pointerStyle: StagePaneCore.PointerStyle = .system
    private var pointerAppearance: PointerAppearance = .presentationDefault
    private var outputWidth = 1920
    private var outputHeight = 1080
    private var configurationRevision = 0
    private var sourceOrdinal = 0

    var hasResettableFailure: Bool {
        guard !isCaptureActive else { return false }
        if case .failed = phase { return true }
        return false
    }
    private var lastFailure: String?

    override init() {
        self.outputQueue = DispatchQueue(
            label: "com.hinoshiba.stagepane.capture.video",
            qos: .userInteractive
        )
        super.init()

        let picker = SCContentSharingPicker.shared
        picker.defaultConfiguration = makePickerConfiguration()
        picker.maximumStreamCount = Self.maximumSources
        picker.add(self)
        picker.isActive = true
    }

    deinit {
        SCContentSharingPicker.shared.remove(self)
    }

    func chooseSource() {
        addSource()
    }

    func addSource() {
        guard !isPickerPresented else {
            if !publishStopFailureIfPresent() {
                statusDetail = L10n.text(
                    "現在の選択を完了してから、次のソースを追加してください。",
                    "Finish the current selection before adding another source."
                )
            }
            return
        }
        guard sessions.count < Self.maximumSources else {
            if !publishStopFailureIfPresent() {
                statusDetail = L10n.text(
                    "同時に追加できるソースは最大\(Self.maximumSources)件です。",
                    "You can add up to \(Self.maximumSources) sources at once."
                )
            }
            return
        }

        pickerIntent = .add
        isPickerPresented = true
        if !publishStopFailureIfPresent() {
            phase = .choosing
            statusDetail = L10n.text(
                "追加するウインドウ、アプリ、または画面を1つ選んでください。",
                "Choose one window, app, or display to add."
            )
        }
        SCContentSharingPicker.shared.present()
    }

    func replaceSource(_ sourceID: StageSourceID) {
        guard !isPickerPresented,
              let session = sessions[sourceID],
              !session.isStopping,
              !session.isUpdatingContent,
              canReplaceSource(sourceID) else { return }

        pickerIntent = .replace(sourceID)
        isPickerPresented = true
        if !publishStopFailureIfPresent() {
            phase = .choosing
            statusDetail = L10n.text(
                "「\(session.source.title)」に設定する新しい対象を1つ選んでください。",
                "Choose one new item for “\(session.source.title)”."
            )
        }
        SCContentSharingPicker.shared.present(for: session.stream)
    }

    func removeSource(_ sourceID: StageSourceID, completion: ((String?) -> Void)? = nil) {
        guard let session = sessions[sourceID] else {
            completion?(nil)
            return
        }
        invalidatePickerIntent(ifReplacing: sourceID)
        beginTeardown(of: session, outcome: .removed, completion: completion)
    }

    func canTogglePause(_ sourceID: StageSourceID) -> Bool {
        guard !isPickerPresented,
              let session = sessions[sourceID],
              session.isStarted,
              !session.isStopping,
              !session.isFinalizing,
              !session.outputSuppressed,
              !session.isUpdatingContent,
              !session.isUpdatingConfiguration,
              session.pauseTransition == nil,
              (session.source.isPaused || session.pendingFilter == nil) else { return false }
        if case .stopFailure = session.activeAttention { return false }
        return session.source.isPaused ? !session.isStreamRunning : session.isStreamRunning
    }

    func togglePause(_ sourceID: StageSourceID) {
        guard canTogglePause(sourceID), let session = sessions[sourceID] else { return }
        if session.source.isPaused {
            beginResume(of: session)
        } else {
            beginPause(of: session)
        }
    }

    func stop(completion: ((String?) -> Void)? = nil) {
        lastFailure = nil
        invalidatePickerIntent()
        let targets = Array(sessions.values)
        guard !targets.isEmpty else {
            isCaptureActive = false
            publishSteadyState()
            completion?(nil)
            return
        }

        if let completion {
            let batch = CaptureStopBatch(count: targets.count, completion: completion)
            for target in targets {
                beginTeardown(of: target, outcome: .removed) { error in
                    batch.finish(error: error)
                }
            }
        } else {
            for target in targets {
                beginTeardown(of: target, outcome: .removed)
            }
        }
    }

    func setPointerStyle(_ value: StagePaneCore.PointerStyle) {
        guard pointerStyle != value else { return }
        let nativeCursorVisibilityChanged =
            pointerStyle.showsSystemCursor != value.showsSystemCursor
        pointerStyle = value
        if nativeCursorVisibilityChanged { configurationRevision &+= 1 }

        for session in sessions.values {
            guard !session.source.isPaused, session.pauseTransition == nil else {
                // A paused source deliberately retains its last video frame,
                // but its live pointer overlay must not keep moving over it.
                session.source.renderers.setPointerStyle(.hidden)
                continue
            }
            if value != .redDot {
                session.source.renderers.setPointerStyle(value)
            } else {
                session.source.renderers.requestDeferredRedDot(token: session.token)
                applyPointerStyleToRenderersIfSafe(for: session)
            }
        }
        updateConfigurationsIfNeeded()
    }

    /// Updates only the local overlay artwork. Native cursor visibility and
    /// its frame-generation safeguards remain untouched.
    func setPointerAppearance(_ value: PointerAppearance) {
        guard pointerAppearance != value else { return }
        pointerAppearance = value
        for session in sessions.values {
            session.source.renderers.setPointerAppearance(value)
        }
    }

    func setOutputSize(width: Int, height: Int) {
        guard width > 0, height > 0 else { return }
        let boundedWidth = min(width, 3840)
        let boundedHeight = min(height, 3840)
        guard outputWidth != boundedWidth || outputHeight != boundedHeight else { return }
        outputWidth = boundedWidth
        outputHeight = boundedHeight
        configurationRevision &+= 1
        updateConfigurationsIfNeeded()
    }

    func source(for sourceID: StageSourceID) -> CaptureSource? {
        sources.first { $0.id == sourceID }
    }

    /// True when removing this session leaves no renderer that can still be
    /// visible on the public Stage. Stop-failure sessions stay registered for
    /// retry but are output-suppressed, so a simple source count is insufficient.
    func removalLeavesNoVisibleSources(_ sourceID: StageSourceID) -> Bool {
        guard sessions[sourceID] != nil else { return false }
        return sessions.values.allSatisfy { session in
            session.source.id == sourceID ||
                session.outputSuppressed ||
                session.isStopping ||
                session.isFinalizing
        }
    }

    /// Hit-tests the actual Stage composition. `layout.sources` is ordered
    /// back-to-front, so the visible top tile always owns the click even when
    /// sources overlap.
    func previewInteractionHit(
        at stagePoint: CGPoint,
        stageSize: CGSize
    ) -> StageInteractionHit? {
        let interactionSources = layout.sources.compactMap { item -> StageInteractionSource? in
            guard let session = sessions[item.id],
                  !session.outputSuppressed,
                  !session.isStopping,
                  !session.isFinalizing,
                  session.appliedSurfaceWidth > 0,
                  session.appliedSurfaceHeight > 0 else { return nil }
            return StageInteractionSource(
                id: item.id,
                stageFrame: item.frame,
                contentSize: CGSize(
                    width: session.appliedSurfaceWidth,
                    height: session.appliedSurfaceHeight
                )
            )
        }
        return StageInteractionProjection.frontmostHit(
            at: stagePoint,
            stageSize: stageSize,
            sources: interactionSources
        )
    }

    /// Resolves a click against the exact complete frame displayed by the
    /// private preview. Filter replacement and resume invalidate this snapshot
    /// until a fresh frame is actually enqueued.
    func resolvePreviewInputClick(
        _ hit: StageInteractionHit,
        completion: @escaping @MainActor @Sendable (
            Result<ResolvedPreviewInputClick, PreviewInputForwardingFailure>
        ) -> Void
    ) {
        guard !isPickerPresented,
              let session = sessions[hit.sourceID],
              session.isStarted,
              session.isStreamRunning,
              session.isStreamContentActive,
              !session.source.isPaused,
              session.pauseTransition == nil,
              !session.isStopping,
              !session.isFinalizing,
              !session.outputSuppressed,
              !session.isUpdatingContent,
              !session.isUpdatingConfiguration else {
            completion(.failure(.sourceTemporarilyUnavailable))
            return
        }

        let destination: PreviewWindowInputDestination
        switch PreviewInputDestinationResolver.destination(
            for: hit.sourceID,
            filter: session.filter
        ) {
        case let .success(value):
            destination = value
        case let .failure(failure):
            completion(.failure(failure))
            return
        }

        let token = session.token
        let filterGeneration = session.sourceGeometryGeneration
        session.source.previewRenderer.resolveGlobalInteractionPoint(
            normalizedSourcePoint: hit.normalizedSourcePoint,
            token: token,
            filterGeneration: filterGeneration
        ) { [weak self] resolvedPoint in
            guard let self,
                  let current = self.sessions[hit.sourceID],
                  current === session,
                  current.token == token,
                  current.sourceGeometryGeneration == filterGeneration,
                  current.isStreamRunning,
                  current.isStreamContentActive,
                  !current.source.isPaused,
                  current.pauseTransition == nil,
                  !current.isStopping,
                  !current.isFinalizing,
                  !current.outputSuppressed,
                  !current.isUpdatingContent,
                  !current.isUpdatingConfiguration else {
                completion(.failure(.sourceTemporarilyUnavailable))
                return
            }
            guard let resolvedPoint else {
                completion(.failure(.staleDisplayedFrame))
                return
            }
            completion(.success(ResolvedPreviewInputClick(
                destination: destination,
                globalPoint: resolvedPoint.globalPoint,
                displayedWindowFrame: resolvedPoint.displayedScreenRect,
                captureActionTicket: resolvedPoint.actionTicket
            )))
        }
    }

    func canReplaceSource(_ sourceID: StageSourceID) -> Bool {
        guard let session = sessions[sourceID],
              session.isStarted,
              session.isStreamRunning,
              !session.isStopping,
              !session.source.isPaused,
              session.pauseTransition == nil,
              !session.isUpdatingContent,
              !session.isUpdatingConfiguration,
              !session.outputSuppressed else { return false }
        if case .stopFailure = session.activeAttention { return false }
        return true
    }

    func moveSource(_ sourceID: StageSourceID, byX deltaX: Double, y deltaY: Double) {
        var updated = layout
        guard updated.moveSource(sourceID, byX: deltaX, y: deltaY) else { return }
        layout = updated
    }

    func setSourceFrame(
        _ sourceID: StageSourceID,
        frame: NormalizedStageRect,
        minimumWidth: Double = StageLayout.defaultMinimumDimension,
        minimumHeight: Double = StageLayout.defaultMinimumDimension
    ) {
        var updated = layout
        guard updated.resizeSource(
            sourceID,
            x: frame.x,
            y: frame.y,
            width: frame.width,
            height: frame.height,
            minimumWidth: minimumWidth,
            minimumHeight: minimumHeight
        ) else { return }
        layout = updated
    }

    /// Commits a completed resize to ScreenCaptureKit. Drag updates remain a
    /// cheap layer-only operation; the stream surface is resized once the user
    /// releases the handle.
    func commitSourceLayout(_ sourceID: StageSourceID) {
        guard let session = sessions[sourceID], !session.outputSuppressed else { return }
        session.requestedSourceConfigurationRevision &+= 1
        updateConfigurationIfNeeded(for: session)
    }

    func arrangeSourcesAutomatically() {
        applyLayoutPreset(.grid)
    }

    func applyLayoutPreset(_ preset: StageLayoutPreset) {
        var updated = layout
        updated.apply(preset: preset)
        layout = updated
        for session in sessions.values where !session.outputSuppressed {
            session.requestedSourceConfigurationRevision &+= 1
        }
        updateConfigurationsIfNeeded()
    }

    func bringSourceToFront(_ sourceID: StageSourceID) {
        guard let selected = layout[sourceID: sourceID],
              layout.sources.last?.id != sourceID else { return }
        let reordered = layout.sources.filter { $0.id != sourceID } + [selected]
        layout = StageLayout(sources: reordered)
    }

    private func beginCapture(with filter: SCContentFilter) {
        guard sessions.count < Self.maximumSources else {
            publishFailure(L10n.text(
                "ソース数の上限に達したため追加できませんでした。",
                "The source limit was reached, so the item was not added."
            ))
            return
        }

        sourceOrdinal += 1
        let ordinal = sourceOrdinal
        let sourceID = StageSourceID(rawValue: UUID().uuidString)
        var proposedLayout = layout
        let proposedFrame = StageLayout.suggestedFrameForNewSource(
            occupiedFrames: proposedLayout.sources.map(\.frame)
        )
        _ = proposedLayout.addSource(sourceID, frame: proposedFrame)
        let renderers = CaptureSourceRenderers(renderQueue: outputQueue)
        let metadata = sourceMetadata(for: filter, ordinal: ordinal)
        let source = CaptureSource(
            id: sourceID,
            ordinal: ordinal,
            title: metadata.title,
            kind: metadata.kind,
            renderers: renderers
        )

        let token = UUID()
        let initialPresentationGeneration = UUID()
        let proxy = CaptureStreamProxy(
            token: token,
            renderers: renderers,
            outputQueue: outputQueue,
            initialPresentationGeneration: initialPresentationGeneration,
            geometryHandler: { [weak self] token, generation, geometry in
                Task { @MainActor [weak self] in
                    self?.observeSourceGeometry(
                        token: token,
                        generation: generation,
                        geometry: geometry
                    )
                }
            },
            presentationHandler: { [weak self] token, update in
                // Preserve the output queue's unavailable -> ready order.
                // Independent unstructured MainActor tasks do not guarantee it.
                DispatchQueue.main.async { [weak self] in
                    self?.handlePresentationUpdate(
                        token: token,
                        update: update
                    )
                }
            },
            stopHandler: { [weak self] token, streamBox, failure in
                Task { @MainActor [weak self] in
                    self?.handleUnexpectedStop(
                        token: token,
                        stream: streamBox.value,
                        failure: failure
                    )
                }
            }
        )
        let configuration = makeConfiguration(for: filter, frame: proposedFrame)
        let stream = SCStream(filter: filter, configuration: configuration, delegate: proxy)

        do {
            try stream.addStreamOutput(proxy, type: .screen, sampleHandlerQueue: outputQueue)
        } catch {
            renderers.flush()
            publishFailure(error.localizedDescription)
            return
        }

        let session = CaptureSession(
            source: source,
            token: token,
            stream: stream,
            proxy: proxy,
            filter: filter,
            presentationGeneration: initialPresentationGeneration,
            appliedConfigurationRevision: configurationRevision,
            appliedShowsCursor: configuration.showsCursor,
            appliedSurfaceWidth: configuration.width,
            appliedSurfaceHeight: configuration.height
        )
        sessions[sourceID] = session
        sources.append(source)
        layout = proposedLayout
        isCaptureActive = true
        lastFailure = nil
        renderers.setPointerAppearance(pointerAppearance)
        renderers.setPointerStyle(pointerStyle)
        renderers.activate(
            token: token,
            showsCursor: configuration.showsCursor,
            presentationGeneration: initialPresentationGeneration
        )
        SCContentSharingPicker.shared.setConfiguration(makePickerConfiguration(), for: stream)
        publishSteadyState()

        let streamBox = SendableBox(stream)
        let outputQueue = self.outputQueue
        stream.startCapture { [weak self] error in
            let message = error?.localizedDescription
            outputQueue.async { [weak self] in
                if message == nil {
                    renderers.resumePreviewInteractionOnRenderQueue(
                        reason: .captureLifecycle,
                        token: token,
                        filterGeneration: 0
                    )
                }
                Task { @MainActor [weak self] in
                    self?.handleStartCompletion(
                        sourceID: sourceID,
                        token: token,
                        stream: streamBox.value,
                        errorMessage: message
                    )
                }
            }
        }
    }

    private func updateContent(of session: CaptureSession, with filter: SCContentFilter) {
        guard !session.isStopping, !session.outputSuppressed else { return }
        if !session.isStarted ||
            session.source.isPaused ||
            session.pauseTransition != nil ||
            session.isUpdatingContent ||
            session.isUpdatingConfiguration {
            session.pendingFilter = filter
            switch session.pauseTransition {
            case .pausing:
                session.source.phase = .pausing
            case .resuming:
                session.source.phase = .resuming
            case nil:
                if session.source.isPaused {
                    session.source.phase = .paused
                } else {
                    session.source.phase = .preparing
                }
            }
            publishSteadyState()
            return
        }
        session.sourceGeometryGeneration &+= 1
        let geometryGeneration = session.sourceGeometryGeneration
        let presentationGeneration = UUID()
        session.presentationGeneration = presentationGeneration
        session.awaitsFreshPresentationFrame = true
        session.isStreamContentActive = false
        session.sourceGeometryDebounceTask?.cancel()
        session.sourceGeometryDebounceTask = nil
        session.pendingSourceGeometry = nil
        session.isUpdatingContent = true
        session.source.phase = .preparing
        publishSteadyState()

        let sourceID = session.source.id
        let token = session.token
        let streamBox = SendableBox(session.stream)
        let filterBox = SendableBox(filter)
        let proxy = session.proxy
        let renderers = session.source.renderers
        let outputQueue = self.outputQueue
        renderers.suspendPreviewInteraction(
            reason: .contentReplacement,
            token: token
        ) {
            proxy.beginContentReplacementOnOutputQueue(
                presentationGeneration: presentationGeneration
            )
            streamBox.value.updateContentFilter(filterBox.value) { [weak self] error in
                let message = error?.localizedDescription
                outputQueue.async { [weak self] in
                    if message == nil {
                        proxy.finishContentReplacementOnOutputQueue(
                            presentationGeneration: presentationGeneration,
                            geometryGeneration: geometryGeneration
                        )
                        renderers.resumePreviewInteractionOnRenderQueue(
                            reason: .contentReplacement,
                            token: token,
                            filterGeneration: geometryGeneration
                        )
                    }
                    Task { @MainActor [weak self] in
                        guard let self,
                              let current = self.sessions[sourceID],
                              current === session,
                              current.token == token,
                              current.stream === streamBox.value,
                              !current.isFinalizing else { return }
                        self.handleContentUpdateCompletion(
                            session: current,
                            filter: filterBox.value,
                            errorMessage: message
                        )
                    }
                }
            }
        }
    }

    private func handleStartCompletion(
        sourceID: StageSourceID,
        token: UUID,
        stream: SCStream,
        errorMessage: String?
    ) {
        guard let session = sessions[sourceID],
              session.token == token,
              session.stream === stream,
              !session.isFinalizing else { return }
        if let errorMessage {
            session.startDidFail = true
            beginTeardown(of: session, outcome: .failed(errorMessage))
            return
        }

        session.isStarted = true
        session.isStreamRunning = true
        guard !session.isStopping, !session.outputSuppressed else {
            publishSteadyState()
            return
        }
        if startPendingContentUpdateIfNeeded(for: session) { return }
        session.source.phase = liveSourcePhase(for: session)
        updateConfigurationIfNeeded(for: session)
        publishSteadyState()
    }

    private func beginPause(of session: CaptureSession) {
        guard canTogglePause(session.source.id), !session.source.isPaused else { return }
        clearPauseFailure(for: session)
        session.pauseTransition = .pausing
        session.source.phase = .pausing
        session.sourceGeometryDebounceTask?.cancel()
        session.sourceGeometryDebounceTask = nil
        session.pendingSourceGeometry = nil
        // Keep the displayed video image, but remove the independently sampled
        // red-dot overlay before stopping the stream.
        session.source.renderers.setPointerStyle(.hidden)
        publishSteadyState()

        let sourceID = session.source.id
        let token = session.token
        let filterGeneration = session.sourceGeometryGeneration
        let renderers = session.source.renderers
        let proxy = session.proxy
        let outputQueue = self.outputQueue
        let streamBox = SendableBox(session.stream)
        renderers.suspendPreviewInteraction(
            reason: .captureLifecycle,
            token: token
        ) {
            proxy.beginExplicitPauseOnOutputQueue()
            streamBox.value.stopCapture { [weak self] error in
                let message = error?.localizedDescription
                outputQueue.async { [weak self] in
                    if message != nil {
                        proxy.cancelExplicitPauseOnOutputQueue()
                        renderers.resumePreviewInteractionOnRenderQueue(
                            reason: .captureLifecycle,
                            token: token,
                            filterGeneration: filterGeneration
                        )
                    }
                    Task { @MainActor [weak self] in
                        self?.handlePauseCompletion(
                            sourceID: sourceID,
                            token: token,
                            stream: streamBox.value,
                            errorMessage: message
                        )
                    }
                }
            }
        }
    }

    private func handlePauseCompletion(
        sourceID: StageSourceID,
        token: UUID,
        stream: SCStream,
        errorMessage: String?
    ) {
        guard let session = sessions[sourceID],
              session.token == token,
              session.stream === stream,
              session.pauseTransition == .pausing,
              !session.isFinalizing else { return }
        session.pauseTransition = nil
        if consumePendingUnexpectedStop(for: session) { return }

        if let errorMessage {
            session.isStreamRunning = true
            if session.isStopping {
                continueTeardown(of: session)
                return
            }
            restorePointerStyle(for: session)
            let message = L10n.text(
                "「\(session.source.title)」を一時停止できませんでした。画面取得は継続しています。",
                "“\(session.source.title)” could not be paused. Capture is still running."
            ) + " (\(errorMessage))"
            session.activeAttention = .pauseFailure(message)
            session.source.phase = .needsAttention(message)
            lastFailure = message
            updateConfigurationIfNeeded(for: session)
            publishSteadyState()
            return
        }

        session.isStreamRunning = false
        session.source.isPaused = true
        clearPauseFailure(for: session)
        if session.isStopping {
            // The in-flight pause already stopped this exact stream. Removal
            // can proceed without issuing a second stopCapture request.
            finalizeStoppedSession(
                session,
                outcome: session.teardownOutcome ?? .removed
            )
            return
        }
        session.source.phase = .paused
        publishSteadyState()
    }

    private func beginResume(of session: CaptureSession) {
        guard canTogglePause(session.source.id), session.source.isPaused else { return }
        clearPauseFailure(for: session)
        session.pauseTransition = .resuming
        session.source.phase = .resuming
        let presentationGeneration = UUID()
        session.presentationGeneration = presentationGeneration
        session.awaitsFreshPresentationFrame = true
        session.isStreamContentActive = false
        // Remain visually paused until ScreenCaptureKit confirms the same
        // stream has restarted.
        session.source.renderers.setPointerStyle(.hidden)
        publishSteadyState()

        let sourceID = session.source.id
        let token = session.token
        let filterGeneration = session.sourceGeometryGeneration
        let renderers = session.source.renderers
        let proxy = session.proxy
        let outputQueue = self.outputQueue
        let streamBox = SendableBox(session.stream)
        outputQueue.async {
            proxy.beginExplicitResumeOnOutputQueue(
                presentationGeneration: presentationGeneration
            )
            streamBox.value.startCapture { [weak self] error in
                let message = error?.localizedDescription
                outputQueue.async { [weak self] in
                    if message == nil {
                        renderers.resumePreviewInteractionOnRenderQueue(
                            reason: .captureLifecycle,
                            token: token,
                            filterGeneration: filterGeneration
                        )
                    } else {
                        proxy.cancelExplicitResumeOnOutputQueue()
                    }
                    Task { @MainActor [weak self] in
                        self?.handleResumeCompletion(
                            sourceID: sourceID,
                            token: token,
                            stream: streamBox.value,
                            errorMessage: message
                        )
                    }
                }
            }
        }
    }

    private func handleResumeCompletion(
        sourceID: StageSourceID,
        token: UUID,
        stream: SCStream,
        errorMessage: String?
    ) {
        guard let session = sessions[sourceID],
              session.token == token,
              session.stream === stream,
              session.pauseTransition == .resuming,
              !session.isFinalizing else { return }
        session.pauseTransition = nil
        if consumePendingUnexpectedStop(for: session) { return }

        if let errorMessage {
            session.isStreamRunning = false
            if session.isStopping {
                finalizeStoppedSession(
                    session,
                    outcome: session.teardownOutcome ?? .removed
                )
                return
            }
            let message = L10n.text(
                "「\(session.source.title)」を再開できませんでした。一時停止した画像を表示しています。",
                "“\(session.source.title)” could not be resumed. Its paused image remains visible."
            ) + " (\(errorMessage))"
            session.activeAttention = .pauseFailure(message)
            session.source.phase = .needsAttention(message)
            lastFailure = message
            publishSteadyState()
            return
        }

        session.isStreamRunning = true
        session.source.isPaused = false
        if session.isStopping {
            continueTeardown(of: session)
            return
        }
        clearPauseFailure(for: session)
        restorePointerStyle(for: session)
        if startPendingContentUpdateIfNeeded(for: session) { return }
        session.source.phase = liveSourcePhase(for: session)
        updateConfigurationIfNeeded(for: session)
        publishSteadyState()
    }

    private func handleContentUpdateCompletion(
        session: CaptureSession,
        filter: SCContentFilter,
        errorMessage: String?
    ) {
        guard sessions[session.source.id] === session, !session.isFinalizing else { return }
        session.isUpdatingContent = false
        guard !session.isStopping else { return }
        if let errorMessage {
            if session.outputSuppressed {
                publishSteadyState()
                return
            }
            beginTeardown(of: session, outcome: .failed(errorMessage))
            return
        }

        session.filter = filter
        session.sourceGeometry = nil
        if startPendingContentUpdateIfNeeded(for: session) { return }
        session.requestedSourceConfigurationRevision &+= 1
        let metadata = sourceMetadata(for: filter, ordinal: session.source.ordinal)
        session.source.title = metadata.title
        session.source.kind = metadata.kind
        if session.activeAttention?.clearsAfterSuccessfulContentUpdate == true {
            session.activeAttention = nil
        }
        session.source.phase = liveSourcePhase(for: session)
        updateConfigurationIfNeeded(for: session)
        publishSteadyState()
    }

    private func observeSourceGeometry(
        token: UUID,
        generation: Int,
        geometry: CaptureSourceGeometry
    ) {
        guard let session = sessions.values.first(where: { $0.token == token }),
              session.sourceGeometryGeneration == generation,
              !session.isStopping,
              !session.isFinalizing,
              !session.outputSuppressed,
              !session.isUpdatingContent,
              !session.source.isPaused,
              session.pauseTransition == nil else { return }

        session.pendingSourceGeometry = geometry
        session.sourceGeometryDebounceTask?.cancel()
        let sourceID = session.source.id
        session.sourceGeometryDebounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
            } catch {
                return
            }
            guard let self,
                  let current = self.sessions[sourceID],
                  current.token == token,
                  current.sourceGeometryGeneration == generation,
                  current.pendingSourceGeometry == geometry,
                  !current.isStopping,
                  !current.isFinalizing,
                  !current.outputSuppressed,
                  !current.isUpdatingContent,
                  !current.source.isPaused,
                  current.pauseTransition == nil else { return }

            current.pendingSourceGeometry = nil
            current.sourceGeometryDebounceTask = nil
            let frame = self.layout[sourceID: sourceID]?.frame ?? .fullCanvas
            let previousSize = self.captureSurfaceSize(
                for: current.filter,
                sourceGeometry: current.sourceGeometry,
                frame: frame
            )
            current.sourceGeometry = geometry
            let observedSize = self.captureSurfaceSize(
                for: current.filter,
                sourceGeometry: geometry,
                frame: frame
            )
            guard observedSize != previousSize else { return }

            current.requestedSourceConfigurationRevision &+= 1
            self.updateConfigurationIfNeeded(for: current)
        }
    }

    private func updateConfigurationsIfNeeded() {
        for session in sessions.values {
            updateConfigurationIfNeeded(for: session)
        }
    }

    private func updateConfigurationIfNeeded(for session: CaptureSession) {
        guard sessions[session.source.id] === session,
              session.isStarted,
              session.isStreamRunning,
              !session.isStopping,
              !session.outputSuppressed,
              !session.source.isPaused,
              session.pauseTransition == nil,
              !session.isUpdatingContent,
              !session.isUpdatingConfiguration,
              (session.appliedConfigurationRevision != configurationRevision ||
                  session.appliedSourceConfigurationRevision !=
                    session.requestedSourceConfigurationRevision) else { return }

        let targetRevision = configurationRevision
        let targetSourceRevision = session.requestedSourceConfigurationRevision
        let frame = layout[sourceID: session.source.id]?.frame ?? .fullCanvas
        let configuration = makeConfiguration(
            for: session.filter,
            sourceGeometry: session.sourceGeometry,
            frame: frame
        )
        let targetShowsCursor = configuration.showsCursor
        let targetSurfaceWidth = configuration.width
        let targetSurfaceHeight = configuration.height
        let sourceID = session.source.id
        let token = session.token
        let filterGeneration = session.sourceGeometryGeneration
        let renderers = session.source.renderers
        let outputQueue = self.outputQueue
        let streamBox = SendableBox(session.stream)
        let configurationBox = SendableBox(configuration)
        let removesNativeCursor = session.appliedShowsCursor && !targetShowsCursor
        let addsNativeCursor = !session.appliedShowsCursor && targetShowsCursor
        let changesNativeCursorVisibility = removesNativeCursor || addsNativeCursor
        let changesSurfaceDimensions =
            session.appliedSurfaceWidth != targetSurfaceWidth ||
            session.appliedSurfaceHeight != targetSurfaceHeight
        session.isUpdatingConfiguration = true
        session.source.phase = .preparing
        publishSteadyState()

        let updateCompletion: @Sendable (Error?) -> Void = { [weak self] error in
            let message = error?.localizedDescription
            outputQueue.async { [weak self] in
                if message == nil, changesSurfaceDimensions {
                    renderers.resumePreviewInteractionOnRenderQueue(
                        reason: .surfaceConfiguration,
                        token: token,
                        filterGeneration: filterGeneration
                    )
                }
                Task { @MainActor [weak self] in
                    guard let self,
                          let current = self.sessions[sourceID],
                          current === session,
                          current.token == token,
                          current.stream === streamBox.value,
                          !current.isFinalizing else { return }
                    if let message {
                        if changesNativeCursorVisibility {
                            current.source.renderers.cancelRedDotTransition(token: token)
                        }
                        current.isUpdatingConfiguration = false
                        if current.outputSuppressed {
                            self.publishSteadyState()
                            return
                        }
                        self.beginTeardown(of: current, outcome: .failed(message))
                        return
                    }

                    current.appliedConfigurationRevision = targetRevision
                    current.appliedSourceConfigurationRevision = targetSourceRevision
                    current.appliedShowsCursor = targetShowsCursor
                    current.appliedSurfaceWidth = targetSurfaceWidth
                    current.appliedSurfaceHeight = targetSurfaceHeight
                    current.isUpdatingConfiguration = false
                    guard !current.isStopping, !current.outputSuppressed else {
                        if changesNativeCursorVisibility {
                            current.source.renderers.cancelRedDotTransition(token: token)
                        }
                        self.publishSteadyState()
                        return
                    }
                    if removesNativeCursor {
                        current.source.renderers.commitCursorlessConfiguration(token: token)
                    } else {
                        if addsNativeCursor {
                            current.source.renderers.commitSystemCursorConfiguration(token: token)
                        }
                        self.applyPointerStyleToRenderersIfSafe(for: current)
                    }
                    if self.startPendingContentUpdateIfNeeded(for: current) { return }
                    current.source.phase = self.liveSourcePhase(for: current)
                    self.updateConfigurationIfNeeded(for: current)
                    self.publishSteadyState()
                }
            }
        }

        let startConfigurationUpdate: @Sendable () -> Void = {
            if changesNativeCursorVisibility {
                renderers.prepareCursorVisibilityTransition(
                    token: token,
                    targetShowsCursor: targetShowsCursor
                ) {
                    streamBox.value.updateConfiguration(
                        configurationBox.value,
                        completionHandler: updateCompletion
                    )
                }
            } else {
                streamBox.value.updateConfiguration(
                    configurationBox.value,
                    completionHandler: updateCompletion
                )
            }
        }
        if changesSurfaceDimensions {
            renderers.suspendPreviewInteraction(
                reason: .surfaceConfiguration,
                token: token,
                then: startConfigurationUpdate
            )
        } else {
            startConfigurationUpdate()
        }
    }

    private func beginTeardown(
        of target: CaptureSession,
        outcome: CaptureSession.TeardownOutcome,
        completion: ((String?) -> Void)? = nil
    ) {
        guard sessions[target.source.id] === target else {
            completion?(nil)
            return
        }
        if let completion { target.stopCompletions.append(completion) }
        // A stopped session remains registered while both presentation surfaces
        // finish draining. Later Stop/Quit requests must join that same barrier,
        // not report completion before the displayed images are discarded.
        guard !target.isFinalizing else { return }
        if target.isStopping {
            if case .failed = outcome { target.teardownOutcome = outcome }
            return
        }

        if let attentionMessage = target.activeAttention?.message,
           lastFailure == attentionMessage {
            lastFailure = nil
        }
        target.activeAttention = nil
        target.isStopping = true
        target.outputSuppressed = true
        target.source.isOutputSuppressed = true
        target.pendingFilter = nil
        target.sourceGeometryGeneration &+= 1
        target.sourceGeometryDebounceTask?.cancel()
        target.sourceGeometryDebounceTask = nil
        target.pendingSourceGeometry = nil
        target.teardownOutcome = outcome
        target.source.phase = .stopping
        target.source.renderers.deactivate(token: target.token)
        publishSteadyState()

        continueTeardown(of: target)
    }

    private func continueTeardown(of target: CaptureSession) {
        guard sessions[target.source.id] === target,
              target.isStopping,
              !target.isFinalizing,
              !target.isTeardownStopRequested,
              target.pauseTransition == nil else { return }
        if target.source.isPaused, !target.isStreamRunning {
            finalizeStoppedSession(
                target,
                outcome: target.teardownOutcome ?? .removed
            )
            return
        }

        target.isTeardownStopRequested = true
        let sourceID = target.source.id
        let token = target.token
        let streamBox = SendableBox(target.stream)
        streamBox.value.stopCapture { [weak self] error in
            let message = error?.localizedDescription
            Task { @MainActor [weak self] in
                self?.handleStopCompletion(
                    sourceID: sourceID,
                    token: token,
                    stream: streamBox.value,
                    errorMessage: message
                )
            }
        }
    }

    private func handleStopCompletion(
        sourceID: StageSourceID,
        token: UUID,
        stream: SCStream,
        errorMessage: String?
    ) {
        guard let session = sessions[sourceID],
              session.token == token,
              session.stream === stream,
              !session.isFinalizing else { return }
        session.isTeardownStopRequested = false
        if let errorMessage {
            if session.isStarted || !session.startDidFail {
                let callbacks = session.stopCompletions
                session.stopCompletions.removeAll()
                session.isStopping = false
                session.teardownOutcome = nil
                let message = L10n.text(
                    "「\(session.source.title)」を解除できませんでした。取得は継続中ですが、出力は隠しています。もう一度解除してください。",
                    "“\(session.source.title)” could not be removed. Capture continues, but its output is hidden. Try removing it again."
                ) + " (\(errorMessage))"
                session.activeAttention = .stopFailure(message)
                session.source.phase = .needsAttention(message)
                lastFailure = message
                publishSteadyState()
                callbacks.forEach { $0(message) }
            } else {
                // startCapture can fail before a stream exists to stop. Keep
                // the original start failure instead of replacing it with the
                // expected secondary "already stopped" cleanup error.
                finalizeStoppedSession(
                    session,
                    outcome: session.teardownOutcome ?? .failed(errorMessage)
                )
            }
            return
        }

        session.isStreamRunning = false
        finalizeStoppedSession(
            session,
            outcome: session.teardownOutcome ?? .removed
        )
    }

    private func finalizeStoppedSession(
        _ session: CaptureSession,
        outcome: CaptureSession.TeardownOutcome
    ) {
        guard sessions[session.source.id] === session, !session.isFinalizing else { return }
        session.isStreamRunning = false
        session.isFinalizing = true
        session.isStopping = true
        session.outputSuppressed = true
        session.source.isOutputSuppressed = true
        session.source.phase = .stopping
        var finalOutcome = outcome
        do {
            try session.stream.removeStreamOutput(session.proxy, type: .screen)
        } catch {
            let message = L10n.text(
                "画面取得は停止しましたが、出力の後処理に失敗しました。",
                "Capture stopped, but output cleanup failed."
            ) + " (\(error.localizedDescription))"
            finalOutcome = .failed(message)
        }

        let sourceID = session.source.id
        let token = session.token
        let resolvedOutcome = finalOutcome
        session.source.renderers.deactivate(token: token) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self,
                      let current = self.sessions[sourceID],
                      current === session else { return }
                self.finishStoppedSession(current, outcome: resolvedOutcome)
            }
        }
    }

    private func finishStoppedSession(
        _ session: CaptureSession,
        outcome: CaptureSession.TeardownOutcome
    ) {
        guard sessions[session.source.id] === session else { return }
        let callbacks = session.stopCompletions
        sessions.removeValue(forKey: session.source.id)
        sources.removeAll { $0.id == session.source.id }
        var updatedLayout = layout
        _ = updatedLayout.removeSource(session.source.id)
        layout = updatedLayout

        let errorMessage: String?
        switch outcome {
        case .removed:
            errorMessage = nil
        case let .failed(message):
            lastFailure = message
            errorMessage = message
        }
        publishSteadyState()
        callbacks.forEach { $0(errorMessage) }
    }

    private func handleUnexpectedStop(
        token: UUID,
        stream: SCStream,
        failure: StreamStopFailure
    ) {
        guard let session = session(for: stream),
              session.token == token,
              !session.isFinalizing else { return }
        if session.pauseTransition != nil {
            if session.pendingUnexpectedStop == nil {
                session.pendingUnexpectedStop = failure
            }
            return
        }
        session.isStreamRunning = false
        finalizeStoppedSession(
            session,
            outcome: unexpectedStopOutcome(failure, for: session)
        )
    }

    private func handlePresentationUpdate(
        token: UUID,
        update: CapturePresentationUpdate
    ) {
        guard let session = sessions.values.first(where: { $0.token == token }),
              !session.isStopping,
              !session.isFinalizing,
              !session.outputSuppressed else { return }

        switch update {
        case let .unavailable(previousGeneration, currentGeneration):
            // A content replacement or resume may already have installed a
            // different UUID while this queue-to-main notification was pending.
            guard session.presentationGeneration == previousGeneration else { return }
            session.presentationGeneration = currentGeneration
            session.awaitsFreshPresentationFrame = true
            session.isStreamContentActive = false
        case let .ready(generation):
            guard session.presentationGeneration == generation else { return }
            session.awaitsFreshPresentationFrame = false
            session.isStreamContentActive = true
        }

        if session.pauseTransition == nil, !session.source.isPaused {
            session.source.phase = liveSourcePhase(for: session)
        }
        publishSteadyState()
    }

    @discardableResult
    private func consumePendingUnexpectedStop(for session: CaptureSession) -> Bool {
        guard let failure = session.pendingUnexpectedStop else { return false }
        session.pendingUnexpectedStop = nil
        session.isStreamRunning = false
        finalizeStoppedSession(
            session,
            outcome: unexpectedStopOutcome(failure, for: session)
        )
        return true
    }

    private func unexpectedStopOutcome(
        _ failure: StreamStopFailure,
        for session: CaptureSession
    ) -> CaptureSession.TeardownOutcome {
        failure.isUserStopped
            ? session.teardownOutcome ?? .removed
            : .failed(failure.message)
    }

    private func session(for stream: SCStream) -> CaptureSession? {
        sessions.values.first { $0.stream === stream }
    }

    private func makePickerConfiguration() -> SCContentSharingPickerConfiguration {
        var configuration = SCContentSharingPickerConfiguration()
        configuration.allowedPickerModes = [
            .singleWindow,
            .singleApplication,
            .singleDisplay
        ]
        configuration.excludedBundleIDs = Bundle.main.bundleIdentifier.map { [$0] } ?? []
        configuration.allowsChangingSelectedContent = true
        return configuration
    }

    private func makeConfiguration(
        for filter: SCContentFilter,
        sourceGeometry: CaptureSourceGeometry? = nil,
        frame: NormalizedStageRect
    ) -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        let surfaceSize = captureSurfaceSize(
            for: filter,
            sourceGeometry: sourceGeometry,
            frame: frame
        )
        configuration.width = surfaceSize.width
        configuration.height = surfaceSize.height
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.queueDepth = 3
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.scalesToFit = true
        configuration.preservesAspectRatio = true
        configuration.showsCursor = pointerStyle.showsSystemCursor
        configuration.capturesAudio = false
        configuration.backgroundColor = Self.streamBackgroundColor
        configuration.shouldBeOpaque = true
        configuration.ignoreShadowsSingleWindow = true
        configuration.ignoreGlobalClipSingleWindow = true
        configuration.captureResolution = .best
        configuration.streamName = "StagePane Local Source"
        if #available(macOS 14.2, *) {
            configuration.includeChildWindows = true
        }
        return configuration
    }

    private func captureSurfaceSize(
        for filter: SCContentFilter,
        sourceGeometry: CaptureSourceGeometry?,
        frame: NormalizedStageRect
    ) -> CaptureSurfaceSize {
        let maximumWidth = streamDimension(
            fullDimension: outputWidth,
            normalizedDimension: frame.width
        )
        let maximumHeight = streamDimension(
            fullDimension: outputHeight,
            normalizedDimension: frame.height
        )
        if let sourceGeometry {
            return CaptureSurfaceSize.fitted(
                source: sourceGeometry,
                maximumWidth: maximumWidth,
                maximumHeight: maximumHeight
            )
        }
        return CaptureSurfaceSize.fitted(
            sourcePointWidth: filter.contentRect.width,
            sourcePointHeight: filter.contentRect.height,
            pointPixelScale: Double(filter.pointPixelScale),
            maximumWidth: maximumWidth,
            maximumHeight: maximumHeight
        )
    }

    private func streamDimension(
        fullDimension: Int,
        normalizedDimension: Double
    ) -> Int {
        let scaled = Double(fullDimension) * normalizedDimension
        let rounded = max(2, min(3840, Int(scaled.rounded())))
        // Even dimensions are friendlier to media surfaces and remain exact
        // enough for normalized layout sizing.
        return rounded.isMultiple(of: 2) ? rounded : min(3840, rounded + 1)
    }

    @discardableResult
    private func startPendingContentUpdateIfNeeded(for session: CaptureSession) -> Bool {
        guard !session.isStopping,
              !session.outputSuppressed,
              session.isStreamRunning,
              !session.source.isPaused,
              session.pauseTransition == nil,
              let pendingFilter = session.pendingFilter else { return false }
        session.pendingFilter = nil
        updateContent(of: session, with: pendingFilter)
        return true
    }

    private func applyPointerStyleToRenderersIfSafe(for session: CaptureSession) {
        guard pointerStyle == .redDot,
              !session.isStopping,
              !session.outputSuppressed,
              !session.source.isPaused,
              session.pauseTransition == nil,
              !session.isUpdatingConfiguration,
              !session.appliedShowsCursor else { return }
        // Reuse a displayed frame only when the renderer proved it arrived
        // under a cursorless configuration; otherwise wait for a later complete
        // frame instead of drawing over stale native-cursor pixels.
        session.source.renderers.commitCursorlessConfiguration(token: session.token)
    }

    private func restorePointerStyle(for session: CaptureSession) {
        guard !session.source.isPaused,
              session.pauseTransition == nil,
              !session.isStopping,
              !session.outputSuppressed else { return }
        if pointerStyle == .redDot {
            session.source.renderers.requestDeferredRedDot(token: session.token)
            applyPointerStyleToRenderersIfSafe(for: session)
        } else {
            session.source.renderers.setPointerStyle(pointerStyle)
        }
    }

    private func liveSourcePhase(for session: CaptureSession) -> CaptureSourcePhase {
        guard session.isStarted,
              session.isStreamRunning,
              !session.awaitsFreshPresentationFrame,
              session.isStreamContentActive,
              !session.isUpdatingContent,
              !session.isUpdatingConfiguration else { return .preparing }
        return session.activeAttention.map {
            .needsAttention($0.message)
        } ?? .active
    }

    private func clearPauseFailure(for session: CaptureSession) {
        guard case let .pauseFailure(message) = session.activeAttention else { return }
        session.activeAttention = nil
        if lastFailure == message { lastFailure = nil }
    }

    private func sourceMetadata(
        for filter: SCContentFilter,
        ordinal: Int
    ) -> (title: String, kind: CaptureSourceKind) {
        let kind: CaptureSourceKind
        switch filter.style {
        case .window: kind = .window
        case .application: kind = .application
        case .display: kind = .display
        case .none: kind = .unknown
        @unknown default: kind = .unknown
        }

        if #available(macOS 15.2, *) {
            switch kind {
            case .window:
                if let window = filter.includedWindows.first {
                    let appName = window.owningApplication?.applicationName
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let windowTitle = window.title?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if let windowTitle, !windowTitle.isEmpty,
                       let appName, !appName.isEmpty {
                        return ("\(appName) — \(windowTitle)", kind)
                    }
                    if let windowTitle, !windowTitle.isEmpty { return (windowTitle, kind) }
                    if let appName, !appName.isEmpty { return (appName, kind) }
                }
            case .application:
                let names = filter.includedApplications
                    .map(\.applicationName)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !names.isEmpty { return (names.joined(separator: ", "), kind) }
            case .display:
                if let display = filter.includedDisplays.first {
                    return (L10n.text(
                        "画面 \(display.width)×\(display.height)",
                        "Display \(display.width)×\(display.height)"
                    ), kind)
                }
            case .unknown:
                break
            }
        }

        return (genericSourceTitle(kind: kind, ordinal: ordinal), kind)
    }

    private func genericSourceTitle(kind: CaptureSourceKind, ordinal: Int) -> String {
        switch kind {
        case .window: L10n.text("ウインドウ \(ordinal)", "Window \(ordinal)")
        case .application: L10n.text("アプリ \(ordinal)", "App \(ordinal)")
        case .display: L10n.text("画面 \(ordinal)", "Display \(ordinal)")
        case .unknown: L10n.text("ソース \(ordinal)", "Source \(ordinal)")
        }
    }

    private func publishFailure(_ message: String) {
        guard !publishStopFailureIfPresent() else { return }
        lastFailure = message
        phase = .failed(message)
        statusDetail = message
        isCaptureActive = !sessions.isEmpty
    }

    private func publishSteadyState() {
        isCaptureActive = !sessions.isEmpty

        // A failed stop leaves that source running with both renderers hidden.
        // Keep this durable, retryable condition above the temporary picker
        // state so opening or failing another picker cannot mask it.
        if publishStopFailureIfPresent() { return }

        if isPickerPresented {
            phase = .choosing
            if pickerIntent == .invalidated {
                statusDetail = L10n.text(
                    "この選択は適用されません。システムピッカーを閉じてください。",
                    "This selection will be ignored. Close the system picker."
                )
            } else if sessions.isEmpty {
                statusDetail = L10n.text(
                    "追加する対象を1つ選んでください。",
                    "Choose one item to add."
                )
            } else {
                statusDetail = L10n.text(
                    "現在のソースを表示したまま、追加または設定する対象を選んでいます。",
                    "Current sources remain live while you choose an item to add or replace."
                )
            }
            return
        }

        if let attention = sessions.values.compactMap(\.activeAttention?.message).first {
            phase = .failed(attention)
            statusDetail = attention
            return
        }

        if sessions.values.contains(where: {
            !$0.isStarted ||
                $0.isStopping ||
                $0.pauseTransition != nil ||
                $0.isUpdatingContent ||
                $0.isUpdatingConfiguration ||
                (!$0.source.isPaused &&
                    ($0.awaitsFreshPresentationFrame || !$0.isStreamContentActive))
        }) {
            phase = .preparing
            statusDetail = L10n.text(
                "ソースを安全に準備・停止しています…",
                "Preparing or stopping sources safely…"
            )
            return
        }

        if !sessions.isEmpty {
            if let lastFailure {
                phase = .failed(lastFailure)
                statusDetail = lastFailure
            } else {
                phase = .previewing
                let pausedCount = sessions.values.count { $0.source.isPaused }
                let runningCount = sessions.count - pausedCount
                if runningCount == 0 {
                    statusDetail = L10n.text(
                        "\(pausedCount)件を一時停止中 — 最後のフレームを表示しています",
                        "\(pausedCount) source\(pausedCount == 1 ? " is" : "s are") paused — showing the last frame"
                    )
                } else if pausedCount > 0 {
                    statusDetail = L10n.text(
                        "\(runningCount)件を画面取得中・\(pausedCount)件を一時停止中",
                        "Capturing \(runningCount); \(pausedCount) paused"
                    )
                } else {
                    statusDetail = L10n.text(
                        "\(runningCount)件を画面取得中 — 保存も送信もしていません",
                        "Capturing \(runningCount) source\(runningCount == 1 ? "" : "s") — nothing is saved or sent"
                    )
                }
            }
            return
        }

        if let lastFailure {
            phase = .failed(lastFailure)
            statusDetail = lastFailure
        } else {
            phase = .idle
            statusDetail = ""
        }
    }

    @discardableResult
    private func publishStopFailureIfPresent() -> Bool {
        for source in sources {
            guard let session = sessions[source.id],
                  session.outputSuppressed,
                  case let .stopFailure(message) = session.activeAttention else { continue }
            phase = .failed(message)
            statusDetail = message
            isCaptureActive = true
            return true
        }
        return false
    }

    private func invalidatePickerIntent(ifReplacing sourceID: StageSourceID? = nil) {
        guard isPickerPresented else { return }
        switch pickerIntent {
        case .add where sourceID == nil:
            pickerIntent = .invalidated
        case let .replace(pendingID) where sourceID == nil || pendingID == sourceID:
            pickerIntent = .invalidated
        case .invalidated:
            break
        default:
            break
        }
    }

    private func finishPickerPresentation() {
        pickerIntent = nil
        isPickerPresented = false
    }
}

extension CaptureCoordinator: SCContentSharingPickerObserver {
    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didCancelFor stream: SCStream?
    ) {
        let streamBox = SendableBox(stream)
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.pickerIntent == .invalidated {
                self.finishPickerPresentation()
                self.publishSteadyState()
                return
            }
            if let callbackStream = streamBox.value {
                guard let session = self.session(for: callbackStream) else {
                    self.finishPickerPresentation()
                    self.publishSteadyState()
                    return
                }
                if self.pickerIntent == .replace(session.source.id) {
                    self.finishPickerPresentation()
                }
            } else if self.pickerIntent == .add {
                self.finishPickerPresentation()
            }
            self.publishSteadyState()
        }
    }

    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    ) {
        let filterBox = SendableBox(filter)
        let streamBox = SendableBox(stream)
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.pickerIntent == .invalidated {
                self.finishPickerPresentation()
                self.publishSteadyState()
                return
            }
            if let callbackStream = streamBox.value {
                guard let session = self.session(for: callbackStream),
                      !session.isStopping,
                      !session.outputSuppressed else {
                    self.finishPickerPresentation()
                    self.publishSteadyState()
                    return
                }
                if self.pickerIntent == .replace(session.source.id) {
                    self.finishPickerPresentation()
                }
                self.updateContent(of: session, with: filterBox.value)
            } else {
                // A nil stream with no local intent can originate from the
                // system video menu and is still an explicit user selection.
                guard self.pickerIntent == nil || self.pickerIntent == .add else {
                    self.finishPickerPresentation()
                    self.publishSteadyState()
                    return
                }
                if self.pickerIntent == .add { self.finishPickerPresentation() }
                self.beginCapture(with: filterBox.value)
            }
        }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            guard let self else { return }
            let intent = self.pickerIntent
            self.finishPickerPresentation()

            if intent == .invalidated {
                self.publishSteadyState()
                return
            }

            if case let .replace(sourceID) = intent,
               let session = self.sessions[sourceID],
               !session.isStopping {
                let activeMessage = L10n.text(
                    "選択画面を開けませんでした。「\(session.source.title)」の取得は継続中です。",
                    "The picker could not open. “\(session.source.title)” remains active."
                ) + " (\(message))"
                if case .stopFailure = session.activeAttention {
                    self.publishSteadyState()
                } else {
                    session.activeAttention = .pickerFailure(activeMessage)
                    session.source.phase = .needsAttention(activeMessage)
                    self.publishSteadyState()
                }
            } else {
                self.publishFailure(message)
            }
        }
    }
}
