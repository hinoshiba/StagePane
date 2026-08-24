import XCTest
@testable import StagePaneCore

final class PointerStyleTests: XCTestCase {
    func testRawValuesRemainStable() {
        XCTAssertEqual(PointerStyle.system.rawValue, "system")
        XCTAssertEqual(PointerStyle.redDot.rawValue, "redDot")
        XCTAssertEqual(PointerStyle.hidden.rawValue, "hidden")
        XCTAssertEqual(PointerStyle.allCases, [.system, .redDot, .hidden])
    }

    func testStoredStyleTakesPrecedenceOverLegacyPreference() {
        XCTAssertEqual(
            PointerStyle.resolvePreference(
                storedRawValue: PointerStyle.redDot.rawValue,
                legacyShowsCursor: false
            ),
            .redDot
        )
    }

    func testLegacyVisibilityMigratesToEquivalentStyle() {
        XCTAssertEqual(
            PointerStyle.resolvePreference(storedRawValue: nil, legacyShowsCursor: true),
            .system
        )
        XCTAssertEqual(
            PointerStyle.resolvePreference(storedRawValue: nil, legacyShowsCursor: false),
            .hidden
        )
    }

    func testMissingOrInvalidPreferenceUsesSystemStyle() {
        XCTAssertEqual(
            PointerStyle.resolvePreference(storedRawValue: nil, legacyShowsCursor: nil),
            .system
        )
        XCTAssertEqual(
            PointerStyle.resolvePreference(storedRawValue: "future-style", legacyShowsCursor: nil),
            .system
        )
    }

    func testOnlySystemStyleUsesCapturedCursor() {
        XCTAssertTrue(PointerStyle.system.showsSystemCursor)
        XCTAssertFalse(PointerStyle.redDot.showsSystemCursor)
        XCTAssertFalse(PointerStyle.hidden.showsSystemCursor)
    }
}
