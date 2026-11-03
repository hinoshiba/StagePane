import AppKit
import XCTest
@testable import StagePane

final class ScreenRecordingPermissionTests: XCTestCase {
    @MainActor
    func testNormalLaunchDoesNotCheckRequestOrPresentAPermissionWindow() {
        _ = NSApplication.shared
        let previousActivationPolicy = NSApp.activationPolicy()
        let existingWindows = Set(NSApp.windows.map(ObjectIdentifier.init))
        NSApp.setActivationPolicy(.accessory)
        NSApp.finishLaunching()
        NSApp.activate(ignoringOtherApps: true)
        let defaults = UserDefaults.standard
        let keys = [
            "NSWindow Frame StagePane.ShareStage", "NSWindow Frame StagePane.Workspace",
            "onboarding.macScreenRecordingAccessChecked"
        ]
        let values = keys.map { defaults.object(forKey: $0) }
        defer {
            for window in NSApp.windows where !existingWindows.contains(ObjectIdentifier(window)) && !window.frameAutosaveName.isEmpty {
                window.close()
            }
            NSApp.setActivationPolicy(previousActivationPolicy)
            for (key, value) in zip(keys, values) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        // A fresh installation must not depend on the retired onboarding flag.
        defaults.removeObject(forKey: "onboarding.macScreenRecordingAccessChecked")
        var permissionCalls = 0
        let controller = AppController(
            screenRecordingPreflight: { permissionCalls += 1; return false },
            screenRecordingRequest: { permissionCalls += 1; return false }
        )

        controller.start()
        controller.refreshMacScreenRecordingAccess()

        XCTAssertEqual(permissionCalls, 0)
        XCTAssertTrue(controller.workspaceIsVisible)
        XCTAssertTrue(controller.stageIsVisible)
        XCTAssertNil(defaults.object(forKey: "onboarding.macScreenRecordingAccessChecked"))
        let newWindows = NSApp.windows.filter { !existingWindows.contains(ObjectIdentifier($0)) && $0.isVisible }
        XCTAssertFalse(newWindows.contains { $0.frameAutosaveName == "StagePane.MacScreenRecordingAccess" })
    }

    @MainActor
    func testActivationBeforeOpeningAccessSettingsDoesNotQueryOrRequestPermission() {
        var checks = 0
        var requests = 0
        let controller = AppController(
            screenRecordingPreflight: { checks += 1; return false },
            screenRecordingRequest: { requests += 1; return false }
        )

        controller.refreshMacScreenRecordingAccess()
        controller.refreshMacScreenRecordingAccess()

        XCTAssertEqual(checks, 0)
        XCTAssertEqual(requests, 0)
        XCTAssertFalse(controller.hasRequestedMacScreenRecordingAccess)
    }

    @MainActor
    func testOpeningAccessSettingsReadsStatusWithoutRequestingPermission() {
        _ = NSApplication.shared
        var requests = 0
        let controller = AppController(
            screenRecordingPreflight: { true },
            screenRecordingRequest: { requests += 1; return true }
        )
        let suiteName = "StagePane.PermissionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(SettingsPane.access.rawValue, forKey: "StagePane.Settings.SelectedPane")
        let settings = SettingsWindowController(controller: controller, capture: controller.capture, defaults: defaults)
        defer { settings.close() }

        settings.present()

        XCTAssertTrue(controller.hasMacScreenRecordingAccess)
        XCTAssertEqual(requests, 0)
        XCTAssertFalse(controller.hasRequestedMacScreenRecordingAccess)
    }

    @MainActor
    func testExplicitRequestImmediatelyUsesSystemRequestAndRefreshesStatus() {
        var allowed = false
        var requests = 0
        let controller = AppController(
            screenRecordingPreflight: { allowed },
            screenRecordingRequest: { requests += 1; allowed = true; return true }
        )

        controller.requestMacScreenRecordingAccess()

        XCTAssertEqual(requests, 1)
        XCTAssertTrue(controller.hasRequestedMacScreenRecordingAccess)
        XCTAssertTrue(controller.hasMacScreenRecordingAccess)
        XCTAssertFalse(controller.capture.isCaptureActive)
    }

    @MainActor
    func testDenialDoesNotRepeatRequestOnActivationOrRetry() {
        var allowed = false
        var requests = 0
        let controller = AppController(
            screenRecordingPreflight: { allowed },
            screenRecordingRequest: { requests += 1; return false }
        )

        controller.requestMacScreenRecordingAccess()
        controller.refreshMacScreenRecordingAccess()
        controller.requestMacScreenRecordingAccess()

        XCTAssertEqual(requests, 1)
        XCTAssertFalse(controller.hasMacScreenRecordingAccess)
        XCTAssertFalse(controller.capture.isCaptureActive)
        // Returning from System Settings updates the status without another request.
        allowed = true
        controller.refreshMacScreenRecordingAccess()
        XCTAssertTrue(controller.hasMacScreenRecordingAccess)
        XCTAssertEqual(requests, 1)
    }

    @MainActor
    func testExistingAccessSkipsSystemRequest() {
        var requests = 0
        let controller = AppController(
            screenRecordingPreflight: { true },
            screenRecordingRequest: { requests += 1; return true }
        )

        controller.requestMacScreenRecordingAccess()

        XCTAssertTrue(controller.hasMacScreenRecordingAccess)
        XCTAssertFalse(controller.hasRequestedMacScreenRecordingAccess)
        XCTAssertEqual(requests, 0)
    }
}
