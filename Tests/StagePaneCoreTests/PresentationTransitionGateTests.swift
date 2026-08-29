import Foundation
import XCTest
@testable import StagePaneCore

final class PresentationTransitionGateTests: XCTestCase {
    func testTransitionRequiresHideBeforeShow() {
        var gate = PresentationTransitionGate()
        let context = gate.begin(
            token: UUID(),
            presentationGeneration: UUID()
        )

        XCTAssertEqual(gate.phase, .awaitingHide(context))
        XCTAssertFalse(gate.isVisible)
        XCTAssertFalse(gate.canRequestMediaData)
        XCTAssertFalse(gate.beginShow(context))

        XCTAssertTrue(gate.acknowledgeHide(context))
        XCTAssertEqual(gate.phase, .hidden(context))
        XCTAssertTrue(gate.canRequestMediaData)
        XCTAssertTrue(gate.beginShow(context))
        XCTAssertEqual(gate.phase, .awaitingShow(context))
        XCTAssertTrue(gate.acknowledgeShow(context))
        XCTAssertTrue(gate.isVisible)
    }

    func testCancelledCallbackCannotAdvanceNewTransition() {
        var gate = PresentationTransitionGate()
        let token = UUID()
        let generation = UUID()
        let stale = gate.begin(
            token: token,
            presentationGeneration: generation
        )
        gate.cancel()
        let current = gate.begin(
            token: token,
            presentationGeneration: generation
        )

        XCTAssertGreaterThan(current.revision, stale.revision)
        XCTAssertFalse(gate.acknowledgeHide(stale))
        XCTAssertEqual(gate.phase, .awaitingHide(current))
        XCTAssertTrue(gate.acknowledgeHide(current))
    }

    func testTokenAndGenerationArePartOfCallbackFence() {
        var gate = PresentationTransitionGate()
        let context = gate.begin(
            token: UUID(),
            presentationGeneration: UUID()
        )
        let wrongToken = PresentationTransitionGate.Context(
            revision: context.revision,
            token: UUID(),
            presentationGeneration: context.presentationGeneration
        )
        let wrongGeneration = PresentationTransitionGate.Context(
            revision: context.revision,
            token: context.token,
            presentationGeneration: UUID()
        )

        XCTAssertFalse(gate.acknowledgeHide(wrongToken))
        XCTAssertFalse(gate.acknowledgeHide(wrongGeneration))
        XCTAssertTrue(gate.acknowledgeHide(context))
    }

    func testMissingGeometryCanRemainSuppressedUntilAnotherTransition() {
        var gate = PresentationTransitionGate()
        let first = gate.begin(
            token: UUID(),
            presentationGeneration: UUID()
        )
        XCTAssertTrue(gate.acknowledgeHide(first))
        XCTAssertTrue(gate.suppress(first))
        XCTAssertEqual(gate.phase, .suppressed)
        XCTAssertFalse(gate.canRequestMediaData)

        let replacement = gate.begin(
            token: first.token,
            presentationGeneration: first.presentationGeneration
        )
        XCTAssertGreaterThan(replacement.revision, first.revision)
        XCTAssertEqual(gate.phase, .awaitingHide(replacement))
    }
}
