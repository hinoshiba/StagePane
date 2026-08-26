import XCTest
@testable import StagePaneCore

final class StagePaneAccessTests: XCTestCase {
    func testFreePlanAllowsTwoSources() {
        XCTAssertEqual(StagePaneAccess.sourceLimit(hasProAccess: false), 2)
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 0, hasProAccess: false))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 1, hasProAccess: false))
        XCTAssertFalse(StagePaneAccess.canAddSource(currentCount: 2, hasProAccess: false))
    }

    func testProPlanDoesNotImposeASourceLimit() {
        XCTAssertNil(StagePaneAccess.sourceLimit(hasProAccess: true))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 2, hasProAccess: true))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 4, hasProAccess: true))
        XCTAssertTrue(StagePaneAccess.canAddSource(currentCount: 10_000, hasProAccess: true))
    }

    func testThirdSourceIsTheUpgradeBoundary() {
        XCTAssertFalse(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 1,
                hasProAccess: false
            )
        )
        XCTAssertTrue(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 2,
                hasProAccess: false
            )
        )
        XCTAssertFalse(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 2,
                hasProAccess: true
            )
        )
        XCTAssertFalse(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 2,
                hasProAccess: true
            )
        )
        XCTAssertTrue(
            StagePaneAccess.requiresProForNextSource(
                currentCount: 10_000,
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
