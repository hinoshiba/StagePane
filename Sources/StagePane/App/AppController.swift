import AppKit
import Combine
import CoreGraphics
import StagePaneCore
import SwiftUI
import UniformTypeIdentifiers

enum WorkspaceSection: String, CaseIterable, Identifiable, Sendable {
    case canvas
    case sources
    case stage
    case appearance
    case permissions
    case privacy
    case about

    var id: String { rawValue }
}

@MainActor
final class AppController: NSObject, ObservableObject, NSMenuItemValidation {
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
    @Published private(set) var stageInteractionMode: StageInteractionMode = .arrange
    @Published private(set) var workspaceSection: WorkspaceSection = .canvas
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

    @Published var pointerStyle: StagePaneCore.PointerStyle {
        didSet {
            defaults.set(pointerStyle.rawValue, forKey: Keys.pointerStyle)
            capture.setPointerStyle(pointerStyle)
        }
    }

    @Published var pointerAppearance: PointerAppearance {
        didSet {
            defaults.set(pointerAppearance.diameter, forKey: Keys.pointerDiameter)
            defaults.set(pointerAppearance.color.hexRGB, forKey: Keys.pointerColor)
            defaults.set(pointerAppearance.glow, forKey: Keys.pointerGlow)
            capture.setPointerAppearance(pointerAppearance)
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
    @Published private(set) var workspaceIsVisible = false
    @Published private(set) var isStageScreenshotInProgress = false
    @Published private(set) var hasAnnotations = false
    @Published var transientNotice: String? {
        didSet {
            guard let transientNotice, transientNotice != oldValue else { return }
            AccessibilityNotification.Announcement(transientNotice).post()
        }
    }

    let capture: CaptureCoordinator
    let annotations = StageAnnotationStore()

    var annotationTool: StageInkTool { annotations.preferences.tool }

    var availableStageInteractionModes: [StageInteractionMode] { StageInteractionMode.allCases }

    private let defaults: UserDefaults
    private var workspaceWindowController: StageWorkspaceWindowController?
    private var stageWindowController: StageWindowController?
    private var pendingStageSnapshot: StageSnapshot?
    private var statusItemController: StatusItemController?
    private var cancellables = Set<AnyCancellable>()
    private var previousCapturePhase: CapturePhase = .idle
    private var previousCaptureWasActive = false
    private var awaitsInvalidatedPickerDismissal = false

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
        self.pointerStyle = StagePaneCore.PointerStyle.resolvePreference(
            storedRawValue: defaults.string(forKey: Keys.pointerStyle),
            legacyShowsCursor: defaults.object(forKey: Keys.legacyShowsCursor) as? Bool
        )
        self.pointerAppearance = PointerAppearance.resolvePreference(
            storedDiameter: (defaults.object(forKey: Keys.pointerDiameter) as? NSNumber)?.doubleValue,
            storedColorHex: defaults.string(forKey: Keys.pointerColor),
            storedGlow: (defaults.object(forKey: Keys.pointerGlow) as? NSNumber)?.doubleValue
        )
        self.showsSafeArea = defaults.object(forKey: Keys.showsSafeArea) as? Bool ?? false
        self.showsWatermark = defaults.object(forKey: Keys.showsWatermark) as? Bool ?? true
        self.privacyMessage = StageMessage.normalized(
            defaults.string(forKey: Keys.privacyMessage) ?? "",
            fallback: L10n.text("少々お待ちください", "Back in a moment")
        )
        self.capture = CaptureCoordinator()
        super.init()
        // Persist a canonical value after resolving the legacy Boolean setting.
        defaults.set(pointerStyle.rawValue, forKey: Keys.pointerStyle)
        defaults.set(pointerAppearance.diameter, forKey: Keys.pointerDiameter)
        defaults.set(pointerAppearance.color.hexRGB, forKey: Keys.pointerColor)
        defaults.set(pointerAppearance.glow, forKey: Keys.pointerGlow)
        capture.setPointerStyle(pointerStyle)
        capture.setPointerAppearance(pointerAppearance)
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
        capture.$isPickerPresented
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] isPresented in
                self?.pickerPresentationDidChange(isPresented: isPresented)
            }
            .store(in: &cancellables)
        capture.$sources
            .map(\.isEmpty)
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] isEmpty in
                guard let self, isEmpty else { return }
                annotations.removeAll()
                stageInteractionMode = .arrange
            }
            .store(in: &cancellables)
        annotations.$document
            .map { !$0.strokes.isEmpty }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] hasAnnotations in
                self?.hasAnnotations = hasAnnotations
            }
            .store(in: &cancellables)
        annotations.$preferences
            .map(\.tool)
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Only a tool change affects parent-level mode descriptions.
                // Ink points remain local to the annotation overlay so a long
                // stroke never invalidates the full Workspace hierarchy.
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func setStageInteractionMode(_ mode: StageInteractionMode) {
        guard stageInteractionMode != mode else { return }
        annotations.endStroke()
        stageInteractionMode = mode
    }

    func removeSource(
        _ sourceID: StageSourceID,
        completion: ((String?) -> Void)? = nil
    ) {
        if capture.removalLeavesNoVisibleSources(sourceID) {
            annotations.endStroke()
            annotations.removeAll()
        }
        capture.removeSource(sourceID, completion: completion)
    }

    func presentPermissionCheck() {
        workspaceSection = .permissions
        presentWorkspace()
    }

    func dismissTransientNotice() {
        transientNotice = nil
    }

    func start(showWindows: Bool = true) {
        let stage = StageWindowController(controller: self, capture: capture)
        let workspace = StageWorkspaceWindowController(controller: self, capture: capture)
        stageWindowController = stage
        workspaceWindowController = workspace
        statusItemController = StatusItemController(controller: self, capture: capture)

        if showWindows {
            showStage()
            showStageWorkspace()
        }
    }

    @MainActor
    func writeSnapshots(to directory: URL) throws {
        let originalPreset = preset
        let originalTheme = theme
        let originalAlwaysOnTop = isAlwaysOnTop
        let originalFollowsAllSpaces = followsAllSpaces
        let originalPresentationLock = presentationLock
        let originalPointerStyle = pointerStyle
        let originalPointerAppearance = pointerAppearance
        let originalShowsSafeArea = showsSafeArea
        let originalShowsWatermark = showsWatermark
        let originalPrivacyMessage = privacyMessage
        let originalCurtain = privacyCurtain
        let originalWorkspaceSection = workspaceSection
        defer {
            preset = originalPreset
            theme = originalTheme
            isAlwaysOnTop = originalAlwaysOnTop
            followsAllSpaces = originalFollowsAllSpaces
            presentationLock = originalPresentationLock
            pointerStyle = originalPointerStyle
            pointerAppearance = originalPointerAppearance
            showsSafeArea = originalShowsSafeArea
            showsWatermark = originalShowsWatermark
            privacyMessage = originalPrivacyMessage
            privacyCurtain = originalCurtain
            workspaceSection = originalWorkspaceSection
        }

        // Public assets must never depend on the developer's local defaults.
        // Pin every visible preference to the shipping presentation fixture.
        preset = .widescreen
        theme = .aurora
        isAlwaysOnTop = false
        followsAllSpaces = false
        presentationLock = false
        pointerStyle = .system
        pointerAppearance = .presentationDefault
        showsSafeArea = false
        showsWatermark = true
        privacyMessage = L10n.text("少々お待ちください", "Back in a moment")
        privacyCurtain = true

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        workspaceSection = .canvas
        try writePNG(
            of: StageWorkspaceView(controller: self, capture: capture)
                .frame(width: 1_440, height: 900),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("workspace.png")
        )
        workspaceSection = .sources
        try writePNG(
            of: StageWorkspaceView(controller: self, capture: capture)
                .frame(width: 1_440, height: 900),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("sources.png")
        )
        workspaceSection = .privacy
        try writePNG(
            of: StageWorkspaceView(controller: self, capture: capture)
                .frame(width: 1_440, height: 900),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("privacy.png")
        )
        pointerStyle = .redDot
        pointerAppearance = .presentationDefault
        workspaceSection = .appearance
        try writePNG(
            of: StageWorkspaceView(
                controller: self,
                capture: capture,
                focusesAppearanceForSnapshot: true
            )
                .frame(width: 1_440, height: 900)
                .background(StagePanePalette.cloud),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("appearance.png")
        )

        privacyCurtain = true
        try writePNG(
            of: StageView(controller: self, capture: capture)
                .frame(width: 960, height: 540),
            pointSize: CGSize(width: 960, height: 540),
            to: directory.appendingPathComponent("privacy-curtain.png")
        )
        privacyCurtain = false
        try writePNG(
            of: StageView(controller: self, capture: capture)
                .frame(width: 960, height: 540),
            pointSize: CGSize(width: 960, height: 540),
            to: directory.appendingPathComponent("stage-ready.png")
        )
    }

    @MainActor
    private func writePNG<Content: View>(
        of content: Content,
        pointSize: CGSize,
        to url: URL
    ) throws {
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = CGRect(origin: .zero, size: pointSize)

        // Render through a real AppKit window so platform-backed SwiftUI
        // controls such as NavigationSplitView, Picker, and Menu appear exactly
        // as they do in the shipping application. ImageRenderer substitutes
        // placeholders for some of those controls on macOS.
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: pointSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        window.contentView = hostingView
        window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
        window.orderFront(nil)
        defer {
            window.orderOut(nil)
            window.contentView = nil
        }

        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        let pixelWidth = Int((pointSize.width * 2).rounded())
        let pixelHeight = Int((pointSize.height * 2).rounded())
        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw SnapshotError.renderFailed
        }
        representation.size = pointSize
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        guard let image = representation.cgImage else { throw SnapshotError.renderFailed }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: image.width,
                  height: image.height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            throw SnapshotError.renderFailed
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let opaqueImage = context.makeImage() else {
            throw SnapshotError.renderFailed
        }
        let outputRepresentation = NSBitmapImageRep(cgImage: opaqueImage)
        guard let data = outputRepresentation.representation(using: .png, properties: [:]) else {
            throw SnapshotError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
    }

    @objc func closeFrontWindow() {
        if let frontWindow = NSApp.keyWindow ?? NSApp.mainWindow {
            if frontWindow === stageWindowController?.window {
                stageWindowController?.requestClose()
            } else {
                frontWindow.performClose(nil)
            }
            return
        }

        if let workspace = workspaceWindowController?.window, workspace.isVisible {
            workspace.performClose(nil)
        } else if stageWindowController?.window?.isVisible == true {
            stageWindowController?.requestClose()
        }
    }

    @objc func showStageWorkspace() {
        workspaceSection = .canvas
        presentWorkspace()
    }

    @objc func showSettings() {
        workspaceSection = .stage
        presentWorkspace()
    }

    func selectWorkspaceSection(_ section: WorkspaceSection) {
        workspaceSection = section
    }

    private func presentWorkspace() {
        if workspaceWindowController?.window?.isMiniaturized == true {
            workspaceWindowController?.window?.deminiaturize(nil)
        }
        workspaceWindowController?.showWindow(nil)
        workspaceWindowController?.window?.makeKeyAndOrderFront(nil)
        workspaceIsVisible = true
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showPermissions() {
        presentPermissionCheck()
    }

    @objc func showStage() {
        presentStage(makeKey: true)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func presentStage(makeKey: Bool) {
        if stageWindowController?.window?.isMiniaturized == true {
            stageWindowController?.window?.deminiaturize(nil)
        }
        stageWindowController?.showWindow(nil)
        if makeKey {
            stageWindowController?.window?.makeKeyAndOrderFront(nil)
        } else {
            stageWindowController?.window?.orderFront(nil)
        }
        stageIsVisible = true
    }

    @objc func chooseSource() {
        presentStage(makeKey: false)
        presentWorkspace()
        capture.addSource()
    }

    @objc func toggleCurtain() {
        privacyCurtain.toggle()
        transientNotice = privacyCurtain
            ? L10n.text("共有内容をカーテンで隠しています。", "The stage is covered by the curtain.")
            : L10n.text("ステージの内容を表示しました。", "The stage content is visible.")
    }

    @objc func copyStageScreenshot() {
        guard let snapshot = makeStageScreenshot() else { return }
        defer { isStageScreenshotInProgress = false }

        guard snapshot.copyPNG() else {
            transientNotice = L10n.text(
                "スクリーンショットをクリップボードへコピーできませんでした。",
                "The Stage screenshot could not be copied to the clipboard."
            )
            return
        }
        transientNotice = L10n.text(
            "観客向けStageを\(snapshot.pixelWidth)×\(snapshot.pixelHeight)のPNGでコピーしました。",
            "Copied the audience Stage as a \(snapshot.pixelWidth) by \(snapshot.pixelHeight) PNG."
        )
    }

    @objc func saveStageScreenshot() {
        guard let snapshot = makeStageScreenshot() else { return }
        pendingStageSnapshot = snapshot

        let panel = NSSavePanel()
        panel.title = L10n.text(
            "観客向けStageのスクリーンショットを保存",
            "Save Audience Stage Screenshot"
        )
        panel.prompt = L10n.text("保存", "Save")
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = stageScreenshotFilename()

        if let hostWindow = workspaceWindowController?.window,
           hostWindow.isVisible {
            panel.beginSheetModal(for: hostWindow) { [weak self, weak panel] response in
                let destination = panel?.url
                Task { @MainActor [weak self] in
                    self?.finishStageScreenshotSave(
                        response: response,
                        destination: destination
                    )
                }
            }
        } else {
            finishStageScreenshotSave(
                response: panel.runModal(),
                destination: panel.url
            )
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(copyStageScreenshot), #selector(saveStageScreenshot):
            return !isStageScreenshotInProgress
        case #selector(chooseSource):
            return capture.canAddSource
        case #selector(stopPreview):
            menuItem.title = capture.hasResettableFailure
                ? L10n.text("画面取得のエラーをリセット", "Reset Capture Error")
                : L10n.text("すべてのソースを停止", "Stop All Sources")
            return capture.isCaptureActive || capture.hasResettableFailure
        case #selector(toggleCurtain):
            menuItem.state = privacyCurtain ? .on : .off
            menuItem.title = L10n.text("カーテン", "Curtain")
            return true
        default:
            return true
        }
    }

    private func makeStageScreenshot() -> StageSnapshot? {
        guard !isStageScreenshotInProgress else { return nil }
        guard let window = stageWindowController?.window else {
            transientNotice = L10n.text(
                "共有Stageを準備できませんでした。",
                "The Share Stage is not available."
            )
            return nil
        }

        isStageScreenshotInProgress = true
        do {
            return try StageWindowSnapshotter.capture(
                window: window,
                outputSize: StageSnapshotSize(preset: preset)
            )
        } catch {
            isStageScreenshotInProgress = false
            transientNotice = L10n.text(
                "Stageの画像を作成できませんでした。ソースの最初の映像を待ってから、もう一度お試しください。",
                "The Stage image could not be created. Wait for the source's first frame, then try again."
            ) + " (\(error.localizedDescription))"
            return nil
        }
    }

    private func finishStageScreenshotSave(
        response: NSApplication.ModalResponse,
        destination: URL?
    ) {
        defer {
            pendingStageSnapshot = nil
            isStageScreenshotInProgress = false
        }
        guard response == .OK else { return }
        guard let snapshot = pendingStageSnapshot, let destination else {
            transientNotice = L10n.text(
                "スクリーンショットの保存先を確認できませんでした。",
                "The screenshot destination could not be determined."
            )
            return
        }
        do {
            try snapshot.writePNG(to: destination)
            transientNotice = L10n.text(
                "観客向けStageのPNGを保存しました。",
                "Saved the audience Stage PNG."
            )
        } catch {
            transientNotice = L10n.text(
                "スクリーンショットを保存できませんでした。",
                "The Stage screenshot could not be saved."
            ) + " (\(error.localizedDescription))"
        }
    }

    private func stageScreenshotFilename() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return "StagePane \(formatter.string(from: Date())).png"
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
                    "現在、停止するソースはありません。",
                    "No sources are currently active."
                )
            return
        }
        privacyCurtain = true
        transientNotice = L10n.text(
            "すべてのソースを停止し、フレームを破棄しています…",
            "Stopping every source and discarding frames…"
        )
        // Completion announcements are derived from the atomic capture state
        // subscription below so VoiceOver receives exactly one final result.
        capture.stop()
    }

    func setPreset(_ value: StagePreset) {
        preset = value
        presentStage(makeKey: false)
    }

    func setTheme(_ value: StageTheme) {
        theme = value
    }

    func stageDidClose() {
        stageIsVisible = false
        guard capture.isCaptureActive || capture.isPickerPresented else { return }
        privacyCurtain = true
        if capture.isPickerPresented, !capture.isCaptureActive {
            awaitsInvalidatedPickerDismissal = true
            transientNotice = L10n.text(
                "共有ステージを閉じました。選択内容は適用されないため、システムピッカーを閉じてください。",
                "The Share Stage closed. This selection will not be applied; close the system picker."
            )
        } else {
            transientNotice = L10n.text(
                "共有ステージを閉じたため、画面取得を停止しています…",
                "The Share Stage closed; stopping capture…"
            )
        }
        capture.stop()
    }

    func workspaceDidClose() {
        workspaceDidBecomeHidden()
    }

    func workspaceDidBecomeHidden() {
        workspaceIsVisible = false
        annotations.endStroke()
    }

    func workspaceDidBecomeVisible() {
        workspaceIsVisible = true
    }

    func stageDidBecomeVisible() {
        stageIsVisible = true
    }

    func stageDidBecomeHidden() {
        stageIsVisible = false
    }

    func requestConferenceShare() {
        let requester = workspaceWindowController?.window.flatMap { window in
            window.isVisible ? window : nil
        }

        presentStage(makeKey: false)
        guard #available(macOS 15.0, *),
              let requester,
              let stage = stageWindowController?.window else {
            transientNotice = L10n.text(
                "会議アプリの共有画面から「StagePane Stage」を選んでください。必要な場合はWorkspaceを開いてからもう一度お試しください。",
                "Choose “StagePane Stage” in your meeting app's share picker. If needed, open Workspace and try again."
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

    @objc func openPrivacyPolicy() {
        openExternalPage(
            URL(string: L10n.text(
                "https://stagepane.hinoshiba.com/privacy/",
                "https://stagepane.hinoshiba.com/en/privacy/"
            )),
            fallbackResource: "PRIVACY",
            fallbackExtension: "md"
        )
    }

    @objc func openSupport() {
        openExternalPage(
            URL(string: L10n.text(
                "https://stagepane.hinoshiba.com/#support",
                "https://stagepane.hinoshiba.com/en/#support"
            )),
            fallbackResource: "HELP",
            fallbackExtension: "md"
        )
    }

    private func openExternalPage(
        _ url: URL?,
        fallbackResource: String,
        fallbackExtension: String
    ) {
        if let url, NSWorkspace.shared.open(url) { return }
        openBundledDocument(resource: fallbackResource, extension: fallbackExtension)
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
                    "すべてのソースを完全に停止しました。",
                    "All sources stopped completely."
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
                    "画面取得で問題が発生しました。「画面取得をリセット」してからソースを選び直してください。",
                    "Capture needs attention. Choose Reset Capture, then add the source again."
                )
            return
        }

        if isActive, !wasActive {
            transientNotice = privacyCurtain
                ? L10n.text(
                    "ソースを追加し、画面取得を準備しています。会議アプリでは「StagePane Stage」を共有し、確認してからカーテンを開いてください。",
                    "A source was added and capture is being prepared. Share “StagePane Stage” in your meeting app, confirm it, then reveal the Curtain."
                )
                : L10n.text(
                    "ソースを追加し、ステージへの表示を準備しています。",
                    "A source was added and is being prepared for the Stage."
                )
        }
    }

    private func capturePhaseNeedsAttention(_ phase: CapturePhase) -> Bool {
        if case .failed = phase { return true }
        return false
    }

    private func pickerPresentationDidChange(isPresented: Bool) {
        guard !isPresented, awaitsInvalidatedPickerDismissal else { return }
        awaitsInvalidatedPickerDismissal = false
        transientNotice = L10n.text(
            "保留中のソース選択を適用せず終了しました。",
            "The pending source selection ended without being applied."
        )
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
        static let pointerStyle = "capture.pointerStyle"
        static let legacyShowsCursor = "capture.showsCursor"
        static let pointerDiameter = "capture.pointerDiameter"
        static let pointerColor = "capture.pointerColor"
        static let pointerGlow = "capture.pointerGlow"
        static let showsSafeArea = "stage.showsSafeArea"
        static let showsWatermark = "stage.showsWatermark"
        static let privacyMessage = "stage.privacyMessage"
    }

    private enum SnapshotError: Error {
        case renderFailed
        case encodingFailed
    }
}
