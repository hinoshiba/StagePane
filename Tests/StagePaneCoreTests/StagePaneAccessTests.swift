import XCTest
@testable import StagePaneCore

final class StagePaneAccessTests: XCTestCase {
    func testFreePlanAllowsFourSources() {
        XCTAssertEqual(StagePaneAccess.sourceLimit(hasProAccess: false), 4)
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 0, hasProAccess: false))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 3, hasProAccess: false))
        XCTAssertFalse(StagePaneAccess.canAddSource(currentCount: 4, hasProAccess: false))
    }

    func testProPlanDoesNotImposeASourceLimit() {
        XCTAssertNil(StagePaneAccess.sourceLimit(hasProAccess: true))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 4, hasProAccess: true))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 128, hasProAccess: true))
    }

    func testResolvedSourceLimitPolicyMatchesCaptureBoundary() {
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 3, sourceLimit: 4))
        XCTAssertFalse(StagePaneAccess.canAddSource(currentCount: 4, sourceLimit: 4))
        XCTAssertFalse(StagePaneAccess.canAddSource(currentCount: 8, sourceLimit: 4))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 128, sourceLimit: nil))
    }

    func testFifthSourceIsTheUpgradeBoundary() {
        XCTAssertFalse(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 3,
                hasProAccess: false
            )
        )
        XCTAssertTrue(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 4,
                hasProAccess: false
            )
        )
        XCTAssertFalse(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 4,
                hasProAccess: true
            )
        )
        XCTAssertTrue(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 8,
                hasProAccess: false
            )
        )
    }

    func testFreeAlwaysShowsWatermarkEvenWithLegacyHiddenPreference() {
        XCTAssertTrue(
            StagePaneAccess.showsWatermark(
                preference: false,
                hasProAccess: false
            )
        )
        XCTAssertTrue(
            StagePaneAccess.showsWatermark(
                preference: true,
                hasProAccess: false
            )
        )
    }

    func testProRespectsWatermarkPreference() {
        XCTAssertFalse(
            StagePaneAccess.showsWatermark(
                preference: false,
                hasProAccess: true
            )
        )
        XCTAssertTrue(
            StagePaneAccess.showsWatermark(
                preference: true,
                hasProAccess: true
            )
        )
    }
}
