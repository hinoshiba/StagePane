import AppKit
import SwiftUI

enum SettingsPane: String, CaseIterable {
    case pointer
    case stage
    case window
    case access
    case pro

    var title: String {
        switch self {
        case .pointer: L10n.text("ポインタ", "Pointer")
        case .stage: L10n.text("ステージ", "Stage")
        case .window: L10n.text("ウインドウ", "Window")
        case .access: L10n.text("アクセスとプライバシー", "Access & Privacy")
        case .pro: "Pro"
        }
    }

    var symbol: String {
        switch self {
        case .pointer: "cursorarrow"
        case .stage: "rectangle.inset.filled"
        case .window: "macwindow"
        case .access: "hand.raised"
        case .pro: "star"
        }
    }

    fileprivate var toolbarIdentifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier("StagePane.Settings.\(rawValue)")
    }

    fileprivate var contentHeight: CGFloat {
        switch self {
        case .pointer: 340
        case .stage: 500
        case .window: 240
        case .access: 420
        case .pro: 220
        }
    }
}

/// A single modeless preferences window, independent of the editing workspace.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate {
    private static let selectedPaneKey = "StagePane.Settings.SelectedPane"
    private let controller: AppController
    private let capture: CaptureCoordinator
    private let defaults: UserDefaults
    private let host: NSHostingController<SettingsPaneView>
    private weak var originatingWindow: NSWindow?
    private weak var originatingResponder: NSResponder?
    private var mayRestoreOrigin = false
    private(set) var selectedPane: SettingsPane

    init(controller: AppController, capture: CaptureCoordinator, defaults: UserDefaults) {
        self.controller = controller
        self.capture = capture
        self.defaults = defaults
        selectedPane = defaults.string(forKey: Self.selectedPaneKey)
            .flatMap(SettingsPane.init(rawValue:)) ?? .pointer
        host = NSHostingController(
            rootView: SettingsPaneView(controller: controller, capture: capture, pane: selectedPane)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: selectedPane.contentHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = selectedPane.title
        window.titleVisibility = .visible
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.tabbingMode = .disallowed
        window.collectionBehavior = [.fullScreenNone]
        window.backgroundColor = .windowBackgroundColor
        window.contentViewController = host
        window.toolbarStyle = .preference
        super.init(window: window)

        let toolbar = NSToolbar(identifier: "StagePane.Settings")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.sizeMode = .regular
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.selectedItemIdentifier = selectedPane.toolbarIdentifier
        window.toolbar = toolbar
        window.delegate = self
        window.center()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyWindowChanged(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationResignedActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func present(pane: SettingsPane? = nil) {
        guard let window else { return }
        if NSApp.isActive, let origin = NSApp.keyWindow, origin !== window {
            originatingWindow = origin
            originatingResponder = origin.firstResponder
            mayRestoreOrigin = origin.isVisible && !origin.isMiniaturized
        } else if !window.isVisible {
            originatingWindow = nil
            originatingResponder = nil
            mayRestoreOrigin = false
        }
        if let pane { select(pane) }
        resizeToFitScreen()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func select(_ pane: SettingsPane) {
        guard let window else { return }
        if pane != selectedPane {
            selectedPane = pane
            host.rootView = SettingsPaneView(controller: controller, capture: capture, pane: pane)
        }
        defaults.set(pane.rawValue, forKey: Self.selectedPaneKey)
        window.title = pane.title
        window.toolbar?.selectedItemIdentifier = pane.toolbarIdentifier
        resizeToFitScreen()
    }

    private func resizeToFitScreen() {
        guard let window, let screen = window.screen ?? NSScreen.main else { return }
        let available = screen.visibleFrame.insetBy(dx: 16, dy: 16)
        let chromeHeight = window.frame.height - window.contentLayoutRect.height
        let contentSize = NSSize(
            width: min(680, available.width),
            height: min(selectedPane.contentHeight, max(200, available.height - chromeHeight))
        )
        // Keep the toolbar stationary while switching between short and long panes.
        let top = window.frame.maxY
        window.setContentSize(contentSize)
        var frame = window.frame
        frame.origin.y = top - frame.height
        frame.origin.x = min(max(frame.minX, available.minX), available.maxX - frame.width)
        frame.origin.y = min(max(frame.minY, available.minY), available.maxY - frame.height)
        window.setFrame(frame, display: window.isVisible)
    }

    @objc private func selectToolbarItem(_ sender: NSToolbarItem) {
        guard let pane = SettingsPane.allCases.first(where: {
            $0.toolbarIdentifier == sender.itemIdentifier
        }) else { return }
        select(pane)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsPane.allCases.map(\.toolbarIdentifier)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarAllowedItemIdentifiers(toolbar)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarAllowedItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard let pane = SettingsPane.allCases.first(where: {
            $0.toolbarIdentifier == itemIdentifier
        }) else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = pane.title
        item.paletteLabel = pane.title
        item.toolTip = pane.title
        item.image = NSImage(systemSymbolName: pane.symbol, accessibilityDescription: pane.title)
        item.target = self
        item.action = #selector(selectToolbarItem(_:))
        item.autovalidates = false
        return item
    }

    @objc private func keyWindowChanged(_ notification: Notification) {
        guard window?.isVisible == true,
              let changedWindow = notification.object as? NSWindow,
              changedWindow !== window else { return }
        // Native color editing and an attached sheet still belong to Settings.
        if changedWindow is NSColorPanel || changedWindow.sheetParent === window {
            return
        }
        // Once work moves elsewhere, closing Settings must not revive an old focus.
        mayRestoreOrigin = false
    }

    @objc private func applicationResignedActive() {
        mayRestoreOrigin = false
    }

    func windowWillClose(_ notification: Notification) {
        let shouldRestore = mayRestoreOrigin && window?.isKeyWindow == true
        let origin = originatingWindow
        let responder = originatingResponder
        mayRestoreOrigin = false
        originatingWindow = nil
        originatingResponder = nil
        guard shouldRestore, let origin,
              NSApp.isActive,
              origin.isVisible,
              !origin.isMiniaturized,
              origin.isOnActiveSpace else { return }

        // Choose the original editor before AppKit picks the next window.
        // Stage may have been revealed directly behind Settings by a preset
        // change; waiting until after close would otherwise make Stage key.
        origin.makeKeyAndOrderFront(nil)

        DispatchQueue.main.async { [weak origin, weak responder] in
            guard let origin,
                  NSApp.isActive,
                  origin.isVisible,
                  !origin.isMiniaturized,
                  origin.isOnActiveSpace,
                  NSApp.keyWindow === origin else { return }
            // Recheck membership: the prior editor may have been removed while
            // Settings was open (for example, when its source disconnected).
            if let view = responder as? NSView, view.window === origin {
                origin.makeFirstResponder(view)
            }
        }
    }
}
