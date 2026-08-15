import AppKit
import Combine
import StagePaneCore
import SwiftUI

@MainActor
final class AppController: NSObject, ObservableObject {
    @Published var preset: StagePreset {
        didSet {
            defaults.set(preset.rawValue, forKey: Keys.preset)
            stageWindowController?.applyPreset(preset, resize: true)
            capture.setOutputSize(width: preset.pixelWidth, height: preset.pixelHeight)
        }
    }

    @Published var theme: StageTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var privacyCurtain = true
    @Published var isAlwaysOnTop: Bool {
        didSet {
            defaults.set(isAlwaysOnTop, forKey: Keys.alwaysOnTop)
            stageWindowController?.applyWindowBehavior()
        }
    }

    @Published var followsAllSpaces: Bool {
        didSet {
            defaults.set(followsAllSpaces, forKey: Keys.followsAllSpaces)
            stageWindowController?.applyWindowBehavior()
        }
    }

    @Published var presentationLock: Bool {
        didSet {
            defaults.set(presentationLock, forKey: Keys.presentationLock)
            stageWindowController?.applyWindowBehavior()
        }
    }

    @Published var showsCursor: Bool {
        didSet {
            defaults.set(showsCursor, forKey: Keys.showsCursor)
            capture.setShowsCursor(showsCursor)
        }
    }

    @Published var showsSafeArea: Bool {
        didSet { defaults.set(showsSafeArea, forKey: Keys.showsSafeArea) }
    }

    @Published var showsWatermark: Bool {
        didSet { defaults.set(showsWatermark, forKey: Keys.showsWatermark) }
    }

    @Published var privacyMessage: String {
        didSet {
            let normalized = StageMessage.normalized(
                privacyMessage,
                fallback: L10n.text("少々お待ちください", "Back in a moment")
            )
            defaults.set(normalized, forKey: Keys.privacyMessage)
            if normalized != privacyMessage {
                privacyMessage = normalized
            }
        }
    }

    @Published private(set) var stageIsVisible = false
    @Published var transientNotice: String? {
        didSet {
            guard let transientNotice, transientNotice != oldValue else { return }
            AccessibilityNotification.Announcement(transientNotice).post()
        }
    }

    let capture: CaptureCoordinator

    private let defaults: UserDefaults
    private var controlWindowController: ControlRoomWindowController?
    private var stageWindowController: StageWindowController?
    private var statusItemController: StatusItemController?
    private var cancellables = Set<AnyCancellable>()
    private var previousCapturePhase: CapturePhase = .idle
    private var previousCaptureWasActive = false

    override init() {
        let defaults = UserDefaults.standard
        self.defaults = defaults
        self.preset = StagePreset(
            rawValue: defaults.string(forKey: Keys.preset) ?? ""
        ) ?? .widescreen
        self.theme = StageTheme(
            rawValue: defaults.string(forKey: Keys.theme) ?? ""
        ) ?? .aurora
        self.isAlwaysOnTop = defaults.object(forKey: Keys.alwaysOnTop) as? Bool ?? false
        self.followsAllSpaces = defaults.object(forKey: Keys.followsAllSpaces) as? Bool ?? false
        self.presentationLock = defaults.object(forKey: Keys.presentationLock) as? Bool ?? false
        self.showsCursor = defaults.object(forKey: Keys.showsCursor) as? Bool ?? true
        self.showsSafeArea = defaults.object(forKey: Keys.showsSafeArea) as? Bool ?? false
        self.showsWatermark = defaults.object(forKey: Keys.showsWatermark) as? Bool ?? false
        self.privacyMessage = StageMessage.normalized(
            defaults.string(forKey: Keys.privacyMessage) ?? "",
            fallback: L10n.text("少々お待ちください", "Back in a moment")
        )
        self.capture = CaptureCoordinator()
        super.init()
        capture.setShowsCursor(showsCursor)
        capture.setOutputSize(width: preset.pixelWidth, height: preset.pixelHeight)
        previousCapturePhase = capture.phase
        previousCaptureWasActive = capture.isCaptureActive
        capture.$phase
            .combineLatest(capture.$isCaptureActive)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink { [weak self] phase, isActive in
                self?.captureStateDidChange(phase: phase, isActive: isActive)
            }
            .store(in: &cancellables)
    }

    func start(showWindows: Bool = true) {
        let stage = StageWindowController(controller: self, capture: capture)
        let control = ControlRoomWindowController(controller: self, capture: capture)
        stageWindowController = stage
        controlWindowController = control
        statusItemController = StatusItemController(controller: self, capture: capture)

        if showWindows {
            showStage()
            showControlRoom()
        }
    }

    @MainActor
    func writeSnapshots(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try writePNG(
            of: StageDashboard(controller: self, capture: capture)
                .dashboardContent
                .frame(width: 755, alignment: .top)
                .fixedSize(horizontal: false, vertical: true)
                .background(StagePanePalette.cloud),
            to: directory.appendingPathComponent("control-room.png")
        )
        try writePNG(
            of: StageView(controller: self, capture: capture)
                .frame(width: 960, height: 540),
            to: directory.appendingPathComponent("share-stage.png")
        )
    }

    @MainActor
    private func writePNG<Content: View>(of content: Content, to url: URL) throws {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.cgImage else {
            throw SnapshotError.renderFailed
        }
        let representation = NSBitmapImageRep(cgImage: image)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
    }

    @objc func showControlRoom() {
        controlWindowController?.showWindow(nil)
        controlWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showStage() {
        stageWindowController?.showWindow(nil)
        stageWindowController?.window?.orderFront(nil)
        stageIsVisible = true
    }

    @objc func chooseSource() {
        showStage()
        capture.chooseSource()
    }

    @objc func toggleCurtain() {
        privacyCurtain.toggle()
        showStage()
        transientNotice = privacyCurtain
            ? L10n.text("共有内容をカーテンで隠しています。", "The stage is covered by the curtain.")
            : L10n.text("ステージの内容を表示しました。", "The stage content is visible.")
    }

    @objc func stopPreview() {
        guard capture.isCaptureActive else {
            let neededReset: Bool
            if case .failed = capture.phase {
                neededReset = true
            } else {
                neededReset = false
            }
            capture.stop()
            transientNotice = neededReset
                ? L10n.text(
                    "画面取得のエラー状態をリセットしました。",
                    "The capture error state was reset."
                )
                : L10n.text(
                    "現在、停止する画面取得はありません。",
                    "No screen capture is currently active."
                )
            return
        }
        privacyCurtain = true
        transientNotice = L10n.text(
            "画面取得を停止し、フレームを破棄しています…",
            "Stopping capture and discarding frames…"
        )
        // Completion announcements are derived from the atomic capture state
        // subscription below so VoiceOver receives exactly one final result.
        capture.stop()
    }

    func setPreset(_ value: StagePreset) {
        preset = value
        showStage()
    }

    func setTheme(_ value: StageTheme) {
        theme = value
    }

    func stageDidClose() {
        stageIsVisible = false
        guard capture.isCaptureActive else { return }
        privacyCurtain = true
        transientNotice = L10n.text(
            "共有ステージを閉じたため、画面取得を停止しています…",
            "The Share Stage closed; stopping capture…"
        )
        capture.stop()
    }

    func requestConferenceShare() {
        showStage()
        guard #available(macOS 15.0, *),
              let requester = controlWindowController?.window,
              let stage = stageWindowController?.window else {
            transientNotice = L10n.text(
                "会議アプリの共有画面から「StagePane Stage」を選んでください。",
                "Choose “StagePane Stage” in your meeting app's share picker."
            )
            return
        }

        requester.requestSharingOfWindow(stage) { [weak self] error in
            Task { @MainActor [weak self] in
                if let error {
                    self?.transientNotice = L10n.text(
                        "共有セッションが見つかりません。会議アプリからステージを選択してください。",
                        "No compatible share session was found. Select the Stage from your meeting app."
                    ) + " (\(error.localizedDescription))"
                } else {
                    self?.transientNotice = L10n.text(
                        "会議アプリの共有セッションへStagePane Stageを提案しました。",
                        "StagePane Stage was offered to the active meeting-app share session."
                    )
                }
            }
        }
    }

    func openScreenCaptureSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) { break }
        }
    }

    func openBundledDocument(resource: String, extension fileExtension: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
            transientNotice = L10n.text(
                "この開発ビルドには文書が同梱されていません。リポジトリ内の文書を参照してください。",
                "This development build does not contain that document. Read it in the repository."
            )
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc func openHelp() {
        openBundledDocument(resource: "HELP", extension: "md")
    }

    private func captureStateDidChange(phase: CapturePhase, isActive: Bool) {
        let previousPhase = previousCapturePhase
        let wasActive = previousCaptureWasActive
        guard phase != previousPhase || isActive != wasActive else { return }

        previousCapturePhase = phase
        previousCaptureWasActive = isActive

        if wasActive && !isActive {
            transientNotice = capturePhaseNeedsAttention(phase)
                ? L10n.text(
                    "画面取得は完全に停止しました。後処理の確認が必要です。",
                    "Capture stopped completely, but cleanup needs attention."
                )
                : L10n.text(
                    "画面取得を完全に停止しました。",
                    "Capture stopped completely."
                )
            return
        }

        if capturePhaseNeedsAttention(phase) {
            transientNotice = isActive
                ? L10n.text(
                    "画面取得で問題が発生しましたが、画面取得は継続中です。カーテンまたは停止操作を確認してください。",
                    "Capture needs attention and remains active. Check the Curtain or Stop Capture control."
                )
                : L10n.text(
                    "画面取得で問題が発生しました。停止操作で状態をリセットしてからソースを選び直してください。",
                    "Capture needs attention. Reset it with Stop Capture, then choose the source again."
                )
            return
        }

        if isActive, phase.isPreviewing, !previousPhase.isPreviewing {
            transientNotice = privacyCurtain
                ? L10n.text(
                    "画面取得を開始しました。会議アプリで「StagePane Stage」を共有し、確認してからカーテンを開いてください。",
                    "Capture started. Share “StagePane Stage” in your meeting app, confirm it, then reveal the Curtain."
                )
                : L10n.text(
                    "画面取得を開始し、ステージに表示しています。",
                    "Capture started and is visible on the Stage."
                )
        }
    }

    private func capturePhaseNeedsAttention(_ phase: CapturePhase) -> Bool {
        if case .failed = phase { return true }
        return false
    }

    @objc func terminate() {
        capture.stop()
        NSApp.terminate(nil)
    }

    private enum Keys {
        static let preset = "stage.preset"
        static let theme = "stage.theme"
        static let alwaysOnTop = "window.alwaysOnTop"
        static let followsAllSpaces = "window.followsAllSpaces"
        static let presentationLock = "window.presentationLock"
        static let showsCursor = "capture.showsCursor"
        static let showsSafeArea = "stage.showsSafeArea"
        static let showsWatermark = "stage.showsWatermark"
        static let privacyMessage = "stage.privacyMessage"
    }

    private enum SnapshotError: Error {
        case renderFailed
        case encodingFailed
    }
}
