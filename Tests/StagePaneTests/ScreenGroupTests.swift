import AppKit
import ScreenCaptureKit
import StagePaneCore
import XCTest
@testable import StagePane

final class ScreenGroupTests: XCTestCase {
    @MainActor
    private func makeController() -> AppController {
        let suite = "StagePane.ScreenGroupTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        return AppController(
            screenRecordingPreflight: { XCTFail("Groups must not query capture permission"); return false },
            screenRecordingRequest: { XCTFail("Groups must not request capture permission"); return false },
            defaults: defaults
        )
    }

    @MainActor
    func testFreeAndProEnforceLimitsAtTheControllerBoundary() {
        let controller = makeController()
        controller.applyScreenGroupAccess(hasProAccess: false)
        XCTAssertEqual(controller.screenGroups.count, 1)
        XCTAssertFalse(controller.removeScreenGroup(controller.activeScreenGroupID))
        XCTAssertTrue(controller.addScreenGroup())
        let selected = controller.activeScreenGroupID
        XCTAssertFalse(controller.addScreenGroup())
        XCTAssertEqual(controller.activeScreenGroupID, selected)

        controller.applyScreenGroupAccess(hasProAccess: true)
        for _ in 2..<10 { XCTAssertTrue(controller.addScreenGroup()) }
        XCTAssertEqual(controller.screenGroups.count, 10)
        XCTAssertFalse(controller.addScreenGroup())
        XCTAssertEqual(Set(controller.screenGroups.map(\.id)).count, 10)
    }

    @MainActor
    func testSwitchingRestoresGroupSettingsAndInkWithoutOpeningCurtain() {
        let controller = makeController()
        let first = controller.activeScreenGroup
        controller.preset = .portrait
        controller.theme = .paper
        XCTAssertTrue(first.annotations.beginStroke(at: CGPoint(x: 20, y: 40), canvasSize: CGSize(width: 200, height: 100)))
        first.annotations.endStroke()
        let drawing = first.annotations.document
        XCTAssertTrue(controller.addScreenGroup())
        let second = controller.activeScreenGroup
        XCTAssertTrue(controller.outputScreenGroup === first)
        XCTAssertFalse(first.capture === second.capture)
        XCTAssertTrue(controller.annotations.isEmpty)
        controller.preset = .square
        controller.theme = .aurora

        XCTAssertTrue(controller.selectScreenGroup(first.id))
        XCTAssertTrue(controller.capture === first.capture)
        XCTAssertEqual(controller.preset, .portrait)
        XCTAssertEqual(controller.theme, .paper)
        XCTAssertEqual(controller.annotations.document, drawing)
        XCTAssertTrue(controller.privacyCurtain)
        XCTAssertEqual(controller.stageInteractionMode, .arrange)
        XCTAssertTrue(controller.hasAnnotations)

        controller.privacyCurtain = false
        XCTAssertTrue(controller.selectScreenGroup(second.id))
        XCTAssertEqual(controller.preset, .square)
        XCTAssertTrue(controller.annotations.isEmpty)
        XCTAssertFalse(controller.privacyCurtain)
        XCTAssertTrue(controller.outputScreenGroup === first)
        XCTAssertEqual(controller.outputPreset, .portrait)
        XCTAssertEqual(controller.outputScreenGroup.theme, .paper)
    }

    @MainActor
    func testOnlySelectedGroupAcceptsUnscopedPickerEvents() {
        let controller = makeController()
        let first = controller.capture
        XCTAssertTrue(first.handlesPickerCallback(for: nil))
        XCTAssertTrue(controller.addScreenGroup())
        XCTAssertFalse(first.canRequestSourceAddition)
        XCTAssertFalse(first.handlesPickerCallback(for: nil))
        XCTAssertTrue(controller.capture.handlesPickerCallback(for: nil))
        let unrelatedStream = SCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        XCTAssertFalse(controller.capture.handlesPickerCallback(for: unrelatedStream))
        XCTAssertFalse(first.handlesPickerCallback(for: unrelatedStream))
    }

    @MainActor
    func testPickerBlocksSwitchingUntilCancellationEvenAfterStop() async {
        let controller = makeController()
        let firstID = controller.activeScreenGroupID
        XCTAssertTrue(controller.addScreenGroup())
        let capture = controller.capture
        XCTAssertTrue(capture.beginPickerPresentation())
        XCTAssertFalse(controller.selectScreenGroup(firstID))
        XCTAssertFalse(controller.addScreenGroup())
        XCTAssertFalse(controller.removeScreenGroup(firstID))
        XCTAssertFalse(controller.sendPreviewToStage())
        XCTAssertEqual(controller.outputScreenGroupID, firstID)
        controller.stopAllGroups()
        XCTAssertFalse(controller.canChangeScreenGroup)
        let canceled = expectation(description: "Picker cancellation releases the group switch")
        let subscription = capture.$isPickerPresented.dropFirst().filter { !$0 }.sink { _ in canceled.fulfill() }
        capture.contentSharingPicker(.shared, didCancelFor: nil)
        await fulfillment(of: [canceled], timeout: 2)
        withExtendedLifetime(subscription) {}
        XCTAssertTrue(controller.selectScreenGroup(firstID))
    }

    @MainActor
    func testCanceledRemovedReplacementStillReleasesItsPickerOwner() async {
        let first = CaptureCoordinator(acceptsNewSources: true)
        let second = CaptureCoordinator(acceptsNewSources: false)
        let stream = SCStream(filter: SCContentFilter(), configuration: SCStreamConfiguration(), delegate: nil)
        XCTAssertTrue(first.beginPickerPresentation(replacing: StageSourceID(rawValue: "removed"), stream: stream))
        first.stop()
        first.setAcceptsNewSources(false)
        second.setAcceptsNewSources(true)
        XCTAssertTrue(first.handlesPickerCallback(for: stream))
        XCTAssertFalse(second.handlesPickerCallback(for: nil))
        XCTAssertFalse(second.canRequestSourceAddition)
        let canceled = expectation(description: "Detached replacement cancellation")
        let subscription = first.$isPickerPresented.dropFirst().filter { !$0 }.sink { _ in canceled.fulfill() }
        first.contentSharingPicker(.shared, didCancelFor: stream)
        await fulfillment(of: [canceled], timeout: 2)
        withExtendedLifetime(subscription) {}
        XCTAssertFalse(first.handlesPickerCallback(for: stream))
        XCTAssertTrue(second.handlesPickerCallback(for: nil))
        XCTAssertTrue(second.canRequestSourceAddition)
    }

    @MainActor
    func testInactivePickerFailureDoesNotChangeEitherGroup() async {
        let controller = makeController()
        let first = controller.capture
        XCTAssertTrue(controller.addScreenGroup())
        first.contentSharingPickerStartDidFailWithError(NSError(domain: "test", code: 1))
        await Task.yield()
        XCTAssertEqual(first.phase, .idle)
        XCTAssertEqual(controller.capture.phase, .idle)
        XCTAssertNil(controller.captureAccessIssueNotice)
    }

    @MainActor
    func testDowngradeLocksExtraGroupsWithoutDeletingTheirWork() {
        let controller = makeController()
        controller.applyScreenGroupAccess(hasProAccess: true)
        XCTAssertTrue(controller.addScreenGroup())
        XCTAssertTrue(controller.addScreenGroup())
        let third = controller.activeScreenGroup
        controller.renameScreenGroup(third.id, to: "Demo")
        XCTAssertTrue(third.annotations.beginStroke(at: .zero, canvasSize: CGSize(width: 100, height: 100)))
        third.annotations.endStroke()
        controller.privacyCurtain = false

        controller.applyScreenGroupAccess(hasProAccess: false)
        XCTAssertEqual(controller.screenGroups.count, 3)
        XCTAssertEqual(controller.activeScreenGroupID, controller.screenGroups[0].id)
        XCTAssertEqual(controller.outputScreenGroupID, controller.screenGroups[0].id)
        XCTAssertFalse(controller.privacyCurtain)
        XCTAssertFalse(controller.selectScreenGroup(third.id))
        XCTAssertFalse(controller.addScreenGroup())
        XCTAssertFalse(third.capture.acceptsNewSources)
        XCTAssertFalse(third.annotations.isEmpty)

        controller.applyScreenGroupAccess(hasProAccess: true)
        XCTAssertTrue(controller.selectScreenGroup(third.id))
        XCTAssertEqual(controller.activeScreenGroup.title, "Demo")
        XCTAssertFalse(controller.annotations.isEmpty)
    }

    @MainActor
    func testRemovingGroupsKeepsOneAndRecoversAnAvailableSlot() {
        let controller = makeController()
        controller.applyScreenGroupAccess(hasProAccess: false)
        let firstID = controller.activeScreenGroupID
        XCTAssertTrue(controller.addScreenGroup())
        let secondID = controller.activeScreenGroupID
        controller.privacyCurtain = false
        XCTAssertTrue(controller.removeScreenGroup(secondID))
        XCTAssertEqual(controller.activeScreenGroupID, firstID)
        XCTAssertEqual(controller.outputScreenGroupID, firstID)
        XCTAssertFalse(controller.privacyCurtain)
        XCTAssertTrue(controller.addScreenGroup())
        let thirdID = controller.activeScreenGroupID
        XCTAssertNotEqual(thirdID, secondID)
        XCTAssertTrue(controller.removeScreenGroup(firstID))
        XCTAssertEqual(controller.activeScreenGroupID, thirdID)
        XCTAssertEqual(controller.outputScreenGroupID, thirdID)
        XCTAssertTrue(controller.privacyCurtain)
        XCTAssertFalse(controller.removeScreenGroup(thirdID))
        XCTAssertFalse(controller.selectScreenGroup(UUID()))
    }

    @MainActor
    func testStopAllClearsInkInInactiveGroupsAndKeepsTabs() {
        let controller = makeController()
        let first = controller.activeScreenGroup
        XCTAssertTrue(first.annotations.beginStroke(at: .zero, canvasSize: CGSize(width: 100, height: 100)))
        XCTAssertTrue(controller.addScreenGroup())
        XCTAssertTrue(controller.annotations.beginStroke(at: .zero, canvasSize: CGSize(width: 100, height: 100)))
        var completed = false
        controller.stopAllGroups { error in
            XCTAssertNil(error)
            completed = true
        }
        XCTAssertTrue(completed)
        XCTAssertTrue(controller.screenGroups.allSatisfy { $0.annotations.isEmpty })
        XCTAssertEqual(controller.screenGroups.count, 2)
        XCTAssertFalse(controller.isStoppingAllGroups)
        XCTAssertTrue(controller.privacyCurtain)
    }

    @MainActor
    func testAudienceImageChangesOnlyWhenPreviewIsSentToTheSameWindow() throws {
        _ = NSApplication.shared
        let controller = makeController()
        controller.theme = .paper
        controller.privacyCurtain = false
        let firstID = controller.activeScreenGroupID
        let stage = StageWindowController(controller: controller)
        defer { stage.window?.orderOut(nil) }
        let window = try XCTUnwrap(stage.window)
        let number = window.windowNumber
        func corner() throws -> NSColor {
            let canvas = stage.stageCanvasView
            canvas.layoutSubtreeIfNeeded()
            canvas.displayIfNeeded()
            let png = try StageWindowSnapshotter.capture(contentView: canvas)
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: png.pngData))
            return try XCTUnwrap(bitmap.colorAt(x: 10, y: 10))
        }
        let firstColor = try corner()
        XCTAssertTrue(controller.addScreenGroup())
        controller.theme = .midnight
        XCTAssertEqual(try corner(), firstColor, "Preview theme changes must not reach the audience")
        let secondID = controller.activeScreenGroupID
        XCTAssertTrue(controller.sendPreviewToStage())
        let secondColor = try corner()
        XCTAssertNotEqual(firstColor, secondColor)
        XCTAssertEqual(controller.outputScreenGroupID, secondID)
        XCTAssertTrue(controller.selectScreenGroup(firstID))
        XCTAssertEqual(try corner(), secondColor)
        XCTAssertTrue(controller.sendPreviewToStage())
        XCTAssertEqual(try corner(), firstColor)
        XCTAssertTrue(stage.window === window)
        XCTAssertEqual(window.windowNumber, number)
    }

    @MainActor
    func testSendingPreviewPreservesCurtainAndIsolatesInkAndMagnifier() {
        let controller = makeController()
        let first = controller.activeScreenGroup
        XCTAssertTrue(controller.addScreenGroup())
        controller.setStageInteractionMode(.magnify)
        XCTAssertFalse(controller.showsAudienceMagnifier)
        XCTAssertTrue(controller.annotations.beginStroke(at: .zero, canvasSize: CGSize(width: 100, height: 100)))
        controller.annotations.endStroke()
        XCTAssertTrue(first.annotations.isEmpty)
        XCTAssertTrue(controller.sendPreviewToStage())
        XCTAssertTrue(controller.privacyCurtain)
        XCTAssertTrue(controller.showsAudienceMagnifier)
        XCTAssertFalse(controller.canSendPreviewToStage)
        XCTAssertTrue(controller.selectScreenGroup(first.id))
        XCTAssertFalse(controller.showsAudienceMagnifier)
        XCTAssertFalse(controller.outputScreenGroup.annotations.isEmpty)
        controller.privacyCurtain = false
        XCTAssertTrue(controller.sendPreviewToStage())
        XCTAssertFalse(controller.privacyCurtain)
        XCTAssertTrue(controller.outputScreenGroup.annotations.isEmpty)
    }

    @MainActor
    func testDowngradeClosesCurtainWhenOutputGroupBecomesUnavailable() {
        let controller = makeController()
        controller.applyScreenGroupAccess(hasProAccess: true)
        let firstID = controller.activeScreenGroupID
        XCTAssertTrue(controller.addScreenGroup())
        XCTAssertTrue(controller.addScreenGroup())
        XCTAssertTrue(controller.sendPreviewToStage())
        XCTAssertTrue(controller.selectScreenGroup(firstID))
        controller.privacyCurtain = false
        controller.applyScreenGroupAccess(hasProAccess: false)
        XCTAssertTrue(controller.privacyCurtain)
        XCTAssertEqual(controller.outputScreenGroupID, firstID)
        XCTAssertEqual(controller.activeScreenGroupID, firstID)
    }

    @MainActor
    func testStageGeometryUsesOutputPresetWhileEditingAnotherGroup() throws {
        _ = NSApplication.shared
        let controller = makeController()
        controller.preset = .widescreen
        let first = controller.activeScreenGroup
        let existingWindows = Set(NSApp.windows.map(ObjectIdentifier.init))
        controller.start(showWindows: false)
        let windows = NSApp.windows.filter { !existingWindows.contains(ObjectIdentifier($0)) }
        defer {
            for window in windows {
                window.setFrameAutosaveName("")
                window.close()
            }
        }
        let window = try XCTUnwrap(windows.first { $0.windowController is StageWindowController })
        let stage = try XCTUnwrap(window.windowController as? StageWindowController)
        window.setFrameAutosaveName("")
        stage.applyPreset(.widescreen, resize: true)
        let initialFrame = window.frame
        let windowNumber = window.windowNumber
        XCTAssertTrue(controller.addScreenGroup())
        controller.setPreset(.portrait)
        XCTAssertEqual(first.preset, .widescreen)
        XCTAssertEqual(controller.outputPreset, .widescreen)
        XCTAssertEqual(window.frame, initialFrame)
        XCTAssertTrue(controller.sendPreviewToStage())
        XCTAssertEqual(window.frame.width / window.frame.height, StagePreset.portrait.aspectRatio, accuracy: 0.01)
        XCTAssertEqual(stage.stageCanvasView.bounds.width / stage.stageCanvasView.bounds.height, StagePreset.portrait.aspectRatio, accuracy: 0.01)
        let outputFrame = window.frame
        XCTAssertTrue(controller.selectScreenGroup(first.id))
        XCTAssertEqual(window.frame, outputFrame)
        stage.toggleMaximized()
        XCTAssertEqual(window.frame.width / window.frame.height, StagePreset.portrait.aspectRatio, accuracy: 0.01)
        XCTAssertEqual(window.windowNumber, windowNumber)
    }

    @MainActor
    func testFullScreenTransitionsPreventGroupMutation() {
        let controller = makeController()
        let firstID = controller.activeScreenGroupID
        XCTAssertTrue(controller.addScreenGroup())
        controller.updateStageFullScreenState(isFullScreen: false, isTransitioning: true)
        XCTAssertFalse(controller.addScreenGroup())
        XCTAssertFalse(controller.selectScreenGroup(firstID))
        XCTAssertFalse(controller.removeScreenGroup(firstID))
        XCTAssertFalse(controller.sendPreviewToStage())
        controller.updateStageFullScreenState(isFullScreen: true, isTransitioning: false)
        XCTAssertTrue(controller.selectScreenGroup(firstID))
    }
}
