import XCTest
@testable import StagePaneCore

final class TransientNoticeStateTests: XCTestCase {
    func testStartsWithoutANotice() {
        XCTAssertNil(TransientNoticeState().notice)
    }

    func testRepeatedMessageReceivesANewIdentity() {
        var state = TransientNoticeState()
        let first = state.present("Saved")
        let second = state.present("Saved")

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(state.notice, second)
    }

    func testStaleDismissalCannotClearReplacement() {
        var state = TransientNoticeState()
        let first = state.present("First")
        let second = state.present("Second")

        XCTAssertFalse(state.dismiss(id: first.id))
        XCTAssertEqual(state.notice, second)
        XCTAssertTrue(state.dismiss(id: second.id))
        XCTAssertNil(state.notice)
    }

    func testManualDismissalInvalidatesEarlierIdentity() {
        var state = TransientNoticeState()
        let dismissed = state.present("First")
        state.dismissCurrent()
        let replacement = state.present("Second")

        XCTAssertFalse(state.dismiss(id: dismissed.id))
        XCTAssertEqual(state.notice, replacement)
    }
}
