import AppKit
import StagePaneCore
import SwiftUI

@MainActor
private final class StageShareWindow: NSWindow {
    var exitFullScreen: (() -> Void)?
    // Borderless NSWindow instances are not key or main by default. The Stage
    // deliberately stays chrome-free, but it must still become the front
    // window when the user clicks it or chooses Show Share Stage so standard
    // commands such as Close Window target the surface they can see.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        if styleMask.contains(.fullScreen) {
            exitFullScreen?()
        } else {
            super.cancelOperation(sender)
        }
    }

    override func sendEvent(_ event: NSEvent) {
        // Stage contains audience artwork only. Start a native window drag
        // explicitly so movement does not depend on SwiftUI's background
        // mouse-event forwarding. Leave the resize perimeter and sheets to
        // AppKit, and never try to move a full-screen window.
        if event.type == .leftMouseDown,
           event.window === self,
           isMovable,
           attachedSheet == nil,
           !styleMask.contains(.fullScreen),
           let contentView,
           contentView.bounds.insetBy(dx: 8, dy: 8).contains(
               contentView.convert(event.locationInWindow, from: nil)
           ) {
            if !NSApp.isActive { NSApp.activate() }
            makeKeyAndOrderFront(nil)
            performDrag(with: event)
            // Window Server owns the drag; a mouse-up need not be delivered.
            return
        }
        super.sendEvent(event)
    }
}

@MainActor
final class StageWorkspaceWindowController: NSWindowController, NSWindowDelegate {
    private weak var controller: AppController?

    init(controller: AppController, capture: CaptureCoordinator) {
        self.controller = controller
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.workspaceWindowTitle
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isReleasedWhenClosed = false
        // This is the app's sole private main window. Below the wide-canvas
        // threshold its global navigation becomes an icon rail; the layer list
        // stays beside the canvas so overlap controls are always available.
        window.contentMinSize = NSSize(width: 900, height: 620)
        window.setFrameAutosaveName("StagePane.Workspace")
        window.tabbingMode = .disallowed
        // AppKit no longer provides a supported window-capture exclusion
        // boundary. The visible KEEP PRIVATE guidance directs users to share
        // the exact Stage window; full-display sharing can include Workspace.
        window.contentViewController = NSHostingController(
            rootView: StageWorkspaceView(controller: controller, capture: capture)
        )

        super.init(window: window)
        window.delegate = self
        if window.frame.origin == .zero { window.center() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        controller?.workspaceDidClose()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        controller?.workspaceDidBecomeVisible()
    }

    func windowDidMiniaturize(_ notification: Notification) {
        controller?.workspaceDidBecomeHidden()
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        controller?.workspaceDidBecomeVisible()
    }
}

@MainActor
final class StageWindowController: NSWindowController, NSWindowDelegate {
    private weak var controller: AppController?
    private let canvasHost: StageCanvasHostViewController
    private enum FullScreenPhase {
        case windowed, entering, fullScreen, exiting

        var isTransitioning: Bool { self == .entering || self == .exiting }
    }
    private var fullScreenPhase: FullScreenPhase = .windowed
    private var pendingPresetResize = false
    private var frameAutosaveIsSuspended = false
    private var failureRecovery: Task<Void, Never>?

    var stageCanvasView: NSView {
        canvasHost.view.layoutSubtreeIfNeeded()
        return canvasHost.canvasView
    }

    private var allowsWindowGeometryChanges: Bool {
        fullScreenPhase == .windowed && window?.styleMask.contains(.fullScreen) == false
    }

    init(controller: AppController, capture: CaptureCoordinator) {
        self.controller = controller
        canvasHost = StageCanvasHostViewController(controller: controller, capture: capture)
        let suggested = StageWindowSizing.suggestedContentSize(for: controller.preset)
        let window = StageShareWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: suggested.width,
                height: suggested.height
            ),
            // The Stage is the exact window users share. A titled window is
            // still captured with a titlebar band even when its title and
            // traffic-light controls are hidden, so keep the audience surface
            // genuinely chrome-free. The Window menu remains the keyboard
            // route for Close; StageShareWindow handles dragging its content.
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.stageWindowTitle
        window.isReleasedWhenClosed = false
        window.isOpaque = true
        window.alphaValue = 1
        window.backgroundColor = .black
        window.contentMinSize = StageWindowSizing.minimumContentSize(for: controller.preset)
        window.tabbingMode = .disallowed
        window.sharingType = .readOnly
        let initialFrame = window.frame
        window.contentViewController = canvasHost
        window.isMovableByWindowBackground = false

        super.init(window: window)
        window.delegate = self
        window.exitFullScreen = { [weak self] in self?.toggleFullScreen() }
        canvasHost.onCanvasLayout = { [weak self] in self?.updateRenderingSize() }
        applyPreset(controller.preset, resize: false)
        // Assigning contentViewController resizes the window to the hosting
        // view's current size. Restore the intended frame only afterward, and
        // register autosaving last so that temporary minimum size is not saved.
        if !window.setFrameUsingName("StagePane.ShareStage") {
            window.setFrame(initialFrame, display: false)
            window.center()
        }
        window.setFrameAutosaveName("StagePane.ShareStage")
        applyWindowBehavior()
        updateRenderingSize()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyPreset(_ preset: StagePreset, resize: Bool) {
        guard let window else { return }
        canvasHost.setPreset(preset)
        window.contentMinSize = StageWindowSizing.minimumContentSize(for: preset)
        window.contentAspectRatio = NSSize(width: preset.pixelWidth, height: preset.pixelHeight)
        guard resize else { return }
        guard allowsWindowGeometryChanges else {
            // Update the fitted canvas now; restore the newly selected shape
            // only after AppKit finishes returning to an ordinary window.
            pendingPresetResize = true
            updateRenderingSize()
            return
        }

        let size = StageWindowSizing.suggestedContentSize(for: preset)
        var frame = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        frame.origin.x = window.frame.midX - frame.width / 2
        frame.origin.y = window.frame.midY - frame.height / 2
        // Reselecting a preset restores its suggested size after a user resize.
        // Skip only an identical frame, avoiding a no-op animation on the
        // audience window without taking away that reset gesture.
        guard frame != window.frame else { return }
        window.setFrame(frame, display: true, animate: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        updateRenderingSize()
    }

    func enlargeForSharing() {
        guard allowsWindowGeometryChanges else { return }
        guard let controller, let window, let contentView = window.contentView,
              let screen = window.screen ?? NSScreen.main else { return }
        let preset = controller.preset
        let target = contentView.convertFromBacking(NSRect(
            x: 0, y: 0, width: preset.pixelWidth, height: preset.pixelHeight
        )).size
        let available = window.contentRect(forFrameRect: screen.visibleFrame).size
        guard let size = StageWindowSizing.enlargedContentSize(
            current: contentView.bounds.size,
            target: target,
            available: available,
            aspectRatio: preset.aspectRatio
        ) else {
            updateRenderingSize()
            controller.transientNotice = L10n.text(
                "Stageは基準サイズに達しているか、この画面ではこれ以上拡大できません。",
                "Stage has reached the reference size, or cannot grow further on this display."
            )
            return
        }

        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        frame.origin = NSPoint(
            x: min(max(window.frame.midX - frame.width / 2, screen.visibleFrame.minX),
                   screen.visibleFrame.maxX - frame.width),
            y: min(max(window.frame.midY - frame.height / 2, screen.visibleFrame.minY),
                   screen.visibleFrame.maxY - frame.height)
        )
        // Keep this exact share window and its capture identity. An immediate
        // resize also avoids sending intermediate animation sizes to a meeting.
        window.setFrame(frame, display: true)
        updateRenderingSize()
        controller.transientNotice = L10n.text(
            "Stageを共有向けに拡大しました。送信解像度は会議アプリの設定にも依存します。",
            "Enlarged Stage for sharing. Sent resolution also depends on your meeting app."
        )
    }

    private func updateRenderingSize() {
        let contentView = stageCanvasView
        controller?.updateStageRenderingSize(contentView.convertToBacking(contentView.bounds).size)
    }

    func toggleFullScreen() {
        guard let window, !fullScreenPhase.isTransitioning else { return }
        failureRecovery?.cancel()
        fullScreenPhase = window.styleMask.contains(.fullScreen) ? .exiting : .entering
        suspendFrameAutosave()
        applyWindowBehavior()
        publishFullScreenState()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // AppKit owns the Space transition. Making an off-Space window key
        // does not always switch Spaces, so waiting for isOnActiveSpace would
        // prevent exiting from Workspace. Reconcile native completion below.
        window.toggleFullScreen(nil)
    }

    private func suspendFrameAutosave() {
        guard !frameAutosaveIsSuspended, let window else { return }
        // Full-screen and intermediate frames must not become the next
        // launch's ordinary Stage dimensions.
        window.setFrameAutosaveName("")
        frameAutosaveIsSuspended = true
    }

    private func publishFullScreenState() {
        controller?.updateStageFullScreenState(
            isFullScreen: window?.styleMask.contains(.fullScreen) == true,
            isTransitioning: fullScreenPhase.isTransitioning
        )
    }

    private func settleFullScreenState() {
        guard let window else { return }
        failureRecovery?.cancel()
        failureRecovery = nil
        fullScreenPhase = window.styleMask.contains(.fullScreen) ? .fullScreen : .windowed
        if fullScreenPhase == .windowed {
            if frameAutosaveIsSuspended {
                window.setFrameAutosaveName("StagePane.ShareStage")
                frameAutosaveIsSuspended = false
            }
            if pendingPresetResize, let controller {
                pendingPresetResize = false
                applyPreset(controller.preset, resize: true)
            }
        }
        applyWindowBehavior()
        publishFullScreenState()
        updateRenderingSize()
    }

    private func recoverFromFullScreenFailure() {
        // AppKit can report a failed off-Space exit immediately before its
        // did-exit notification. Let that success win; never force a frame
        // restoration from a failure callback while the Space is settling.
        failureRecovery?.cancel()
        let expectedFullScreen = fullScreenPhase == .entering
        failureRecovery = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled, let self else { return }
            self.settleFullScreenState()
            if self.window?.styleMask.contains(.fullScreen) != expectedFullScreen {
                self.reportFullScreenFailure()
            }
        }
    }

    private func reportFullScreenFailure() {
        controller?.transientNotice = L10n.text(
            "Stageのフルスクリーン切替を完了できませんでした。Stageを表示して、もう一度お試しください。",
            "Stage could not complete the full-screen switch. Show the Stage and try again."
        )
    }

    func windowWillEnterFullScreen(_ notification: Notification) {
        fullScreenPhase = .entering
        suspendFrameAutosave()
        applyWindowBehavior()
        publishFullScreenState()
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        settleFullScreenState()
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        fullScreenPhase = .exiting
        applyWindowBehavior()
        publishFullScreenState()
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        settleFullScreenState()
    }

    func windowDidFailToEnterFullScreen(_ window: NSWindow) {
        recoverFromFullScreenFailure()
    }

    func windowDidFailToExitFullScreen(_ window: NSWindow) {
        recoverFromFullScreenFailure()
    }

    func windowDidResize(_ notification: Notification) {
        updateRenderingSize()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        updateRenderingSize()
    }

    func windowDidChangeBackingProperties(_ notification: Notification) {
        updateRenderingSize()
    }

    func applyWindowBehavior() {
        guard let controller, let window else { return }
        let usesIndependentSpace = fullScreenPhase != .windowed || window.styleMask.contains(.fullScreen)
        window.isMovable = !usesIndependentSpace
        window.level = !usesIndependentSpace && controller.isAlwaysOnTop ? .floating : .normal
        window.collectionBehavior = !usesIndependentSpace && controller.followsAllSpaces
            ? [.canJoinAllSpaces, .fullScreenAuxiliary]
            : [.managed, .fullScreenPrimary]
        window.standardWindowButton(.closeButton)?.isEnabled = !controller.presentationLock
        window.standardWindowButton(.miniaturizeButton)?.isEnabled = !controller.presentationLock
    }

    func requestClose() {
        guard let window, windowShouldClose(window) else { return }
        window.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !fullScreenPhase.isTransitioning else { return false }
        guard controller?.presentationLock == true else { return true }
        NSSound.beep()
        controller?.transientNotice = L10n.text(
            "プレゼンテーションロック中です。設定から解除できます。",
            "Presentation Lock is on. Turn it off in Appearance."
        )
        return false
    }

    func windowWillClose(_ notification: Notification) {
        failureRecovery?.cancel()
        controller?.stageDidClose()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        controller?.stageDidBecomeVisible()
    }

    func windowDidMiniaturize(_ notification: Notification) {
        controller?.stageDidBecomeHidden()
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        controller?.stageDidBecomeVisible()
    }
}
