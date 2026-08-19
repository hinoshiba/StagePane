import XCTest
@testable import StagePaneCore

final class PreviewInputPermissionPolicyTests: XCTestCase {
    func testStoredMigrationValueAlwaysWins() {
        for storedValue in [false, true] {
            XCTAssertEqual(
                PreviewInputPermissionPolicy.initialRequestWasAttempted(
                    storedValue: storedValue,
                    isAdHocDevelopmentBuild: true,
                    hadExistingInstallationPreferences: true
                ),
                storedValue
            )
        }
    }

    func testExistingAdHocInstallMigratesDirectlyToRepair() {
        XCTAssertTrue(
            PreviewInputPermissionPolicy.initialRequestWasAttempted(
                storedValue: nil,
                isAdHocDevelopmentBuild: true,
                hadExistingInstallationPreferences: true
            )
        )
    }

    func testFreshOrConsistentlySignedInstallKeepsOneTimeRequest() {
        XCTAssertFalse(
            PreviewInputPermissionPolicy.initialRequestWasAttempted(
                storedValue: nil,
                isAdHocDevelopmentBuild: true,
                hadExistingInstallationPreferences: false
            )
        )
        XCTAssertFalse(
            PreviewInputPermissionPolicy.initialRequestWasAttempted(
                storedValue: nil,
                isAdHocDevelopmentBuild: false,
                hadExistingInstallationPreferences: true
            )
        )
    }

    func testTrustedStateNeverRequestsPromptForAnyEvent() {
        for requestWasAttempted in [false, true] {
            let state = PreviewInputPermissionState(
                isTrusted: true,
                requestWasAttempted: requestWasAttempted
            )

            for event in PreviewInputPermissionEvent.allCases {
                XCTAssertEqual(
                    PreviewInputPermissionPolicy.transition(from: state, for: event),
                    PreviewInputPermissionTransition(state: state, action: .refreshOnly)
                )
            }
        }
    }

    func testFirstExplicitContinuePromptsAndRecordsAttempt() {
        let initialState = PreviewInputPermissionState(
            isTrusted: false,
            requestWasAttempted: false
        )

        let first = PreviewInputPermissionPolicy.transition(
            from: initialState,
            for: .explicitContinue
        )

        XCTAssertEqual(first.action, .requestSystemPrompt)
        XCTAssertEqual(
            first.state,
            PreviewInputPermissionState(
                isTrusted: false,
                requestWasAttempted: true
            )
        )
    }

    func testLaterExplicitContinueRoutesToRepairWithoutAnotherPrompt() {
        let initialState = PreviewInputPermissionState(
            isTrusted: false,
            requestWasAttempted: false
        )
        let first = PreviewInputPermissionPolicy.transition(
            from: initialState,
            for: .explicitContinue
        )

        let later = PreviewInputPermissionPolicy.transition(
            from: first.state,
            for: .explicitContinue
        )

        XCTAssertEqual(later.action, .reviewRepair)
        XCTAssertEqual(later.state, first.state)
    }

    func testApplicationActivationNeverRequestsPrompt() {
        for requestWasAttempted in [false, true] {
            let state = PreviewInputPermissionState(
                isTrusted: false,
                requestWasAttempted: requestWasAttempted
            )

            XCTAssertEqual(
                PreviewInputPermissionPolicy.transition(
                    from: state,
                    for: .applicationActivation
                ),
                PreviewInputPermissionTransition(state: state, action: .refreshOnly)
            )
        }
    }

    func testManualRecheckNeverRequestsPrompt() {
        let state = PreviewInputPermissionState(
            isTrusted: false,
            requestWasAttempted: false
        )

        XCTAssertEqual(
            PreviewInputPermissionPolicy.transition(
                from: state,
                for: .manualRecheck
            ),
            PreviewInputPermissionTransition(state: state, action: .refreshOnly)
        )
    }
}
