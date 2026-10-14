import StagePaneCore
import XCTest
@testable import StagePane

final class CaptureAccessIssueNoticeTests: XCTestCase {
    private let target = StageSourceID(rawValue: "failed-source")
    private let other = StageSourceID(rawValue: "already-capturing")
    private let added = StageSourceID(rawValue: "new-source")

    func testSourceFailureSurvivesCancelAndUnrelatedSourceRecovery() {
        let notice = CaptureAccessIssueNotice(
            issue: CaptureAccessIssue(title: "Failed", detail: "Select again", sourceID: target),
            sourceIDsAtFailure: [target, other]
        )

        // Canceling or retrying without a ready frame is not recovery.
        XCTAssertFalse(notice.isResolved(currentSourceIDs: [target, other], readySourceIDs: [other]))
        // Another source can recover or be added while the failed layer remains.
        XCTAssertFalse(notice.isResolved(currentSourceIDs: [target, other, added], readySourceIDs: [other, added]))
        XCTAssertTrue(notice.isResolved(currentSourceIDs: [target, other], readySourceIDs: [target, other]))
    }

    func testRemovingFailedLayerResolvesItsNotice() {
        let notice = CaptureAccessIssueNotice(
            issue: CaptureAccessIssue(title: "Failed", detail: "Select again", sourceID: target),
            sourceIDsAtFailure: [target, other]
        )

        XCTAssertTrue(notice.isResolved(currentSourceIDs: [other], readySourceIDs: [other]))
    }

    func testAddFailureRequiresANewReadySource() {
        let notice = CaptureAccessIssueNotice(
            issue: CaptureAccessIssue(title: "Picker failed", detail: "Add again"),
            sourceIDsAtFailure: [other]
        )

        // The existing capture stays active; neither it nor a canceled picker
        // should dismiss a failed Add Source operation.
        XCTAssertFalse(notice.isResolved(currentSourceIDs: [other], readySourceIDs: [other]))
        XCTAssertFalse(notice.isResolved(currentSourceIDs: [other, added], readySourceIDs: [other]))
        XCTAssertTrue(notice.isResolved(currentSourceIDs: [other, added], readySourceIDs: [other, added]))
    }

    func testFirstSourceFailureSurvivesCancelUntilSuccessfulCapture() {
        let notice = CaptureAccessIssueNotice(
            issue: CaptureAccessIssue(title: "Picker failed", detail: "Add again"),
            sourceIDsAtFailure: []
        )

        XCTAssertFalse(notice.isResolved(currentSourceIDs: [], readySourceIDs: []))
        XCTAssertFalse(notice.isResolved(currentSourceIDs: [added], readySourceIDs: []))
        XCTAssertTrue(notice.isResolved(currentSourceIDs: [added], readySourceIDs: [added]))
    }
}
