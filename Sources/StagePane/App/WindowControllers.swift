import AppKit
import StagePaneCore
import SwiftUI

@MainActor
final class ControlRoomWindowController: NSWindowController, NSWindowDelegate {
    init(controller: AppController, capture: CaptureCoordinator) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.controlWindowTitle
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isReleasedWhenClosed = false
        // The live editor now lives in the larger Workspace window, so the
        // Control Room can remain compact without collapsing its sidebar.
        window.contentMinSize = NSSize(width: 820, height: 580)
        window.setFrameAutosaveName("StagePane.ControlRoom")
        window.tabbingMode = .disallowed
        // The title and in-product guidance are intentional: AppKit no longer
        // provides a supported window-capture exclusion boundary. Users must
        // share the exact Stage window rather than this Control Room.
        window.contentViewController = NSHostingController(
            rootView: ControlRoomView(controller: controller, capture: capture)
        )

        super.init(window: window)
        window.delegate = self
        if window.frame.origin == .zero { window.center() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        window.contentMinSize = NSSize(width: 1040, height: 680)
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
}

@MainActor
final class StageWindowController: NSWindowController, NSWindowDelegate {
    private weak var controller: AppController?

    init(controller: AppController, capture: CaptureCoordinator) {
        self.controller = controller
        let suggested = controller.preset.suggestedPointSize
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: suggested.width,
                height: suggested.height
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.stageWindowTitle
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
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
}
