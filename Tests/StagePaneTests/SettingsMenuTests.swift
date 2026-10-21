import AppKit
import StagePaneCore
import XCTest
@testable import StagePane

final class SettingsMenuTests: XCTestCase {
    @MainActor
    func testPointerMenuActionsUpdateSavedPreferenceAndCheckmarksWithoutOpeningStage() throws {
        try withController { controller in
            controller.pointerStyle = .system
            let menu = try XCTUnwrap(StagePaneMenus.makePointerMenuItem(controller: controller).submenu)
            XCTAssertTrue(menu.autoenablesItems)

            for style in [StagePaneCore.PointerStyle.redDot, .hidden, .system] {
                let item = try pointerItem(style, in: menu)
                XCTAssertTrue(item.target === controller)
                XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(item.action), to: item.target, from: item))
                menu.update()

                XCTAssertEqual(controller.pointerStyle, style)
                XCTAssertEqual(UserDefaults.standard.string(forKey: "capture.pointerStyle"), style.rawValue)
                for candidate in StagePaneCore.PointerStyle.allCases {
                    XCTAssertEqual(try pointerItem(candidate, in: menu).state, candidate == style ? .on : .off)
                }
                XCTAssertEqual(controller.stageInteractionMode, .arrange)
                XCTAssertTrue(controller.privacyCurtain)
                XCTAssertFalse(controller.stageIsVisible)
                XCTAssertFalse(controller.workspaceIsVisible)
                XCTAssertFalse(controller.capture.isCaptureActive)
            }
        }
    }

    @MainActor
    func testPointerMenuExplainsTemporarySuppressionWithoutOverwritingPreference() throws {
        try withController { controller in
            for (mode, explanation) in [
                (StageInteractionMode.annotate, L10n.text("手書き中は一時的に非表示", "Temporarily hidden while drawing")),
                (.magnify, L10n.text("虫眼鏡中は一時的に非表示", "Temporarily hidden while magnifying"))
            ] {
                controller.pointerStyle = .system
                controller.setStageInteractionMode(mode)
                let menu = try XCTUnwrap(StagePaneMenus.makePointerMenuItem(controller: controller).submenu)
                menu.update()
                let status = try XCTUnwrap(menu.items.first { $0.title == explanation })
                XCTAssertNil(status.action)
                XCTAssertFalse(status.isEnabled)
                XCTAssertEqual(try pointerItem(.system, in: menu).state, .on)
                XCTAssertEqual(try pointerItem(.hidden, in: menu).state, .off)

                let laser = try pointerItem(.redDot, in: menu)
                XCTAssertTrue(laser.isEnabled)
                XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(laser.action), to: laser.target, from: laser))
                menu.update()
                XCTAssertEqual(controller.pointerStyle, .redDot)
                XCTAssertEqual(controller.stageInteractionMode, mode)
                XCTAssertTrue(controller.isAudiencePointerSuppressedByInteractionMode)
                XCTAssertEqual(try pointerItem(.redDot, in: menu).state, .on)
                XCTAssertEqual(try pointerItem(.hidden, in: menu).state, .off)

                controller.setStageInteractionMode(.arrange)
                StagePaneMenus.populatePointerMenu(menu, controller: controller)
                menu.update()
                XCTAssertFalse(menu.items.contains { $0.title == explanation })
                XCTAssertFalse(controller.isAudiencePointerSuppressedByInteractionMode)
                XCTAssertEqual(try pointerItem(.redDot, in: menu).state, .on)
                XCTAssertFalse(controller.capture.isCaptureActive)
                XCTAssertFalse(controller.stageIsVisible)
            }
        }
    }

    @MainActor
    func testNativeSettingsToolbarRemembersPaneAndPreservesEditingState() throws {
        try withController { controller in
            let suiteName = "StagePane.SettingsMenuTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
            defer { defaults.removePersistentDomain(forName: suiteName) }
            controller.setStageInteractionMode(.annotate)
            controller.pointerStyle = .redDot

            let settings = SettingsWindowController(
                controller: controller, capture: controller.capture, defaults: defaults
            )
            let window = try XCTUnwrap(settings.window)
            defer { window.close() }
            let toolbar = try XCTUnwrap(window.toolbar)
            XCTAssertEqual(settings.selectedPane, .pointer)
            XCTAssertEqual(window.title, SettingsPane.pointer.title)
            XCTAssertFalse(window.styleMask.contains(.miniaturizable))
            XCTAssertFalse(window.styleMask.contains(.resizable))
            XCTAssertTrue(window.styleMask.contains(.closable))

            for pane in [SettingsPane.stage, .window, .pointer] {
                let item = try XCTUnwrap(toolbar.items.first { $0.label == pane.title })
                XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(item.action), to: item.target, from: item))
                XCTAssertEqual(settings.selectedPane, pane)
                XCTAssertEqual(window.title, pane.title)
                XCTAssertEqual(toolbar.selectedItemIdentifier, item.itemIdentifier)
                XCTAssertTrue(settings.window === window)
                XCTAssertEqual(controller.stageInteractionMode, .annotate)
                XCTAssertEqual(controller.pointerStyle, .redDot)
                XCTAssertTrue(controller.privacyCurtain)
                XCTAssertFalse(controller.stageIsVisible)
                XCTAssertFalse(controller.workspaceIsVisible)
                XCTAssertFalse(controller.capture.isCaptureActive)
            }

            let stage = try XCTUnwrap(toolbar.items.first { $0.label == SettingsPane.stage.title })
            XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(stage.action), to: stage.target, from: stage))
            let reopened = SettingsWindowController(
                controller: controller, capture: controller.capture, defaults: defaults
            )
            defer { reopened.close() }
            XCTAssertEqual(reopened.selectedPane, .stage)
            XCTAssertEqual(reopened.window?.title, SettingsPane.stage.title)
            XCTAssertEqual(reopened.window?.toolbar?.selectedItemIdentifier, stage.itemIdentifier)
        }
    }

    @MainActor
    func testStageChangesKeepSettingsInFrontAndClosingRestoresWorkspaceResponder() throws {
        try withController { controller in
            let previousActivationPolicy = NSApp.activationPolicy()
            let existingWindows = Set(NSApp.windows.map(ObjectIdentifier.init))
            NSApp.setActivationPolicy(.accessory)
            NSApp.finishLaunching()
            NSApp.activate(ignoringOtherApps: true)
            controller.isAlwaysOnTop = false
            controller.start(showWindows: false)
            defer {
                for window in NSApp.windows where !existingWindows.contains(ObjectIdentifier(window)) {
                    window.close()
                }
                NSApp.setActivationPolicy(previousActivationPolicy)
            }

            controller.showStage()
            waitForAppKit { NSApp.keyWindow != nil }
            let stage = try XCTUnwrap(NSApp.keyWindow)
            controller.showStageWorkspace()
            waitForAppKit { NSApp.keyWindow !== stage }
            let workspace = try XCTUnwrap(NSApp.keyWindow)
            XCTAssertFalse(workspace === stage)
            let originalControl = NSSlider(value: 0.5, minValue: 0, maxValue: 1, target: nil, action: nil)
            workspace.contentView?.addSubview(originalControl)
            XCTAssertTrue(workspace.makeFirstResponder(originalControl))
            waitForAppKit { NSApp.isActive }
            XCTAssertTrue(NSApp.isActive)

            controller.showStageSettings()
            let settings = try XCTUnwrap(NSApp.keyWindow)
            XCTAssertEqual(settings.title, SettingsPane.stage.title)
            let input = NSTextField(string: "Continue editing")
            settings.contentView?.addSubview(input)
            XCTAssertTrue(settings.makeFirstResponder(input))
            let editingResponder = try XCTUnwrap(settings.firstResponder)

            for preset in [StagePreset.standard, .portrait, .widescreen] {
                controller.setPreset(preset)
                XCTAssertTrue(NSApp.keyWindow === settings)
                XCTAssertTrue(settings.firstResponder === editingResponder)
                XCTAssertLessThan(settings.orderedIndex, stage.orderedIndex)
                XCTAssertEqual(controller.preset, preset)
                XCTAssertTrue(stage.isVisible)
            }
            controller.enlargeStageForSharing()
            XCTAssertTrue(NSApp.keyWindow === settings)
            XCTAssertTrue(settings.firstResponder === editingResponder)
            XCTAssertLessThan(settings.orderedIndex, stage.orderedIndex)
            XCTAssertFalse(controller.capture.isCaptureActive)

            stage.orderOut(nil)
            XCTAssertFalse(stage.isVisible)
            controller.setPreset(.standard)
            XCTAssertTrue(stage.isVisible)
            XCTAssertTrue(NSApp.keyWindow === settings)
            XCTAssertTrue(settings.firstResponder === editingResponder)
            XCTAssertLessThan(settings.orderedIndex, stage.orderedIndex)

            settings.performClose(nil)
            waitForAppKit { NSApp.keyWindow === workspace && workspace.firstResponder === originalControl }
            XCTAssertFalse(settings.isVisible)
            XCTAssertTrue(stage.isVisible)
            XCTAssertTrue(NSApp.keyWindow === workspace)
            XCTAssertTrue(workspace.firstResponder === originalControl)

            controller.showStageSettings()
            controller.showStage()
            settings.close()
            waitForAppKit { !settings.isVisible }
            XCTAssertTrue(NSApp.keyWindow === stage)
        }
    }

    @MainActor
    private func waitForAppKit(_ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(1)
        while !condition(), Date() < deadline {
            while let event = NSApp.nextEvent(matching: .any, until: .distantPast, inMode: .default, dequeue: true) {
                NSApp.sendEvent(event)
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
    }

    @MainActor
    private func pointerItem(_ style: StagePaneCore.PointerStyle, in menu: NSMenu) throws -> NSMenuItem {
        try XCTUnwrap(menu.items.first {
            $0.action == #selector(AppController.selectPointerStyle(_:)) &&
                $0.representedObject as? String == style.rawValue
        })
    }

    @MainActor
    private func withController(_ operation: (AppController) throws -> Void) rethrows {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        // Preserve preferences normalized during construction or changed by
        // the native-window tests, including their frame autosave values.
        let keys = [
            "capture.pointerStyle", "capture.pointerDiameter", "capture.pointerColor", "capture.pointerGlow",
            "stage.preset", "window.alwaysOnTop", "StagePane.Settings.SelectedPane",
            "NSWindow Frame StagePane.ShareStage", "NSWindow Frame StagePane.Workspace"
        ]
        let originalValues = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, originalValues) {
                if let value {
                    defaults.set(value, forKey: key)
                } else {
                    defaults.removeObject(forKey: key)
                }
            }
        }
        try operation(AppController())
    }
}
