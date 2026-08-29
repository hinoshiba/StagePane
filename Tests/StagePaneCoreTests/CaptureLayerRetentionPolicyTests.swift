import XCTest
@testable import StagePaneCore

final class CaptureLayerRetentionPolicyTests: XCTestCase {
    func testUnexpectedCaptureEndRetainsLogicalLayer() {
        for reason in CaptureBindingEndReason.allCases {
            XCTAssertEqual(
                CaptureLayerRetentionPolicy.disposition(
                    for: reason,
                    removalWasExplicitlyRequested: false
                ),
                .retainLayerForReselection,
                "Unexpected \(reason) should preserve editor state"
            )
        }
    }

    func testExplicitRemovalDestroysLogicalLayer() {
        for reason in CaptureBindingEndReason.allCases {
            XCTAssertEqual(
                CaptureLayerRetentionPolicy.disposition(
                    for: reason,
                    removalWasExplicitlyRequested: true
                ),
                .removeLayer,
                "Explicit removal should win over \(reason)"
            )
        }
    }

    func testStopFailureKeepsRetainedTeardownRetryable() {
        XCTAssertEqual(
            CaptureLayerRetentionPolicy.dispositionAfterStopFailure(
                pendingDisposition: .retainLayerForReselection,
                removalWasExplicitlyRequested: false
            ),
            .retainLayerForReselection
        )
        XCTAssertTrue(
            CaptureLayerRetentionPolicy.canRetryRetainedTeardownAfterStopFailure(
                stopCaptureFailed: true,
                pendingDisposition: .retainLayerForReselection,
                removalWasExplicitlyRequested: false
            )
        )
    }

    func testRetainedTeardownRetryRequiresAStopFailureAndPendingIntent() {
        XCTAssertFalse(
            CaptureLayerRetentionPolicy.canRetryRetainedTeardownAfterStopFailure(
                stopCaptureFailed: false,
                pendingDisposition: .retainLayerForReselection,
                removalWasExplicitlyRequested: false
            )
        )
        XCTAssertFalse(
            CaptureLayerRetentionPolicy.canRetryRetainedTeardownAfterStopFailure(
                stopCaptureFailed: true,
                pendingDisposition: nil,
                removalWasExplicitlyRequested: false
            )
        )
        XCTAssertFalse(
            CaptureLayerRetentionPolicy.canRetryRetainedTeardownAfterStopFailure(
                stopCaptureFailed: true,
                pendingDisposition: .removeLayer,
                removalWasExplicitlyRequested: false
            )
        )
    }

    func testExplicitRemovalPreventsRetainedTeardownRetry() {
        XCTAssertEqual(
            CaptureLayerRetentionPolicy.dispositionAfterStopFailure(
                pendingDisposition: .retainLayerForReselection,
                removalWasExplicitlyRequested: true
            ),
            .removeLayer
        )
        XCTAssertFalse(
            CaptureLayerRetentionPolicy.canRetryRetainedTeardownAfterStopFailure(
                stopCaptureFailed: true,
                pendingDisposition: .retainLayerForReselection,
                removalWasExplicitlyRequested: true
            )
        )
    }

    func testStopFailureNeverDowngradesPendingRemovalOrCreatesAnIntent() {
        XCTAssertEqual(
            CaptureLayerRetentionPolicy.dispositionAfterStopFailure(
                pendingDisposition: .removeLayer,
                removalWasExplicitlyRequested: false
            ),
            .removeLayer
        )
        XCTAssertNil(
            CaptureLayerRetentionPolicy.dispositionAfterStopFailure(
                pendingDisposition: nil,
                removalWasExplicitlyRequested: false
            )
        )
    }

    func testResetFailureIsUnavailableWhileALogicalLayerIsRetained() {
        XCTAssertFalse(
            CaptureLayerRetentionPolicy.canResetCaptureFailure(
                captureIsActive: false,
                hasCaptureFailure: true,
                hasRetainedLayers: true
            )
        )
    }

    func testResetFailureRequiresAnInactiveFailedCaptureWithNoLayers() {
        XCTAssertTrue(
            CaptureLayerRetentionPolicy.canResetCaptureFailure(
                captureIsActive: false,
                hasCaptureFailure: true,
                hasRetainedLayers: false
            )
        )
        XCTAssertFalse(
            CaptureLayerRetentionPolicy.canResetCaptureFailure(
                captureIsActive: true,
                hasCaptureFailure: true,
                hasRetainedLayers: false
            )
        )
        XCTAssertFalse(
            CaptureLayerRetentionPolicy.canResetCaptureFailure(
                captureIsActive: false,
                hasCaptureFailure: false,
                hasRetainedLayers: false
            )
        )
    }
}
