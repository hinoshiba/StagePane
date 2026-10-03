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

    init(controller: AppController, capture: CaptureCoordinator) {
        self.controller = controller
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
        window.contentViewController = NSHostingController(
            rootView: StageView(controller: controller, capture: capture)
        )
        window.isMovableByWindowBackground = false

        super.init(window: window)
        window.delegate = self
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
        window.contentMinSize = StageWindowSizing.minimumContentSize(for: preset)
        window.contentAspectRatio = NSSize(width: preset.pixelWidth, height: preset.pixelHeight)
        guard resize else { return }

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
        guard let contentView = window?.contentView else { return }
        controller?.updateStageRenderingSize(contentView.convertToBacking(contentView.bounds).size)
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
