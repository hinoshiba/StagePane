import AppKit
import Combine
import CoreGraphics
import StagePaneCore
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

enum WorkspaceSection: String, CaseIterable, Identifiable, Sendable {
    case canvas
    case sources
    case stage
    case appearance
    case pro
    case permissions
    case privacy
    case about

    var id: String { rawValue }
}

enum ProUpgradeTrigger: Equatable, Sendable {
    case direct
    case sourceLimit
    case watermark
}

/// A source failure stays readable until dismissed or that operation recovers.
/// An unrelated source update or a canceled picker is not recovery.
struct CaptureAccessIssueNotice: Identifiable {
    let id = UUID()
    let issue: CaptureAccessIssue
    let sourceIDsAtFailure: Set<StageSourceID>

    func isResolved(currentSourceIDs: Set<StageSourceID>, readySourceIDs: Set<StageSourceID>) -> Bool {
        if let sourceID = issue.sourceID {
            return !currentSourceIDs.contains(sourceID) || readySourceIDs.contains(sourceID)
        }
        return !readySourceIDs.subtracting(sourceIDsAtFailure).isEmpty
    }
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
    @Published private(set) var stageRenderingSize: CGSize?
    @Published private(set) var stageIsFullScreen = false
    @Published private(set) var stageFullScreenTransitionInProgress = false
    @Published private(set) var stageInteractionMode: StageInteractionMode = .arrange
    /// Private editing focus; selecting a layer never changes audience stacking.
    @Published private(set) var selectedSourceID: StageSourceID?
    @Published private(set) var cropEditingSourceID: StageSourceID?
    @Published private(set) var cropDraft: NormalizedSourceRect?
    @Published private(set) var workspaceSection: WorkspaceSection = .appearance
    @Published var isStageSettingsPresented = false
    @Published private(set) var captureAccessIssueNotice: CaptureAccessIssueNotice?
    @Published private(set) var hasMacScreenRecordingAccess = false
    @Published private(set) var hasRequestedMacScreenRecordingAccess = false
    @Published private(set) var proWindowIsVisible = false
    @Published var isAlwaysOnTop: Bool {
        didSet {
            beginWorkspaceInteraction()
            defaults.set(isAlwaysOnTop, forKey: Keys.alwaysOnTop)
            stageWindowController?.applyWindowBehavior()
        }
    }

    @Published var followsAllSpaces: Bool {
        didSet {
            beginWorkspaceInteraction()
            defaults.set(followsAllSpaces, forKey: Keys.followsAllSpaces)
            stageWindowController?.applyWindowBehavior()
        }
    }

    @Published var presentationLock: Bool {
        didSet {
            beginWorkspaceInteraction()
            defaults.set(presentationLock, forKey: Keys.presentationLock)
            stageWindowController?.applyWindowBehavior()
        }
    }

    @Published var pointerStyle: StagePaneCore.PointerStyle {
        didSet {
            defaults.set(pointerStyle.rawValue, forKey: Keys.pointerStyle)
            capture.setPointerStyle(effectivePointerStyle)
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

    @Published private var prefersWatermark: Bool {
        didSet { defaults.set(prefersWatermark, forKey: Keys.showsWatermark) }
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

    @Published var privacyMessageSize: Int {
        didSet {
            let normalized = StageMessage.normalizedTextSize(privacyMessageSize)
            defaults.set(normalized, forKey: Keys.privacyMessageSize)
            if normalized != privacyMessageSize {
                privacyMessageSize = normalized
            }
        }
    }

    @Published private(set) var stageIsVisible = false
    @Published private(set) var stageIsMiniaturized = false
    @Published private(set) var workspaceIsVisible = false
    @Published private(set) var isStageScreenshotInProgress = false
    @Published private(set) var hasAnnotations = false
    @Published private(set) var proUpgradeTrigger: ProUpgradeTrigger = .direct
    @Published private(set) var transientNoticeState = TransientNoticeState()
    var transientNotice: String? {
        get { transientNoticeState.notice?.message }
        set {
            guard let newValue else {
                dismissTransientNotice()
                return
            }
            presentTransientNotice(newValue)
        }
    }

    let capture: CaptureCoordinator
    let purchases: ProPurchaseStore
    let annotations = StageAnnotationStore()
    let magnifier = StageMagnifierStore()

    var annotationTool: StageInkTool { annotations.preferences.tool }
    var isAudiencePointerSuppressedByInteractionMode: Bool {
        stageInteractionMode.suppressesAudiencePointer
    }

    var availableStageInteractionModes: [StageInteractionMode] { StageInteractionMode.allCases }

    var hasProAccess: Bool { purchases.hasProAccess }

    var activeSourceLimit: Int? {
        StagePaneAccess.sourceLimit(hasProAccess: hasProAccess)
    }

    var activeSourceLimitDescription: String {
        activeSourceLimit.map(String.init) ?? "∞"
    }

    func sourceCountAccessibilityDescription(_ count: Int) -> String {
        let englishSource = count == 1 ? "source" : "sources"
        guard let activeSourceLimit else {
            return L10n.text(
                "\(count)件、StagePaneによる上限なし",
                "\(count) \(englishSource), no app-imposed limit"
            )
        }
        if count > activeSourceLimit {
            return L10n.text(
                "\(count)件、無料版の上限\(activeSourceLimit)件",
                "\(count) \(englishSource); Free limit \(activeSourceLimit)"
            )
        }
        return L10n.text(
            "\(count)件、無料版の上限\(activeSourceLimit)件",
            "\(count) of \(activeSourceLimit) sources"
        )
    }

    var canRequestSourceAddition: Bool {
        capture.canRequestSourceAddition
    }

    var showsWatermark: Bool {
        get {
            StagePaneAccess.showsWatermark(
                preference: prefersWatermark,
                hasProAccess: hasProAccess
            )
        }
        set {
            if newValue || hasProAccess {
                prefersWatermark = newValue
            }
        }
    }

    private var effectivePointerStyle: StagePaneCore.PointerStyle {
        stageInteractionMode.audiencePointerStyle(preferred: pointerStyle)
    }

    private let defaults: UserDefaults
    private var workspaceWindowController: StageWorkspaceWindowController?
    private var stageWindowController: StageWindowController?
    private var settingsWindowController: StagePrivateWindowController?
    private var permissionsWindowController: StagePrivateWindowController?
    private var macScreenRecordingAccessWindowController: StagePrivateWindowController?
    private var checksMacScreenRecordingAccess = false
    private var proWindowController: StagePrivateWindowController?
    private var pendingStageSnapshot: StageSnapshot?
    private var stopAllConfirmationAlert: NSAlert?
    private var statusItemController: StatusItemController?
    private var cancellables = Set<AnyCancellable>()
    private var previousCapturePhase: CapturePhase = .idle
    private var previousCaptureWasActive = false
    private var activeSessionStartedAt: Date?
    private var activeSessionReachedPreview = false
    private var previousHasProAccess = false
    private var pendingProContinuation = false
    private var proContinuationID: UUID?
    private var reviewRequestIsScheduled = false
    private var transientNoticeDismissalTask: Task<Void, Never>?

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
        self.prefersWatermark = defaults.object(forKey: Keys.showsWatermark) as? Bool ?? true
        self.privacyMessage = StageMessage.normalized(
            defaults.string(forKey: Keys.privacyMessage) ?? "",
            fallback: L10n.text("少々お待ちください", "Back in a moment")
        )
        self.privacyMessageSize = StageMessage.normalizedTextSize(
            defaults.object(forKey: Keys.privacyMessageSize) as? Int ?? StageMessage.defaultTextSize
        )
        self.purchases = ProPurchaseStore()
        self.capture = CaptureCoordinator()
        super.init()
        // Persist a canonical value after resolving the legacy Boolean setting.
        defaults.set(pointerStyle.rawValue, forKey: Keys.pointerStyle)
        defaults.set(pointerAppearance.diameter, forKey: Keys.pointerDiameter)
        defaults.set(pointerAppearance.color.hexRGB, forKey: Keys.pointerColor)
        defaults.set(pointerAppearance.glow, forKey: Keys.pointerGlow)
        capture.setPointerStyle(effectivePointerStyle)
        capture.setPointerAppearance(pointerAppearance)
        capture.setOutputSize(width: preset.pixelWidth, height: preset.pixelHeight)
        capture.setAllowedSourceLimit(activeSourceLimit)
        capture.sourceLimitReachedHandler = { [weak self] in
            self?.presentProUpgrade(trigger: .sourceLimit)
        }
        capture.sourceAccessIssueHandler = { [weak self] issue in
            // Keep source failures in the editor; they do not establish that
            // app-wide Screen Recording permission is missing.
            self?.presentCaptureAccessIssue(issue)
        }
        previousHasProAccess = hasProAccess
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
        capture.$sources
            .map(\.isEmpty)
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] isEmpty in
                guard let self, isEmpty else { return }
                annotations.removeAll()
                setStageInteractionMode(.arrange)
            }
            .store(in: &cancellables)
        capture.$sources
            .map { $0.map(\.id) }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] sourceIDs in
                guard let self else { return }
                if let selectedSourceID,
                   !sourceIDs.contains(selectedSourceID),
                   capture.source(for: selectedSourceID) == nil {
                    self.selectedSourceID = nil
                }
                guard let cropEditingSourceID,
                      !sourceIDs.contains(cropEditingSourceID) else { return }
                discardCropEditing(announce: false)
                setStageInteractionMode(.arrange)
                transientNotice = L10n.cropSourceUnavailableNotice
            }
            .store(in: &cancellables)
        purchases.$entitlementState
            .combineLatest(purchases.$operationState)
            .removeDuplicates { previous, current in
                previous.0 == current.0 && previous.1 == current.1
            }
            .sink { [weak self] entitlementState, operationState in
                guard let self else { return }
                // @Published sends from willSet. Apply the emitted entitlement
                // in this same main-actor turn so a refund cannot leave a
                // one-run-loop window in the system video menu.
                let nowHasProAccess = entitlementState == .pro ||
                    entitlementState == .sourceBuild
                let gainedProAccess = !previousHasProAccess && nowHasProAccess
                previousHasProAccess = nowHasProAccess
                capture.setAllowedSourceLimit(
                    StagePaneAccess.sourceLimit(hasProAccess: nowHasProAccess)
                )
                objectWillChange.send()
                if !nowHasProAccess {
                    pendingProContinuation = false
                    return
                }
                if gainedProAccess, proWindowIsVisible, proContinuationID != nil {
                    pendingProContinuation = true
                }
                guard pendingProContinuation,
                      operationState == .idle,
                      proWindowIsVisible,
                      let continuationID = proContinuationID else { return }
                pendingProContinuation = false
                // Allow the StoreKit sheet to dismiss before returning to the
                // original action. Recheck its identity after that turn: closing
                // Pro or beginning another task invalidates this continuation.
                DispatchQueue.main.async { [weak self] in
                    guard let self,
                          self.hasProAccess,
                          self.proWindowIsVisible,
                          self.proContinuationID == continuationID else { return }
                    let trigger = self.proUpgradeTrigger
                    self.beginWorkspaceInteraction()
                    switch trigger {
                    case .sourceLimit:
                        guard self.canRequestSourceAddition else { return }
                        self.proWindowController?.close()
                        self.chooseSource()
                    case .watermark:
                        self.prefersWatermark = false
                        self.proWindowController?.close()
                        self.showStageSettings()
                        self.transientNotice = L10n.text(
                            "StagePaneロゴを非表示にしました。",
                            "The StagePane mark is now hidden."
                        )
                    case .direct:
                        break
                    }
                }
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

    func selectSource(_ sourceID: StageSourceID?) {
        if let sourceID {
            guard let source = capture.source(for: sourceID),
                  source.phase != .stopping,
                  capture.layout[sourceID: sourceID] != nil else { return }
        }
        beginWorkspaceInteraction()
        guard selectedSourceID != sourceID else { return }
        selectedSourceID = sourceID
    }

    func setStageInteractionMode(_ mode: StageInteractionMode) {
        beginWorkspaceInteraction()
        if mode == .crop, cropEditingSourceID == nil {
            guard let sourceID = defaultCropEditingSourceID,
                  beginCropEditing(sourceID) else { return }
        } else if mode != .crop, cropEditingSourceID != nil {
            discardCropEditing(announce: true)
        }
        guard stageInteractionMode != mode else { return }
        annotations.endStroke()
        magnifier.hide()
        stageInteractionMode = mode
        capture.setPointerStyle(effectivePointerStyle)
    }

    func editCrop(of sourceID: StageSourceID) {
        if cropEditingSourceID == sourceID, cropDraft != nil {
            selectSource(sourceID)
            setStageInteractionMode(.crop)
            return
        }
        let discardedAnotherDraft = cropEditingSourceID != nil
        guard beginCropEditing(sourceID) else { return }
        setStageInteractionMode(.crop)
        if discardedAnotherDraft {
            transientNotice = L10n.cropPreviousDraftDiscardedNotice
        }
    }

    func resetCrop(of sourceID: StageSourceID) {
        if cropEditingSourceID == sourceID, cropDraft != nil {
            selectSource(sourceID)
            cropDraft = .fullSource
            setStageInteractionMode(.crop)
            transientNotice = L10n.cropResetDraftNotice
            return
        }
        let discardedAnotherDraft = cropEditingSourceID != nil
        guard beginCropEditing(sourceID, draft: .fullSource) else { return }
        setStageInteractionMode(.crop)
        transientNotice = discardedAnotherDraft
            ? L10n.cropPreviousDraftDiscardedAndResetNotice
            : L10n.cropResetDraftNotice
    }

    func setCropDraft(
        _ crop: NormalizedSourceRect,
        for sourceID: StageSourceID
    ) {
        guard cropEditingSourceID == sourceID else { return }
        beginWorkspaceInteraction()
        cropDraft = crop
    }

    func resetCropDraft() {
        guard cropEditingSourceID != nil else { return }
        beginWorkspaceInteraction()
        cropDraft = .fullSource
        transientNotice = L10n.cropResetDraftNotice
    }

    func applyCropEditing() {
        guard let sourceID = cropEditingSourceID,
              let cropDraft,
              let source = capture.source(for: sourceID),
              !source.isOutputSuppressed,
              source.isPresentationVisible,
              source.phase != .stopping,
              capture.layout[sourceID: sourceID] != nil else {
            discardCropEditing(announce: false)
            setStageInteractionMode(.arrange)
            transientNotice = L10n.cropSourceUnavailableNotice
            return
        }

        let sourceTitle = capture.source(for: sourceID)?.title ?? ""
        selectSource(sourceID)
        capture.setSourceCrop(sourceID, crop: cropDraft)
        capture.commitSourceCrop(sourceID)
        discardCropEditing(announce: false)
        setStageInteractionMode(.arrange)
        transientNotice = L10n.cropAppliedNotice(sourceTitle)
    }

    func cancelCropEditing() {
        let hadDraft = cropEditingSourceID != nil
        if let sourceID = cropEditingSourceID { selectSource(sourceID) }
        discardCropEditing(announce: false)
        setStageInteractionMode(.arrange)
        if hadDraft {
            transientNotice = L10n.cropDiscardedNotice
        }
    }

    func isSourceCropped(_ sourceID: StageSourceID) -> Bool {
        guard let sourceCrop = capture.layout[sourceID: sourceID]?.sourceCrop else {
            return false
        }
        return sourceCrop != .fullSource
    }

    var canApplyCropEditing: Bool {
        guard let cropEditingSourceID,
              cropDraft != nil,
              let source = capture.source(for: cropEditingSourceID) else { return false }
        return !source.isOutputSuppressed &&
            source.isPresentationVisible &&
            source.phase != .stopping &&
            capture.layout[sourceID: cropEditingSourceID] != nil
    }

    private var defaultCropEditingSourceID: StageSourceID? {
        capture.layout.sources.reversed().first { item in
            guard let source = capture.source(for: item.id) else { return false }
            return !source.isOutputSuppressed &&
                source.isPresentationVisible &&
                source.phase != .stopping
        }?.id
    }

    @discardableResult
    private func beginCropEditing(
        _ sourceID: StageSourceID,
        draft: NormalizedSourceRect? = nil
    ) -> Bool {
        guard let source = capture.source(for: sourceID),
              !source.isOutputSuppressed,
              source.isPresentationVisible,
              source.phase != .stopping,
              let sourceLayout = capture.layout[sourceID: sourceID] else { return false }
        selectSource(sourceID)
        cropEditingSourceID = sourceID
        cropDraft = draft ?? sourceLayout.sourceCrop
        return true
    }

    private func discardCropEditing(announce: Bool) {
        guard cropEditingSourceID != nil else { return }
        cropEditingSourceID = nil
        cropDraft = nil
        if announce {
            transientNotice = L10n.cropDiscardedNotice
        }
    }

    func removeSource(
        _ sourceID: StageSourceID,
        completion: ((String?) -> Void)? = nil
    ) {
        beginWorkspaceInteraction()
        if selectedSourceID == sourceID {
            selectedSourceID = nil
        }
        if cropEditingSourceID == sourceID {
            discardCropEditing(announce: false)
            setStageInteractionMode(.arrange)
            transientNotice = L10n.cropSourceUnavailableNotice
        }
        if capture.removalLeavesNoVisibleSources(sourceID) {
            annotations.endStroke()
            annotations.removeAll()
        }
        capture.removeSource(sourceID, completion: completion)
    }

    func presentPermissionCheck() {
        beginWorkspaceInteraction()
        if permissionsWindowController == nil {
            permissionsWindowController = StagePrivateWindowController(
                title: L10n.text("画面共有について — 手元用", "About Screen Sharing — Private"),
                autosaveName: "StagePane.ScreenSharingAccess",
                size: NSSize(width: 640, height: 500),
                minimumSize: NSSize(width: 560, height: 440),
                content: ScreenSharingAccessView(controller: self, capture: capture)
            )
        }
        permissionsWindowController?.present()
    }

    func closePermissionCheck() {
        permissionsWindowController?.close()
    }

    func chooseSourceFromAccessGuide() {
        closePermissionCheck()
        chooseSource()
    }

    private func presentCaptureAccessIssue(_ issue: CaptureAccessIssue) {
        transientNotice = nil
        captureAccessIssueNotice = CaptureAccessIssueNotice(
            issue: issue, sourceIDsAtFailure: Set(capture.sources.map(\.id))
        )
        AccessibilityNotification.Announcement(issue.title + "\n" + issue.detail).post()
    }

    func dismissCaptureAccessIssue(id: UUID) {
        guard captureAccessIssueNotice?.id == id else { return }
        captureAccessIssueNotice = nil
    }

    var canRetryCaptureAccessIssue: Bool {
        guard let notice = captureAccessIssueNotice,
              stageInteractionMode != .crop,
              !capture.isPickerPresented else { return false }
        if let sourceID = notice.issue.sourceID {
            return capture.canReplaceSource(sourceID)
        }
        return canRequestSourceAddition
    }

    func retryCaptureAccessIssue() {
        guard canRetryCaptureAccessIssue, let notice = captureAccessIssueNotice else { return }
        // Keep the explanation during the attempt: canceling the picker must
        // not erase the last failure. A successful frame clears it below.
        if let sourceID = notice.issue.sourceID {
            beginWorkspaceInteraction()
            capture.replaceSource(sourceID)
        } else {
            chooseSource()
        }
    }

    private func clearResolvedCaptureAccessIssue() {
        guard let notice = captureAccessIssueNotice else { return }
        let currentSourceIDs = Set(capture.sources.map(\.id))
        let readySourceIDs = Set(capture.sources.filter {
            $0.phase == .active && $0.isPresentationVisible && !$0.isOutputSuppressed
        }.map(\.id))
        if notice.isResolved(currentSourceIDs: currentSourceIDs, readySourceIDs: readySourceIDs) {
            dismissCaptureAccessIssue(id: notice.id)
        }
    }

    private func checkMacScreenRecordingAccessAtLaunch() {
        checksMacScreenRecordingAccess = true
        refreshMacScreenRecordingAccess()
        guard !defaults.bool(forKey: Keys.macScreenRecordingAccessChecked) else { return }
        // Remember the initial check separately from the live macOS status.
        // A denied or deferred request must never create a launch prompt loop.
        defaults.set(true, forKey: Keys.macScreenRecordingAccessChecked)
        if !hasMacScreenRecordingAccess {
            presentMacScreenRecordingAccess()
        }
    }

    func refreshMacScreenRecordingAccess() {
        // Snapshot launches never run a preflight, including activation events.
        guard checksMacScreenRecordingAccess else { return }
        hasMacScreenRecordingAccess = CGPreflightScreenCaptureAccess()
    }

    func showMacScreenRecordingAccess() {
        beginWorkspaceInteraction()
        checksMacScreenRecordingAccess = true
        refreshMacScreenRecordingAccess()
        presentMacScreenRecordingAccess()
    }

    private func presentMacScreenRecordingAccess() {
        if macScreenRecordingAccessWindowController == nil {
            macScreenRecordingAccessWindowController = StagePrivateWindowController(
                title: L10n.text("Macの画面収録アクセス — 手元用", "Mac Screen Recording Access — Private"),
                autosaveName: "StagePane.MacScreenRecordingAccess",
                size: NSSize(width: 560, height: 340),
                minimumSize: NSSize(width: 520, height: 320),
                content: MacScreenRecordingAccessView(controller: self)
            )
        }
        macScreenRecordingAccessWindowController?.present()
    }

    func requestMacScreenRecordingAccess() {
        guard checksMacScreenRecordingAccess, !hasMacScreenRecordingAccess else { return }
        hasRequestedMacScreenRecordingAccess = true
        // Only the explicit Allow button calls this prompting API. Picker
        // sharing remains available regardless of the app-wide result.
        _ = CGRequestScreenCaptureAccess()
        refreshMacScreenRecordingAccess()
    }

    func closeMacScreenRecordingAccess() {
        macScreenRecordingAccessWindowController?.close()
    }

    func openMacSystemSettings() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") else { return }
        NSWorkspace.shared.open(url)
    }

    func dismissTransientNotice(id: UUID? = nil) {
        var nextState = transientNoticeState
        if let id {
            guard nextState.dismiss(id: id) else { return }
        } else {
            nextState.dismissCurrent()
        }
        transientNoticeDismissalTask?.cancel()
        transientNoticeDismissalTask = nil
        transientNoticeState = nextState
    }

    private func presentTransientNotice(_ message: String) {
        transientNoticeDismissalTask?.cancel()

        var nextState = transientNoticeState
        let notice = nextState.present(message)
        transientNoticeState = nextState
        AccessibilityNotification.Announcement(message).post()

        let displaySeconds = NSWorkspace.shared.isVoiceOverEnabled ? 10 : 5
        transientNoticeDismissalTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(displaySeconds))
            } catch {
                return
            }
            self?.dismissTransientNotice(id: notice.id)
        }
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
            checkMacScreenRecordingAccessAtLaunch()
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
        let originalPrivacyMessageSize = privacyMessageSize
        let originalCurtain = privacyCurtain
        let originalWorkspaceSection = workspaceSection
        let originalInteractionMode = stageInteractionMode
        let originalStageRenderingSize = stageRenderingSize
        let originalInkPreferences = annotations.preferences
        let originalMacScreenRecordingAccess = hasMacScreenRecordingAccess
        let originalMacScreenRecordingRequest = hasRequestedMacScreenRecordingAccess
        let originalCaptureAccessIssueNotice = captureAccessIssueNotice
        defer {
            annotations.selectTool(originalInkPreferences.tool)
            annotations.selectColor(originalInkPreferences.colorPreset)
            annotations.setNormalizedWidth(originalInkPreferences.normalizedWidth)
            annotations.setEraserNormalizedWidth(originalInkPreferences.eraserNormalizedWidth)
            setStageInteractionMode(originalInteractionMode)
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
            privacyMessageSize = originalPrivacyMessageSize
            privacyCurtain = originalCurtain
            workspaceSection = originalWorkspaceSection
            stageRenderingSize = originalStageRenderingSize
            hasMacScreenRecordingAccess = originalMacScreenRecordingAccess
            hasRequestedMacScreenRecordingAccess = originalMacScreenRecordingRequest
            captureAccessIssueNotice = originalCaptureAccessIssueNotice
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
        privacyMessageSize = StageMessage.defaultTextSize
        privacyCurtain = true
        captureAccessIssueNotice = nil

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        setStageInteractionMode(.arrange)
        // A public fixture illustrates a 1080p local Stage; it is not evidence
        // of any meeting app's transmitted resolution or this Mac's display.
        stageRenderingSize = CGSize(width: 1_920, height: 1_080)
        try writePNG(
            of: StageInspectorPanel(controller: self, capture: capture)
                .frame(width: 360, height: 600)
                .background(Color(nsColor: .windowBackgroundColor)),
            pointSize: CGSize(width: 360, height: 600),
            to: directory.appendingPathComponent("stage-settings.png")
        )
        workspaceSection = .canvas
        try writePNG(
            of: StageWorkspaceView(controller: self, capture: capture)
                .frame(width: 1_440, height: 900),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("workspace.png")
        )

        privacyCurtain = false
        pointerStyle = .redDot
        try writePNG(
            of: StageWorkspaceView(
                controller: self,
                capture: capture,
                snapshotFixture: .arrange
            )
                .frame(width: 1_440, height: 900),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("arrange.png")
        )

        annotations.selectTool(.eraser)
        setStageInteractionMode(.annotate)
        try writePNG(
            of: StageWorkspaceView(
                controller: self,
                capture: capture,
                snapshotFixture: .draw
            )
                .frame(width: 1_440, height: 900),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("draw.png")
        )

        setStageInteractionMode(.arrange)
        privacyCurtain = true
        workspaceSection = .sources
        try writePNG(
            of: StageWorkspaceView(
                controller: self,
                capture: capture,
                snapshotFixture: .sources
            )
                .frame(width: 1_440, height: 900),
            pointSize: CGSize(width: 1_440, height: 900),
            to: directory.appendingPathComponent("sources.png")
        )

        try writePNG(
            of: ScreenSharingAccessView(controller: self, capture: capture)
                .frame(width: 640, height: 500),
            pointSize: CGSize(width: 640, height: 500),
            to: directory.appendingPathComponent("permissions.png")
        )

        // Synthetic access states never query or request macOS permissions.
        let accessFixtures = [
            (suffix: "", allowed: false, requested: false),
            (suffix: "-pending", allowed: false, requested: true),
            (suffix: "-allowed", allowed: true, requested: false)
        ]
        for fixture in accessFixtures {
            hasMacScreenRecordingAccess = fixture.allowed
            hasRequestedMacScreenRecordingAccess = fixture.requested
            try writePNG(
                of: MacScreenRecordingAccessView(controller: self)
                    .preferredColorScheme(.light)
                    .frame(width: 560, height: 340),
                pointSize: CGSize(width: 560, height: 340),
                to: directory.appendingPathComponent("screen-recording-access\(fixture.suffix).png")
            )
        }

        workspaceSection = .privacy
        try writePNG(
            of: AppSettingsView(controller: self, capture: capture)
                .frame(width: 720, height: 650),
            pointSize: CGSize(width: 720, height: 650),
            to: directory.appendingPathComponent("privacy.png")
        )
        pointerAppearance = .presentationDefault
        workspaceSection = .appearance
        try writePNG(
            of: StageInspectorPanel(controller: self, capture: capture)
                .frame(width: 360, height: 600)
                .background(Color(nsColor: .windowBackgroundColor)),
            pointSize: CGSize(width: 360, height: 600),
            to: directory.appendingPathComponent("appearance.png")
        )
        try writePNG(
            of: AppSettingsView(controller: self, capture: capture)
                .frame(width: 720, height: 650),
            pointSize: CGSize(width: 720, height: 650),
            to: directory.appendingPathComponent("app-settings.png")
        )
        try writePNG(
            of: ProUpgradePanel(controller: self, purchases: purchases)
                .frame(width: 780, height: 760)
                .background(Color(nsColor: .windowBackgroundColor)),
            pointSize: CGSize(width: 780, height: 760),
            to: directory.appendingPathComponent("pro.png")
        )

        // Exercise private windows and native controls in dark appearance too,
        // without changing the app's or the user's system appearance.
        try writePNG(
            of: AppSettingsView(controller: self, capture: capture)
                .preferredColorScheme(.dark)
                .frame(width: 720, height: 650),
            pointSize: CGSize(width: 720, height: 650),
            to: directory.appendingPathComponent("app-settings-dark.png")
        )
        workspaceSection = .about
        try writePNG(
            of: AppSettingsView(controller: self, capture: capture)
                .preferredColorScheme(.dark)
                .frame(width: 640, height: 540),
            pointSize: CGSize(width: 640, height: 540),
            to: directory.appendingPathComponent("settings-640-about-dark.png")
        )
        try writePNG(
            of: StageInspectorPanel(controller: self, capture: capture)
                .preferredColorScheme(.dark)
                .frame(width: 360, height: 600),
            pointSize: CGSize(width: 360, height: 600),
            to: directory.appendingPathComponent("stage-inspector-dark.png")
        )
        try writePNG(
            of: ScreenSharingAccessView(controller: self, capture: capture)
                .preferredColorScheme(.dark)
                .frame(width: 640, height: 500),
            pointSize: CGSize(width: 640, height: 500),
            to: directory.appendingPathComponent("permissions-dark.png")
        )
        for fixture in accessFixtures {
            hasMacScreenRecordingAccess = fixture.allowed
            hasRequestedMacScreenRecordingAccess = fixture.requested
            try writePNG(
                of: MacScreenRecordingAccessView(controller: self)
                    .preferredColorScheme(.dark)
                    .frame(width: 560, height: 340),
                pointSize: CGSize(width: 560, height: 340),
                to: directory.appendingPathComponent("screen-recording-access\(fixture.suffix)-dark.png")
            )
        }
        try writePNG(
            of: ProUpgradePanel(controller: self, purchases: purchases)
                .preferredColorScheme(.dark)
                .frame(width: 780, height: 760)
                .background(Color(nsColor: .windowBackgroundColor)),
            pointSize: CGSize(width: 780, height: 760),
            to: directory.appendingPathComponent("pro-dark.png")
        )
        privacyCurtain = false
        for colorScheme in [ColorScheme.light, .dark] {
            let appearanceName = colorScheme == .dark ? "dark" : "light"
            try writePNG(
                of: StageWorkspaceView(
                    controller: self,
                    capture: capture,
                    snapshotFixture: .arrange
                )
                    .preferredColorScheme(colorScheme)
                    .frame(width: 900, height: 620),
                pointSize: CGSize(width: 900, height: 620),
                to: directory.appendingPathComponent("workspace-900-\(appearanceName).png")
            )
            try writePNG(
                of: StageWorkspaceView(controller: self, capture: capture)
                    .preferredColorScheme(colorScheme)
                    .frame(width: 900, height: 620),
                pointSize: CGSize(width: 900, height: 620),
                to: directory.appendingPathComponent("workspace-empty-900-\(appearanceName).png")
            )
            captureAccessIssueNotice = CaptureAccessIssueNotice(
                issue: CaptureAccessIssue(
                    title: L10n.text("画面の選択を開始できませんでした", "Couldn’t open source selection"),
                    detail: L10n.text(
                        "「ソースを追加」から、もう一度選択画面を開いてください。選択画面を開けない状態が続く場合は、共有するウインドウが開いていることを確認してください。この説明は、もう一度選択して新しいソースを取得できるか、「閉じる」を選ぶまでここに残ります。（これは画面取得を行わない合成サンプルです。）",
                        "Use Add Source to open the selection again. If source selection still cannot open, check that the window you want to share is open and try again. This explanation remains available until a new source is successfully captured or you choose Dismiss. Canceling the selection does not erase the error. (This is a synthetic sample; no screen capture is running.)"
                    )
                ),
                sourceIDsAtFailure: []
            )
            try writePNG(
                of: StageWorkspaceView(controller: self, capture: capture)
                    .preferredColorScheme(colorScheme)
                    .frame(width: 900, height: 620),
                pointSize: CGSize(width: 900, height: 620),
                to: directory.appendingPathComponent("workspace-access-error-empty-900-\(appearanceName).png")
            )
            let failedSourceID = StageSourceID(rawValue: "snapshot-presentation")
            captureAccessIssueNotice = CaptureAccessIssueNotice(
                issue: CaptureAccessIssue(
                    title: L10n.text("画面の取得を開始できませんでした", "Couldn’t start capture"),
                    detail: L10n.text(
                        "「プレゼンテーション」の画面取得を開始できませんでした。レイヤー一覧の「選び直す」から、対象をもう一度選択してください。レイヤーの配置と切り抜きは保持されています。（これは画面取得を行わない合成サンプルです。）",
                        "Capture couldn’t start for “Presentation”. Use Select Again in the layer list to choose the source again. The layer placement and crop were kept. (This is a synthetic sample; no screen capture is running.)"
                    ),
                    sourceID: failedSourceID
                ),
                sourceIDsAtFailure: [failedSourceID]
            )
            try writePNG(
                of: StageWorkspaceView(controller: self, capture: capture, snapshotFixture: .arrange)
                    .preferredColorScheme(colorScheme)
                    .frame(width: 900, height: 620),
                pointSize: CGSize(width: 900, height: 620),
                to: directory.appendingPathComponent("workspace-access-error-source-900-\(appearanceName).png")
            )
            captureAccessIssueNotice = nil
            try writePNG(
                of: ProPlanComparison()
                    .padding(24)
                    .preferredColorScheme(colorScheme)
                    .frame(width: 640, height: 360)
                    .background(Color(nsColor: .windowBackgroundColor)),
                pointSize: CGSize(width: 640, height: 360),
                to: directory.appendingPathComponent("pro-comparison-\(appearanceName).png")
            )
        }

        for section in [WorkspaceSection.appearance, .about] {
            workspaceSection = section
            try writePNG(
                of: AppSettingsView(controller: self, capture: capture)
                    .frame(width: 640, height: 540),
                pointSize: CGSize(width: 640, height: 540),
                to: directory.appendingPathComponent("settings-640-\(section.rawValue).png")
            )
        }
        setStageInteractionMode(.annotate)
        try writePNG(
            of: StageWorkspaceView(controller: self, capture: capture, snapshotFixture: .draw)
                .frame(width: 900, height: 620),
            pointSize: CGSize(width: 900, height: 620),
            to: directory.appendingPathComponent("draw-900.png")
        )
        annotations.selectTool(.eraser)
        for colorScheme in [ColorScheme.light, .dark] {
            let appearanceName = colorScheme == .dark ? "dark" : "light"
            try writePNG(
                of: StageWorkspaceView(controller: self, capture: capture, snapshotFixture: .draw)
                    .preferredColorScheme(colorScheme)
                    .frame(width: 900, height: 620),
                pointSize: CGSize(width: 900, height: 620),
                to: directory.appendingPathComponent("eraser-900-\(appearanceName).png")
            )
        }
        annotations.selectTool(.pen)
        setStageInteractionMode(.arrange)

        // The same fictional slides and booking form illustrate what the
        // audience sees and how that exact composition looks in Workspace.
        // No source stream, source metadata, or permission state is created.
        privacyCurtain = false
        try writePNG(
            of: SnapshotProductComposition(
                showsEditingChrome: false,
                theme: theme,
                showsWatermark: showsWatermark
            )
                .preferredColorScheme(.light)
                .frame(width: 960, height: 540),
            pointSize: CGSize(width: 960, height: 540),
            to: directory.appendingPathComponent("product-stage.png")
        )
        for colorScheme in [ColorScheme.light, .dark] {
            let appearanceName = colorScheme == .dark ? "dark" : "light"
            try writePNG(
                of: StageWorkspaceView(controller: self, capture: capture, snapshotFixture: .product)
                    .preferredColorScheme(colorScheme)
                    .frame(width: 900, height: 620),
                pointSize: CGSize(width: 900, height: 620),
                to: directory.appendingPathComponent("product-workspace-\(appearanceName).png")
            )
        }

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
        beginWorkspaceInteraction()
        if proWindowIsVisible { proWindowController?.close() }
        presentWorkspace()
    }

    @objc func showSettings() {
        beginWorkspaceInteraction()
        if workspaceSection == .privacy {
            workspaceSection = .about
        } else if workspaceSection != .about {
            workspaceSection = .appearance
        }
        presentSettingsWindow()
    }

    @objc func showAbout() {
        selectWorkspaceSection(.about)
    }

    @objc func showStageSettings() {
        beginWorkspaceInteraction()
        if proWindowIsVisible { proWindowController?.close() }
        presentWorkspace()
        isStageSettingsPresented = true
    }

    @objc func showProUpgrade() {
        presentProUpgrade(trigger: .direct)
    }

    func selectWorkspaceSection(_ section: WorkspaceSection) {
        switch section {
        case .canvas, .sources:
            showStageWorkspace()
        case .stage:
            showStageSettings()
        case .pro:
            showProUpgrade()
        case .permissions:
            presentPermissionCheck()
        case .appearance, .privacy, .about:
            beginWorkspaceInteraction()
            workspaceSection = section == .privacy ? .about : section
            presentSettingsWindow()
        }
    }

    private func presentSettingsWindow() {
        if settingsWindowController == nil {
            settingsWindowController = StagePrivateWindowController(
                title: L10n.text("StagePane設定 — 手元用", "StagePane Settings — Private"),
                autosaveName: "StagePane.Settings",
                size: NSSize(width: 720, height: 650),
                minimumSize: NSSize(width: 640, height: 540),
                content: AppSettingsView(controller: self, capture: capture)
            )
        }
        settingsWindowController?.present()
    }

    func presentProUpgrade(trigger: ProUpgradeTrigger) {
        proUpgradeTrigger = trigger
        pendingProContinuation = false
        proContinuationID = trigger == .direct ? nil : UUID()
        isStageSettingsPresented = false
        if proWindowController == nil {
            proWindowController = StagePrivateWindowController(
                title: L10n.text("StagePane Pro — 手元用", "StagePane Pro — Private"),
                autosaveName: "StagePane.Pro",
                size: NSSize(width: 780, height: 760),
                minimumSize: NSSize(width: 620, height: 540),
                content: ProUpgradePanel(controller: self, purchases: purchases),
                onClose: { [weak self] in self?.proWindowDidClose() },
                onMiniaturize: { [weak self] in self?.beginWorkspaceInteraction() }
            )
        }
        proWindowIsVisible = true
        proWindowController?.present()
    }

    /// Returning to editing cancels a deferred purchase action, never the
    /// purchase itself. Entitlements still update after the window closes.
    func beginWorkspaceInteraction() {
        pendingProContinuation = false
        proContinuationID = nil
    }

    private func proWindowDidClose() {
        proWindowIsVisible = false
        beginWorkspaceInteraction()
    }

    func requestWatermarkVisibility(_ isVisible: Bool) {
        if isVisible || hasProAccess {
            beginWorkspaceInteraction()
            prefersWatermark = isVisible
        } else {
            presentProUpgrade(trigger: .watermark)
        }
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

    @objc func enlargeStageForSharing() {
        let workspaceWasKey = workspaceWindowController?.window?.isKeyWindow == true
        presentStage(makeKey: false)
        stageWindowController?.enlargeForSharing()
        if workspaceWasKey {
            workspaceWindowController?.window?.makeKeyAndOrderFront(nil)
        }
    }

    @objc func toggleStageFullScreen() {
        stageWindowController?.toggleFullScreen()
    }

    @objc func toggleStageAlwaysOnTop() { isAlwaysOnTop.toggle() }
    @objc func toggleStageAllSpaces() { followsAllSpaces.toggle() }
    @objc func toggleStageProtection() { presentationLock.toggle() }

    @objc func editSelectedLayerCrop() {
        guard let selectedSourceID, !capture.isPickerPresented else { return }
        beginWorkspaceInteraction()
        editCrop(of: selectedSourceID)
        presentWorkspace()
    }

    @objc func moveSelectedLayerForward() {
        guard canReorderSelectedLayer, let selectedSourceID else { return }
        beginWorkspaceInteraction()
        capture.bringSourceForward(selectedSourceID)
    }

    @objc func moveSelectedLayerBackward() {
        guard canReorderSelectedLayer, let selectedSourceID else { return }
        beginWorkspaceInteraction()
        capture.sendSourceBackward(selectedSourceID)
    }

    @objc func bringSelectedLayerToFront() {
        guard canReorderSelectedLayer, let selectedSourceID else { return }
        beginWorkspaceInteraction()
        capture.bringSourceToFront(selectedSourceID)
    }

    @objc func sendSelectedLayerToBack() {
        guard canReorderSelectedLayer, let selectedSourceID else { return }
        beginWorkspaceInteraction()
        capture.sendSourceToBack(selectedSourceID)
    }

    private var canReorderSelectedLayer: Bool {
        guard stageInteractionMode != .crop,
              !capture.isPickerPresented,
              let selectedSourceID,
              let source = capture.source(for: selectedSourceID),
              source.phase != .stopping else { return false }
        return capture.layout[sourceID: selectedSourceID] != nil
    }

    func updateStageFullScreenState(isFullScreen: Bool, isTransitioning: Bool) {
        if stageIsFullScreen != isFullScreen { stageIsFullScreen = isFullScreen }
        if stageFullScreenTransitionInProgress != isTransitioning {
            stageFullScreenTransitionInProgress = isTransitioning
        }
    }

    func updateStageRenderingSize(_ size: CGSize) {
        guard size.width.isFinite, size.height.isFinite,
              size.width > 0, size.height > 0 else { return }
        let pixels = CGSize(width: size.width.rounded(), height: size.height.rounded())
        guard pixels != stageRenderingSize else { return }
        stageRenderingSize = pixels
    }

    private func presentStage(makeKey: Bool) {
        // Preparing a source or changing a preset must keep the private
        // Workspace's Space active while Stage occupies its own Space.
        if !makeKey, stageIsFullScreen || stageFullScreenTransitionInProgress {
            return
        }
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
        stageIsMiniaturized = false
    }

    @objc func chooseSource() {
        beginWorkspaceInteraction()
        guard canRequestSourceAddition else { return }
        if StagePaneAccess.requiresProForNextSource(
            currentCount: capture.occupiedSourceSlots,
            hasProAccess: hasProAccess
        ) {
            presentProUpgrade(trigger: .sourceLimit)
            return
        }
        if proWindowIsVisible { proWindowController?.close() }
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
        beginWorkspaceInteraction()
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
        beginWorkspaceInteraction()
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
        case #selector(toggleStageAlwaysOnTop):
            menuItem.state = isAlwaysOnTop ? .on : .off
            return !stageIsFullScreen && !stageFullScreenTransitionInProgress
        case #selector(toggleStageAllSpaces):
            menuItem.state = followsAllSpaces ? .on : .off
            return !stageIsFullScreen && !stageFullScreenTransitionInProgress
        case #selector(toggleStageProtection):
            menuItem.state = presentationLock ? .on : .off
            return true
        case #selector(enlargeStageForSharing):
            return !stageIsFullScreen && !stageFullScreenTransitionInProgress
        case #selector(editSelectedLayerCrop):
            guard !capture.isPickerPresented, let selectedSourceID,
                  let source = capture.source(for: selectedSourceID) else { return false }
            return source.isPresentationVisible && !source.isOutputSuppressed &&
                source.phase != .stopping
        case #selector(moveSelectedLayerForward), #selector(bringSelectedLayerToFront):
            return canReorderSelectedLayer && capture.layout.sources.last?.id != selectedSourceID
        case #selector(moveSelectedLayerBackward), #selector(sendSelectedLayerToBack):
            return canReorderSelectedLayer && capture.layout.sources.first?.id != selectedSourceID

        case #selector(copyStageScreenshot), #selector(saveStageScreenshot):
            return !isStageScreenshotInProgress && !stageFullScreenTransitionInProgress
        case #selector(toggleStageFullScreen):
            menuItem.title = stageIsFullScreen
                ? L10n.text("Stageのフルスクリーンを終了", "Exit Stage Full Screen")
                : L10n.text("Stageをフルスクリーンにする", "Enter Stage Full Screen")
            return !stageFullScreenTransitionInProgress
        case #selector(chooseSource):
            return canRequestSourceAddition
        case #selector(stopPreview):
            menuItem.title = capture.hasResettableFailure
                ? L10n.text("画面取得のエラーをリセット", "Reset Capture Error")
                : L10n.stopAllAndRemoveLayersTitle
            return capture.hasLayers || capture.isCaptureActive || capture.hasResettableFailure
        case #selector(toggleCurtain):
            menuItem.state = privacyCurtain ? .on : .off
            menuItem.title = privacyCurtain
                ? L10n.text("カーテンを開く", "Open Curtain")
                : L10n.text("カーテンを閉じる", "Close Curtain")
            return true
        default:
            return true
        }
    }

    private func makeStageScreenshot() -> StageSnapshot? {
        guard !isStageScreenshotInProgress else { return nil }
        guard !stageFullScreenTransitionInProgress else {
            transientNotice = L10n.text(
                "Stageのフルスクリーン切り替えが完了するまでお待ちください。",
                "Wait for Stage to finish switching full screen."
            )
            return nil
        }
        guard let canvasView = stageWindowController?.stageCanvasView else {
            transientNotice = L10n.text(
                "共有Stageを準備できませんでした。",
                "The Share Stage is not available."
            )
            return nil
        }

        isStageScreenshotInProgress = true
        do {
            return try StageWindowSnapshotter.capture(
                contentView: canvasView,
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
        beginWorkspaceInteraction()
        guard capture.hasLayers else {
            if capture.isCaptureActive {
                performStopAllAndRemoveLayers()
                return
            }
            let neededReset = capture.hasResettableFailure
            capture.stop()
            if neededReset, let notice = captureAccessIssueNotice, notice.issue.sourceID == nil {
                dismissCaptureAccessIssue(id: notice.id)
            }
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

        presentStopAllAndRemoveLayersConfirmation()
    }

    private func presentStopAllAndRemoveLayersConfirmation() {
        guard stopAllConfirmationAlert == nil else { return }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.stopAllAndRemoveLayersConfirmationTitle
        alert.informativeText = L10n.stopAllAndRemoveLayersConfirmationMessage

        let cancelButton = alert.addButton(withTitle: L10n.cancelSourceRemovalTitle)
        cancelButton.keyEquivalent = "\r"
        let destructiveButton = alert.addButton(
            withTitle: L10n.confirmStopAllAndRemoveLayersTitle
        )
        destructiveButton.hasDestructiveAction = true
        stopAllConfirmationAlert = alert

        if workspaceIsVisible,
           let workspaceWindow = workspaceWindowController?.window,
           workspaceWindow.isVisible,
           !workspaceWindow.isMiniaturized {
            alert.beginSheetModal(for: workspaceWindow) { [weak self] response in
                guard let self else { return }
                self.stopAllConfirmationAlert = nil
                guard response == .alertSecondButtonReturn else { return }
                self.performStopAllAndRemoveLayers()
            }
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        stopAllConfirmationAlert = nil
        guard response == .alertSecondButtonReturn else { return }
        performStopAllAndRemoveLayers()
    }

    private func performStopAllAndRemoveLayers() {
        selectedSourceID = nil
        privacyCurtain = true
        transientNotice = L10n.text(
            "すべてのソースを停止し、レイヤーを削除しています…",
            "Stopping every source and removing its layers…"
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
        stageIsMiniaturized = false
        guard !capture.sources.isEmpty || capture.isPickerPresented else { return }
        privacyCurtain = true
        if capture.isPickerPresented {
            transientNotice = L10n.text(
                "共有Stageを閉じました。ソース選択は手元のWorkspaceで続けられ、再表示するまで観客側の出力は隠れます。",
                "The Share Stage closed. Source selection can continue in the private Workspace, and audience output stays hidden until you reopen it."
            )
        } else {
            transientNotice = L10n.text(
                "共有Stageを閉じました。レイヤーと画面取得はWorkspaceに保持されています。完全に終了するには「すべて停止してレイヤーを削除」を使ってください。",
                "The Share Stage closed. Layers and capture remain available in the Workspace; use Stop All and Remove Layers to end them completely."
            )
        }
    }

    func workspaceDidClose() {
        workspaceDidBecomeHidden()
    }

    func workspaceDidBecomeHidden() {
        workspaceIsVisible = false
        annotations.endStroke()
        magnifier.hide()
    }

    func workspaceDidBecomeVisible() {
        workspaceIsVisible = true
    }

    func stageDidBecomeVisible() {
        stageIsVisible = true
        stageIsMiniaturized = false
    }

    func stageDidBecomeHidden() {
        stageIsVisible = false
        stageIsMiniaturized = stageWindowController?.window?.isMiniaturized == true
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
                "https://stagepane.hinoshiba.com/#privacy",
                "https://stagepane.hinoshiba.com/?lang=en#privacy"
            )),
            fallbackResource: "PRIVACY",
            fallbackExtension: "md"
        )
    }

    @objc func openSupport() {
        openExternalPage(
            URL(string: L10n.text(
                "https://stagepane.hinoshiba.com/#support",
                "https://stagepane.hinoshiba.com/?lang=en#support"
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
        clearResolvedCaptureAccessIssue()
        discardCropEditingIfSourceUnavailable()
        if !isActive { magnifier.hide() }
        let previousPhase = previousCapturePhase
        let wasActive = previousCaptureWasActive
        guard phase != previousPhase || isActive != wasActive else { return }

        previousCapturePhase = phase
        previousCaptureWasActive = isActive
        if isActive, phase == .previewing {
            activeSessionReachedPreview = true
        }

        if wasActive && !isActive {
            let needsAttention = capturePhaseNeedsAttention(phase)
            let hasDisconnectedLayers = capture.sources.contains {
                $0.needsReselection
            }
            let sessionDuration = activeSessionStartedAt.map {
                Date().timeIntervalSince($0)
            } ?? 0
            let reachedPreview = activeSessionReachedPreview
            activeSessionStartedAt = nil
            activeSessionReachedPreview = false
            if captureAccessIssueNotice == nil || (!needsAttention && !hasDisconnectedLayers) {
                if hasDisconnectedLayers {
                    transientNotice = L10n.text(
                        "画面取得は停止しました。レイヤーの配置と切り抜きは保持されています。対象を選び直してください。",
                        "Capture stopped. The layer placement and crop were kept. Choose its source again."
                    )
                } else if needsAttention {
                    transientNotice = L10n.text(
                        "画面取得は完全に停止しました。後処理の確認が必要です。",
                        "Capture stopped completely, but cleanup needs attention."
                    )
                } else {
                    transientNotice = L10n.text(
                        "すべてのソースを完全に停止しました。",
                        "All sources stopped completely."
                    )
                }
            }
            if ReviewPromptPolicy.qualifiesAsSuccessfulSession(
                duration: sessionDuration,
                needsAttention: needsAttention,
                reachedPreview: reachedPreview
            ) {
                recordSuccessfulSessionForReview()
            }
            return
        }

        if capturePhaseNeedsAttention(phase) {
            // The persistent source-specific recovery stays authoritative;
            // a generic Reset Capture toast would suggest a competing action.
            guard captureAccessIssueNotice == nil else { return }
            if capture.hasDisconnectedLayers {
                let detail = capture.statusDetail.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                transientNotice = detail.isEmpty
                    ? L10n.text(
                        "ソースとの共有が終了しました。レイヤーの配置と切り抜きは保持されています。ソース一覧の「選び直す」を使ってください。",
                        "Source sharing ended. The layer placement and crop were kept. Use Select Again in the source list."
                    )
                    : detail
            } else {
                transientNotice = isActive
                ? L10n.text(
                    "画面取得で問題が発生しましたが、画面取得は継続中です。カーテンまたは停止操作を確認してください。",
                    "Capture needs attention and remains active. Check the Curtain or Stop Capture control."
                )
                : L10n.text(
                    "画面取得で問題が発生しました。「画面取得をリセット」してからソースを選び直してください。",
                    "Capture needs attention. Choose Reset Capture, then add the source again."
                )
            }
            return
        }

        if isActive, !wasActive {
            activeSessionStartedAt = Date()
            activeSessionReachedPreview = phase == .previewing
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

    private func discardCropEditingIfSourceUnavailable() {
        guard let sourceID = cropEditingSourceID else { return }
        if let source = capture.source(for: sourceID),
           !source.isOutputSuppressed,
           source.isPresentationVisible,
           source.phase != .stopping,
           capture.layout[sourceID: sourceID] != nil {
            return
        }
        discardCropEditing(announce: false)
        setStageInteractionMode(.arrange)
        transientNotice = L10n.cropSourceUnavailableNotice
    }

    private func capturePhaseNeedsAttention(_ phase: CapturePhase) -> Bool {
        if case .failed = phase { return true }
        return false
    }

    private func recordSuccessfulSessionForReview() {
#if STAGEPANE_APP_STORE
        guard !reviewRequestIsScheduled else { return }
        let now = Date()
        let count = defaults.integer(forKey: Keys.successfulSessionCount) + 1
        defaults.set(count, forKey: Keys.successfulSessionCount)

        let firstDate: Date
        if let storedDate = defaults.object(forKey: Keys.firstSuccessfulSessionDate) as? Date {
            firstDate = storedDate
        } else {
            firstDate = now
            defaults.set(firstDate, forKey: Keys.firstSuccessfulSessionDate)
        }

        let currentVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? ""
        guard ReviewPromptPolicy.shouldRequestReview(
            successfulSessionCount: count,
            firstSuccessfulSessionDate: firstDate,
            lastRequestedVersion: defaults.string(forKey: Keys.lastReviewRequestVersion),
            currentVersion: currentVersion,
            now: now
        ) else { return }

        reviewRequestIsScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            defer { reviewRequestIsScheduled = false }
            guard NSApp.isActive,
                  !capture.isCaptureActive,
                  !capture.isPickerPresented,
                  !purchases.isBusy,
                  purchases.operationState != .pending,
                  !proWindowIsVisible,
                  let workspaceWindow = workspaceWindowController?.window,
                  workspaceWindow.isVisible,
                  let viewController = workspaceWindow.contentViewController else {
                return
            }
            defaults.set(currentVersion, forKey: Keys.lastReviewRequestVersion)
            AppStore.requestReview(in: viewController)
        }
#endif
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
        static let privacyMessageSize = "stage.privacyMessageSize"
        static let macScreenRecordingAccessChecked = "onboarding.macScreenRecordingAccessChecked"
        static let successfulSessionCount = "review.successfulSessionCount"
        static let firstSuccessfulSessionDate = "review.firstSuccessfulSessionDate"
        static let lastReviewRequestVersion = "review.lastRequestedVersion"
    }

    private enum SnapshotError: Error {
        case renderFailed
        case encodingFailed
    }
}
