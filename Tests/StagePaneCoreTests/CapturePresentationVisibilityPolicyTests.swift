import XCTest
@testable import StagePaneCore

final class CapturePresentationVisibilityPolicyTests: XCTestCase {
    func testRunningLayerWithCurrentFreshFrameIsVisible() {
        XCTAssertTrue(shouldPresent())
    }

    func testStopRequestImmediatelyHidesPresentation() {
        XCTAssertFalse(shouldPresent(isPauseTransitioning: true))
    }

    func testPausedLayerRemainsHidden() {
        XCTAssertFalse(shouldPresent(
            isPaused: true,
            isStreamRunning: false
        ))
    }

    func testResumeStartSuccessAloneDoesNotRevealRetainedFrame() {
        XCTAssertFalse(shouldPresent(
            awaitsFreshFrame: true,
            hasFreshFrame: false
        ))
    }

    func testFreshFrameAloneDoesNotRevealBeforeResumeStarts() {
        XCTAssertFalse(shouldPresent(
            isPaused: true,
            isPauseTransitioning: true,
            isStreamRunning: false
        ))
    }

    func testResumeRevealsOnlyAfterStartAndFreshFrameBothSucceed() {
        XCTAssertTrue(shouldPresent(
            isPaused: false,
            isPauseTransitioning: false,
            isStreamRunning: true,
            awaitsFreshFrame: false,
            hasFreshFrame: true
        ))
    }

    func testResumeFailureKeepsPresentationHidden() {
        XCTAssertFalse(shouldPresent(
            isPaused: true,
            isStreamRunning: false,
            awaitsFreshFrame: true,
            hasFreshFrame: false
        ))
    }

    func testStaleFrameDoesNotSatisfyCurrentGenerationFreshness() {
        // A candidate may still exist, but the generation fence remains closed
        // when its callback belongs to an older presentation.
        XCTAssertFalse(shouldPresent(
            awaitsFreshFrame: true,
            hasFreshFrame: true
        ))
    }

    func testSuppressedOrDisconnectedLayerIsNeverVisible() {
        XCTAssertFalse(shouldPresent(outputSuppressed: true))
        XCTAssertFalse(shouldPresent(needsReselection: true))
    }

    private func shouldPresent(
        outputSuppressed: Bool = false,
        needsReselection: Bool = false,
        isPaused: Bool = false,
        isPauseTransitioning: Bool = false,
        isStreamRunning: Bool = true,
        awaitsFreshFrame: Bool = false,
        hasFreshFrame: Bool = true
    ) -> Bool {
        CapturePresentationVisibilityPolicy.shouldPresent(
            CapturePresentationVisibilityInput(
                outputSuppressed: outputSuppressed,
                needsReselection: needsReselection,
                isPaused: isPaused,
                isPauseTransitioning: isPauseTransitioning,
                isStreamRunning: isStreamRunning,
                awaitsFreshFrame: awaitsFreshFrame,
                hasFreshFrame: hasFreshFrame
            )
        )
    }
}
