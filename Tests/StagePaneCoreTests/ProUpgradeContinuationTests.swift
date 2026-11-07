import XCTest
@testable import StagePaneCore

final class ProUpgradeContinuationTests: XCTestCase {
    func testGroupPurchaseContinuesOnceAndSwitchingContextCancelsIt() {
        var state = ProUpgradeContinuation()
        state.begin(.addScreenGroup)
        state.accessChanged(hasAccess: true, gainedAccess: true)
        let generation = state.generation
        XCTAssertEqual(state.consume(generation: generation, isIdle: true, contextIsValid: true), .addScreenGroup)
        XCTAssertNil(state.consume(generation: generation, isIdle: true, contextIsValid: true))

        state.begin(.addScreenGroup)
        let pending = state.generation
        state.cancel()
        state.accessChanged(hasAccess: true, gainedAccess: true)
        XCTAssertNil(state.consume(generation: pending, isIdle: true, contextIsValid: true))
    }

    func testWaitsForPurchaseToFinishAndResumesOnlyOnce() {
        var state = ProUpgradeContinuation()
        state.begin(.addSource)
        let generation = state.generation
        state.accessChanged(hasAccess: true, gainedAccess: true)
        XCTAssertNil(state.consume(generation: generation, isIdle: false, contextIsValid: true))
        XCTAssertEqual(state.consume(generation: generation, isIdle: true, contextIsValid: true), .addSource)
        XCTAssertNil(state.consume(generation: generation, isIdle: true, contextIsValid: true))
    }

    func testCloseOrAnotherTaskPreventsLateContinuation() {
        for explicitlyCancelled in [true, false] {
            var state = ProUpgradeContinuation()
            state.begin(.hideWatermark)
            let generation = state.generation
            if explicitlyCancelled { state.cancel() }
            state.accessChanged(hasAccess: true, gainedAccess: true)
            XCTAssertNil(state.consume(
                generation: generation, isIdle: true, contextIsValid: explicitlyCancelled
            ))
            XCTAssertNil(state.consume(generation: state.generation, isIdle: true, contextIsValid: true))
        }
    }

    func testOldScheduledCallbackCannotConsumeNewRequest() {
        var state = ProUpgradeContinuation()
        state.begin(.addSource)
        let previous = state.generation
        state.begin(.hideWatermark)
        state.accessChanged(hasAccess: true, gainedAccess: true)
        XCTAssertNil(state.consume(generation: previous, isIdle: true, contextIsValid: true))
        XCTAssertEqual(
            state.consume(generation: state.generation, isIdle: true, contextIsValid: true),
            .hideWatermark
        )
    }

    func testDirectPurchaseDoesNotStartAnUnrequestedAction() {
        var state = ProUpgradeContinuation()
        state.begin(nil)
        state.accessChanged(hasAccess: true, gainedAccess: true)
        XCTAssertNil(state.consume(generation: state.generation, isIdle: true, contextIsValid: true))
    }

    func testExistingAccessAndRevocationCannotTriggerContinuation() {
        var state = ProUpgradeContinuation()
        state.begin(.hideWatermark)
        state.accessChanged(hasAccess: true, gainedAccess: false)
        XCTAssertNil(state.consume(generation: state.generation, isIdle: true, contextIsValid: true))
        state.accessChanged(hasAccess: true, gainedAccess: true)
        state.accessChanged(hasAccess: false, gainedAccess: false)
        XCTAssertNil(state.consume(generation: state.generation, isIdle: true, contextIsValid: true))
    }
}
