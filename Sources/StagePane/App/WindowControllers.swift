import AppKit
import StagePaneCore
import SwiftUI

@MainActor
private final class StageShareWindow: NSWindow {
    // Borderless NSWindow instances are not key or main by default. The Stage
    // deliberately stays chrome-free, but it must still become the front
    // window when the user clicks it or chooses Show Share Stage so standard
    // commands such as Close Window target the surface they can see.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
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
        // threshold its global navigation becomes an icon rail and the canvas
        // source list becomes an overlay, preserving a useful editing area.
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

    init(controller: AppController, capture: CaptureCoordinator) {
        self.controller = controller
        let suggested = controller.preset.suggestedPointSize
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
            // route for Close, and the background stays draggable.
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.stageWindowTitle
        window.isReleasedWhenClosed = false
        window.isOpaque = true
        window.alphaValue = 1
        window.backgroundColor = .black
        window.minSize = NSSize(width: 480, height: 270)
        window.tabbingMode = .disallowed
        window.sharingType = .readOnly
        window.setFrameAutosaveName("StagePane.ShareStage")
        window.contentViewController = NSHostingController(
            rootView: StageView(controller: controller, capture: capture)
        )
        window.isMovableByWindowBackground = true

        super.init(window: window)
        window.delegate = self
        applyPreset(controller.preset, resize: false)
        applyWindowBehavior()
        if window.frame.origin == .zero { window.center() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyPreset(_ preset: StagePreset, resize: Bool) {
        guard let window else { return }
        window.contentAspectRatio = NSSize(width: preset.pixelWidth, height: preset.pixelHeight)
        guard resize else { return }

        let size = preset.suggestedPointSize
        var frame = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        frame.origin.x = window.frame.midX - frame.width / 2
        frame.origin.y = window.frame.midY - frame.height / 2
        window.setFrame(frame, display: true, animate: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    }

    func applyWindowBehavior() {
        guard let controller, let window else { return }
        window.level = controller.isAlwaysOnTop ? .floating : .normal
        window.collectionBehavior = controller.followsAllSpaces
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
        guard controller?.presentationLock == true else { return true }
        NSSound.beep()
        controller?.transientNotice = L10n.text(
            "プレゼンテーションロック中です。設定から解除できます。",
            "Presentation Lock is on. Turn it off in Appearance."
        )
        return false
    }

    func windowWillClose(_ notification: Notification) {
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
