import AppKit
import StagePaneCore
import XCTest
@testable import StagePane

final class StageWindowMenuTests: XCTestCase {
    @MainActor
    func testNativeMenuValidationTracksFullScreenTransitions() throws {
        try withController { controller in
            let menu = controller.makeStageContextMenu()
            XCTAssertTrue(menu.autoenablesItems)
            let maximize = try item(#selector(AppController.toggleStageMaximized), in: menu)
            let fullScreen = try item(#selector(AppController.toggleStageFullScreen), in: menu)
            let protection = try item(#selector(AppController.toggleStageProtection), in: menu)
            let geometryActions = [
                #selector(AppController.toggleStageMaximized),
                #selector(AppController.enlargeStageForSharing),
                #selector(AppController.toggleStageAlwaysOnTop),
                #selector(AppController.toggleStageAllSpaces)
            ]

            for (isFullScreen, isTransitioning) in [
                (false, false), (false, true), (true, false), (true, true), (false, false)
            ] {
                controller.updateStageFullScreenState(
                    isFullScreen: isFullScreen,
                    isTransitioning: isTransitioning
                )
                // Exercise AppKit's automatic target validation, rather than
                // calling the controller's validation implementation directly.
                menu.update()
                for action in geometryActions {
                    XCTAssertEqual(try item(action, in: menu).isEnabled, !isFullScreen && !isTransitioning)
                }
                XCTAssertEqual(fullScreen.isEnabled, !isTransitioning)
                XCTAssertEqual(fullScreen.title, isFullScreen
                    ? L10n.text("Stageのフルスクリーンを終了", "Exit Stage Full Screen")
                    : L10n.text("Stageをフルスクリーンにする", "Enter Stage Full Screen"))
                XCTAssertTrue(protection.isEnabled)
            }
            XCTAssertEqual(maximize.title, L10n.text("Stageを最大化", "Maximize Stage"))
        }
    }

    @MainActor
    func testNativeMenuActionsRefreshPreferenceCheckmarks() throws {
        try withController { controller in
            controller.isAlwaysOnTop = false
            controller.followsAllSpaces = false
            controller.presentationLock = false
            let menu = controller.makeStageContextMenu()
            let actions = [
                #selector(AppController.toggleStageAlwaysOnTop),
                #selector(AppController.toggleStageAllSpaces),
                #selector(AppController.toggleStageProtection)
            ]

            menu.update()
            for action in actions {
                let menuItem = try item(action, in: menu)
                XCTAssertTrue(menuItem.target === controller)
                XCTAssertEqual(menuItem.state, .off)
                XCTAssertTrue(NSApp.sendAction(action, to: menuItem.target, from: menuItem))
            }
            menu.update()
            for action in actions {
                XCTAssertEqual(try item(action, in: menu).state, .on)
            }
            XCTAssertTrue(controller.isAlwaysOnTop)
            XCTAssertTrue(controller.followsAllSpaces)
            XCTAssertTrue(controller.presentationLock)

            for action in actions {
                let menuItem = try item(action, in: menu)
                XCTAssertTrue(NSApp.sendAction(action, to: menuItem.target, from: menuItem))
            }
            menu.update()
            for action in actions {
                XCTAssertEqual(try item(action, in: menu).state, .off)
            }
        }
    }

    @MainActor
    func testMaximizeRestoresSameWindowAndIgnoresFullScreenTransition() throws {
        try withController { controller in
            let screen = try XCTUnwrap(NSScreen.main)
            let stage = StageWindowController(controller: controller, capture: controller.capture)
            let window = try XCTUnwrap(stage.window)
            window.setFrameAutosaveName("")
            defer {
                window.setFrameAutosaveName("")
                window.close()
            }
            let available = window.contentRect(forFrameRect: screen.visibleFrame)
            let fitted = try XCTUnwrap(StageWindowSizing.fittedCanvasRect(
                in: available, aspectRatio: controller.preset.aspectRatio
            ))
            let original = CGRect(
                x: fitted.midX - fitted.width * 0.4,
                y: fitted.midY - fitted.height * 0.4,
                width: fitted.width * 0.8,
                height: fitted.height * 0.8
            )
            window.setFrame(window.frameRect(forContentRect: original), display: false)
            let originalFrame = window.frame
            let windowNumber = window.windowNumber
            let contentView = try XCTUnwrap(window.contentView)
            XCTAssertNotNil(contentView.menu)

            stage.toggleMaximized()
            XCTAssertTrue(stage.isMaximized)
            XCTAssertEqual(window.frame.width / window.frame.height, controller.preset.aspectRatio, accuracy: 0.01)
            XCTAssertEqual(window.frame.width, fitted.width, accuracy: 1)
            XCTAssertEqual(window.frame.height, fitted.height, accuracy: 1)
            XCTAssertTrue(stage.window === window)
            XCTAssertTrue(window.contentView === contentView)
            XCTAssertEqual(window.windowNumber, windowNumber)

            stage.toggleMaximized()
            XCTAssertFalse(stage.isMaximized)
            XCTAssertEqual(window.frame, originalFrame)

            stage.windowWillEnterFullScreen(Notification(name: NSWindow.willEnterFullScreenNotification, object: window))
            XCTAssertTrue(controller.stageFullScreenTransitionInProgress)
            stage.toggleMaximized()
            XCTAssertFalse(stage.isMaximized)
            XCTAssertEqual(window.frame, originalFrame)

            // Settle a cancelled transition without entering an actual Space.
            stage.windowDidExitFullScreen(Notification(name: NSWindow.didExitFullScreenNotification, object: window))
            XCTAssertFalse(controller.stageFullScreenTransitionInProgress)
            stage.toggleMaximized()
            XCTAssertTrue(stage.isMaximized)
            stage.toggleMaximized()
            XCTAssertEqual(window.frame, originalFrame)
        }
    }

    @MainActor
    private func item(_ action: Selector, in menu: NSMenu) throws -> NSMenuItem {
        try XCTUnwrap(menu.items.first { $0.action == action })
    }

    @MainActor
    private func withController(_ operation: (AppController) throws -> Void) rethrows {
        _ = NSApplication.shared
        let defaults = UserDefaults.standard
        // AppController normalizes pointer preferences during initialization;
        // keep that and the exercised window settings local to this test run.
        let keys = [
            "capture.pointerStyle", "capture.pointerDiameter", "capture.pointerColor", "capture.pointerGlow",
            "window.alwaysOnTop", "window.followsAllSpaces", "window.presentationLock",
            "NSWindow Frame StagePane.ShareStage"
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
