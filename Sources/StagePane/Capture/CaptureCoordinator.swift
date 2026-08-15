import AppKit
import Combine
import CoreMedia
import CoreVideo
import ScreenCaptureKit

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

/// A stream-specific output/delegate object prevents callbacks from a retiring
/// stream from being mistaken for frames belonging to its replacement.
private final class CaptureStreamProxy: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    typealias StopHandler = @Sendable (UUID, SendableBox<SCStream>, StreamStopFailure) -> Void

    let token: UUID
    private let renderer: SampleBufferRenderer
    private let stopHandler: StopHandler

    init(token: UUID, renderer: SampleBufferRenderer, stopHandler: @escaping StopHandler) {
        self.token = token
        self.renderer = renderer
        self.stopHandler = stopHandler
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }
        renderer.enqueue(sampleBuffer, token: token)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        stopHandler(token, SendableBox(stream), StreamStopFailure(error))
    }
}

@MainActor
private final class CaptureSession {
    enum TeardownOutcome: Sendable {
        case idle
        case failed(String)
    }

    enum ActiveAttention {
        case stopFailure(String)
        case pickerFailure(String)

        var message: String {
            switch self {
            case let .stopFailure(message), let .pickerFailure(message):
                message
            }
        }

        var clearsAfterSuccessfulContentUpdate: Bool {
            if case .pickerFailure = self { return true }
            return false
        }
    }

    let token: UUID
    let stream: SCStream
    let proxy: CaptureStreamProxy
    var isStarted = false
    var startDidFail = false
    var isStopping = false
    var isUpdatingContent = false
    var isUpdatingConfiguration = false
    var appliedConfigurationRevision: Int
    var teardownOutcome: TeardownOutcome?
    var activeAttention: ActiveAttention?
    var stopCompletions: [(String?) -> Void] = []

    init(
        token: UUID,
        stream: SCStream,
        proxy: CaptureStreamProxy,
        appliedConfigurationRevision: Int
    ) {
        self.token = token
        self.stream = stream
        self.proxy = proxy
        self.appliedConfigurationRevision = appliedConfigurationRevision
    }
}

/// Bridges Apple's consent-preserving content picker to a local-only preview.
///
/// There is deliberately no recorder, encoder, network client, or persistence
/// path in this type. Capture lifecycle and observable state are isolated to the
/// main actor; frame delivery stays on one bounded serial queue.
@MainActor
final class CaptureCoordinator: NSObject, ObservableObject {
    @Published private(set) var phase: CapturePhase = .idle
    @Published private(set) var statusDetail = ""
    /// Conservative privacy truth: remains true throughout an in-flight stop
    /// and becomes false only after stop, output removal, drain, and flush.
    @Published private(set) var isCaptureActive = false

    let renderer: SampleBufferRenderer

    private let outputQueue: DispatchQueue
    private var session: CaptureSession?
    private var showsCursor = true
    private var outputWidth = 1920
    private var outputHeight = 1080
    private var configurationRevision = 0

    override init() {
        let queue = DispatchQueue(
            label: "app.stagepane.capture.video",
            qos: .userInteractive
        )
        self.outputQueue = queue
        self.renderer = SampleBufferRenderer(renderQueue: queue)
        super.init()

        let picker = SCContentSharingPicker.shared
        var pickerConfiguration = SCContentSharingPickerConfiguration()
        pickerConfiguration.allowedPickerModes = [.singleWindow, .singleApplication, .singleDisplay]
        pickerConfiguration.excludedBundleIDs = Bundle.main.bundleIdentifier.map { [$0] } ?? []
        pickerConfiguration.allowsChangingSelectedContent = true
        picker.defaultConfiguration = pickerConfiguration
        picker.maximumStreamCount = 1
        picker.add(self)
        picker.isActive = true
    }

    deinit {
        SCContentSharingPicker.shared.remove(self)
    }

    func chooseSource() {
        guard session?.isStopping != true else {
            statusDetail = L10n.text(
                "停止処理が完了してからソースを選んでください。",
                "Wait for capture to stop before choosing another source."
            )
            return
        }

        if let session, publishActiveAttentionIfNeeded(for: session) {
            // Stop/picker failures remain visible while the picker is open.
        } else {
            phase = .choosing
            statusDetail = L10n.text(
                "macOSの選択画面で、映したい対象を選んでください。",
                "Choose what to place on the stage in the macOS picker."
            )
        }

        if let stream = session?.stream {
            SCContentSharingPicker.shared.present(for: stream)
        } else {
            SCContentSharingPicker.shared.present()
        }
    }

    func stop(completion: ((String?) -> Void)? = nil) {
        guard let session else {
            renderer.flush()
            isCaptureActive = false
            phase = .idle
            statusDetail = ""
            completion?(nil)
            return
        }
        beginTeardown(of: session, outcome: .idle, completion: completion)
    }

    func setShowsCursor(_ value: Bool) {
        guard showsCursor != value else { return }
        showsCursor = value
        configurationRevision &+= 1
        updateConfigurationIfNeeded()
    }

    func setOutputSize(width: Int, height: Int) {
        guard width > 0, height > 0 else { return }
        // Current presets top out at 1920 pixels. This defensive ceiling keeps
        // future/custom values from silently creating an excessive IOSurface.
        let boundedWidth = min(width, 3840)
        let boundedHeight = min(height, 3840)
        guard outputWidth != boundedWidth || outputHeight != boundedHeight else { return }
        outputWidth = boundedWidth
        outputHeight = boundedHeight
        configurationRevision &+= 1
        updateConfigurationIfNeeded()
    }

    private func beginCapture(with filter: SCContentFilter) {
        phase = .preparing
        statusDetail = L10n.text("プレビューを準備しています…", "Preparing the preview…")

        let token = UUID()
        let proxy = CaptureStreamProxy(token: token, renderer: renderer) { [weak self] token, streamBox, failure in
            Task { @MainActor [weak self] in
                self?.handleUnexpectedStop(token: token, stream: streamBox.value, failure: failure)
            }
        }
        let configuration = makeConfiguration()
        let stream = SCStream(filter: filter, configuration: configuration, delegate: proxy)

        do {
            try stream.addStreamOutput(proxy, type: .screen, sampleHandlerQueue: outputQueue)
        } catch {
            renderer.flush()
            isCaptureActive = false
            phase = .failed(error.localizedDescription)
            statusDetail = error.localizedDescription
            return
        }

        let newSession = CaptureSession(
            token: token,
            stream: stream,
            proxy: proxy,
            appliedConfigurationRevision: configurationRevision
        )
        session = newSession
        // Mark active conservatively as soon as capture startup is requested.
        isCaptureActive = true
        renderer.activate(token: token)

        let streamBox = SendableBox(stream)
        stream.startCapture { [weak self] error in
            let message = error?.localizedDescription
            Task { @MainActor [weak self] in
                self?.handleStartCompletion(
                    token: token,
                    stream: streamBox.value,
                    errorMessage: message
                )
            }
        }
    }

    private func updateContent(of session: CaptureSession, with filter: SCContentFilter) {
        guard !session.isStopping, !session.isUpdatingContent else { return }
        session.isUpdatingContent = true
        if !publishActiveAttentionIfNeeded(for: session) {
            phase = .preparing
            statusDetail = L10n.text("ソースを安全に切り替えています…", "Switching sources safely…")
        }

        let token = session.token
        let streamBox = SendableBox(session.stream)
        let filterBox = SendableBox(filter)
        renderer.deactivate(token: token) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self,
                      let current = self.session,
                      current.token == token,
                      current.stream === streamBox.value,
                      !current.isStopping else { return }

                do {
                    try await streamBox.value.updateContentFilter(filterBox.value)
                    self.handleContentUpdateCompletion(
                        token: token,
                        stream: streamBox.value,
                        errorMessage: nil
                    )
                } catch {
                    self.handleContentUpdateCompletion(
                        token: token,
                        stream: streamBox.value,
                        errorMessage: error.localizedDescription
                    )
                }
            }
        }
    }

    private func handleStartCompletion(token: UUID, stream: SCStream, errorMessage: String?) {
        guard let session, session.token == token, session.stream === stream else { return }
        if let errorMessage {
            session.startDidFail = true
            beginTeardown(of: session, outcome: .failed(errorMessage))
            return
        }

        session.isStarted = true
        // A Stop request may have raced the asynchronous start. Its teardown
        // owns the state until stopCapture completes, and a prior stop failure
        // must remain visible as attention rather than being overwritten.
        guard !session.isStopping else { return }
        if publishActiveAttentionIfNeeded(for: session) { return }
        phase = .previewing
        statusDetail = L10n.text(
            "画面取得中 — 保存も送信もしていません",
            "Capture active — nothing is saved or sent"
        )
        updateConfigurationIfNeeded()
    }

    private func handleContentUpdateCompletion(token: UUID, stream: SCStream, errorMessage: String?) {
        guard let session,
              session.token == token,
              session.stream === stream else { return }
        session.isUpdatingContent = false
        // Teardown owns both the UI state and the final renderer flush. A late
        // content-update callback must never reactivate the layer while stopping.
        guard !session.isStopping else { return }
        if let errorMessage {
            beginTeardown(of: session, outcome: .failed(errorMessage))
            return
        }

        renderer.activate(token: token)
        if session.activeAttention?.clearsAfterSuccessfulContentUpdate == true {
            session.activeAttention = nil
        }
        // A Stop failure remains visible even though an in-flight content
        // switch subsequently succeeded. A picker failure is recovered by the
        // successful switch above.
        if publishActiveAttentionIfNeeded(for: session) {
            updateConfigurationIfNeeded()
            return
        }
        phase = .previewing
        statusDetail = L10n.text(
            "画面取得中 — 保存も送信もしていません",
            "Capture active — nothing is saved or sent"
        )
        updateConfigurationIfNeeded()
    }

    private func updateConfigurationIfNeeded() {
        guard let session,
              session.isStarted,
              !session.isStopping,
              !session.isUpdatingContent,
              !session.isUpdatingConfiguration,
              session.appliedConfigurationRevision != configurationRevision else { return }

        let targetRevision = configurationRevision
        let configuration = makeConfiguration()
        let token = session.token
        let streamBox = SendableBox(session.stream)
        session.isUpdatingConfiguration = true

        streamBox.value.updateConfiguration(configuration) { [weak self] error in
            let message = error?.localizedDescription
            Task { @MainActor [weak self] in
                guard let self,
                      let current = self.session,
                      current.token == token,
                      current.stream === streamBox.value else { return }
                current.isUpdatingConfiguration = false
                if let message {
                    self.beginTeardown(of: current, outcome: .failed(message))
                    return
                }
                current.appliedConfigurationRevision = targetRevision
                self.updateConfigurationIfNeeded()
            }
        }
    }

    private func beginTeardown(
        of target: CaptureSession,
        outcome: CaptureSession.TeardownOutcome,
        completion: ((String?) -> Void)? = nil
    ) {
        guard session === target else { return }
        if let completion { target.stopCompletions.append(completion) }
        if target.isStopping {
            if case .failed = outcome { target.teardownOutcome = outcome }
            return
        }

        target.isStopping = true
        target.teardownOutcome = outcome
        switch outcome {
        case .idle:
            statusDetail = L10n.text(
                "画面取得を停止し、フレームを破棄しています…",
                "Stopping capture and discarding frames…"
            )
        case let .failed(message):
            phase = .failed(message)
            statusDetail = message + " " + L10n.text(
                "安全のため画面取得を停止しています…",
                "Stopping capture for safety…"
            )
        }
        // `isCaptureActive` intentionally stays true until teardown completes.
        renderer.deactivate(token: target.token)

        let token = target.token
        let streamBox = SendableBox(target.stream)
        streamBox.value.stopCapture { [weak self] error in
            let message = error?.localizedDescription
            Task { @MainActor [weak self] in
                self?.handleStopCompletion(
                    token: token,
                    stream: streamBox.value,
                    errorMessage: message
                )
            }
        }
    }

    private func handleStopCompletion(token: UUID, stream: SCStream, errorMessage: String?) {
        guard let session, session.token == token, session.stream === stream else { return }
        if let errorMessage {
            if session.isStarted || !session.startDidFail {
                let callbacks = session.stopCompletions
                session.stopCompletions.removeAll()
                session.isStopping = false
                session.teardownOutcome = nil
                renderer.activate(token: token)
                isCaptureActive = true
                let message = L10n.text(
                    "停止できませんでした。画面取得は継続中です。もう一度停止してください。",
                    "Capture could not stop and remains active. Try Stop Capture again."
                ) + " (\(errorMessage))"
                session.activeAttention = .stopFailure(message)
                phase = .failed(message)
                statusDetail = message
                callbacks.forEach { $0(message) }
            } else {
                // Startup never completed, so there is no live capture to
                // restore. Still treat renderer deactivation as an ordered
                // barrier before publishing the inactive state or completing
                // callers; this keeps the teardown invariant true on errors.
                try? stream.removeStreamOutput(session.proxy, type: .screen)
                renderer.deactivate(token: token) { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self,
                              let current = self.session,
                              current === session else { return }
                        self.finishStoppedSession(current, outcome: .failed(errorMessage))
                    }
                }
            }
            return
        }

        var outcome = session.teardownOutcome ?? .idle
        do {
            try stream.removeStreamOutput(session.proxy, type: .screen)
        } catch {
            // Capture is already stopped. Preserve the cleanup error for the UI,
            // but still drain and release the stopped stream safely.
            let message = L10n.text(
                "画面取得は停止しましたが、出力の後処理に失敗しました。",
                "Capture stopped, but output cleanup failed."
            ) + " (\(error.localizedDescription))"
            outcome = .failed(message)
        }

        let finalOutcome = outcome
        renderer.deactivate(token: token) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self,
                      let current = self.session,
                      current === session else { return }
                self.finishStoppedSession(current, outcome: finalOutcome)
            }
        }
    }

    private func finishStoppedSession(
        _ stoppedSession: CaptureSession,
        outcome: CaptureSession.TeardownOutcome
    ) {
        guard session === stoppedSession else { return }
        let callbacks = stoppedSession.stopCompletions
        session = nil
        switch outcome {
        case .idle:
            phase = .idle
            statusDetail = ""
        case let .failed(message):
            phase = .failed(message)
            statusDetail = message
        }
        // Publish the final phase/status first. Until this last write the UI
        // remains conservatively active, never momentarily inactive with a
        // stale previewing phase.
        isCaptureActive = false
        switch outcome {
        case .idle:
            callbacks.forEach { $0(nil) }
        case let .failed(message):
            callbacks.forEach { $0(message) }
        }
    }

    private func handleUnexpectedStop(token: UUID, stream: SCStream, failure: StreamStopFailure) {
        guard let session, session.token == token, session.stream === stream else { return }
        session.isStopping = true
        var outcome: CaptureSession.TeardownOutcome
        if failure.isUserStopped {
            // Preserve a safety/configuration failure that was already driving
            // teardown; otherwise a user stop from the system picker is normal.
            outcome = session.teardownOutcome ?? .idle
        } else {
            outcome = .failed(failure.message)
        }
        do {
            try stream.removeStreamOutput(session.proxy, type: .screen)
        } catch {
            let message = L10n.text(
                "画面取得は停止しましたが、出力の後処理に失敗しました。",
                "Capture stopped, but output cleanup failed."
            ) + " (\(error.localizedDescription))"
            outcome = .failed(message)
        }
        let finalOutcome = outcome
        renderer.deactivate(token: token) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self,
                      let current = self.session,
                      current === session else { return }
                self.finishStoppedSession(current, outcome: finalOutcome)
            }
        }
    }

    private func makeConfiguration() -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        configuration.width = outputWidth
        configuration.height = outputHeight
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.queueDepth = 3
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.scalesToFit = true
        configuration.preservesAspectRatio = true
        configuration.showsCursor = showsCursor
        configuration.capturesAudio = false
        configuration.backgroundColor = NSColor.black.cgColor
        configuration.shouldBeOpaque = true
        configuration.ignoreShadowsSingleWindow = true
        configuration.ignoreGlobalClipSingleWindow = true
        configuration.captureResolution = .best
        configuration.streamName = "StagePane Local Preview"
        if #available(macOS 14.2, *) {
            configuration.includeChildWindows = true
        }
        return configuration
    }

    @discardableResult
    private func publishActiveAttentionIfNeeded(for session: CaptureSession) -> Bool {
        guard let attention = session.activeAttention else { return false }
        phase = .failed(attention.message)
        statusDetail = attention.message
        return true
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
            if let current = self.session, current.stream === streamBox.value {
                guard !current.isStopping else { return }
                if self.publishActiveAttentionIfNeeded(for: current) { return }
                self.phase = .previewing
                self.statusDetail = L10n.text(
                    "現在の画面取得を続けています。",
                    "Keeping the current capture active."
                )
            } else if self.session == nil {
                if case .failed = self.phase { return }
                self.phase = .idle
                self.statusDetail = ""
            }
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
            if let callbackStream = streamBox.value {
                guard let current = self.session, current.stream === callbackStream else { return }
                self.updateContent(of: current, with: filterBox.value)
            } else if self.session == nil {
                self.beginCapture(with: filterBox.value)
            }
        }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let current = self.session, current.isStopping {
                return
            } else if let current = self.session, self.isCaptureActive {
                let activeMessage = L10n.text(
                    "選択画面を開けませんでした。現在の画面取得は継続中です。",
                    "The picker could not open. The current capture remains active."
                ) + " (\(message))"
                if case .stopFailure = current.activeAttention {
                    // A picker failure must not downgrade the stronger privacy
                    // warning that an earlier Stop attempt did not succeed.
                    self.publishActiveAttentionIfNeeded(for: current)
                } else {
                    current.activeAttention = .pickerFailure(activeMessage)
                    self.phase = .failed(activeMessage)
                    self.statusDetail = activeMessage
                }
            } else {
                self.phase = .failed(message)
                self.statusDetail = message
            }
        }
    }
}
