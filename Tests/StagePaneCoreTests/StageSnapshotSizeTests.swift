import XCTest
@testable import StagePaneCore

final class StageSnapshotSizeTests: XCTestCase {
    func testEveryStagePresetProducesItsCanonicalPixelSize() {
        for preset in StagePreset.allCases {
            let size = StageSnapshotSize(preset: preset)
            XCTAssertEqual(size.width, preset.pixelWidth)
            XCTAssertEqual(size.height, preset.pixelHeight)
        }
    }

    func testRejectsEmptyNegativeAndOversizedDimensions() {
        XCTAssertNil(StageSnapshotSize(width: 0, height: 1_080))
        XCTAssertNil(StageSnapshotSize(width: 1_920, height: 0))
        XCTAssertNil(StageSnapshotSize(width: -1, height: 1_080))
        XCTAssertNil(StageSnapshotSize(width: 7_681, height: 1))
        XCTAssertNil(StageSnapshotSize(width: 1, height: 7_681))
    }

    func testAdmitsEightKButRejectsExcessivePixelArea() throws {
        let landscape = try XCTUnwrap(
            StageSnapshotSize(width: 7_680, height: 4_320)
        )
        XCTAssertEqual(landscape.width, 7_680)
        XCTAssertEqual(landscape.height, 4_320)

        let portrait = try XCTUnwrap(
            StageSnapshotSize(width: 4_320, height: 7_680)
        )
        XCTAssertEqual(portrait.width, 4_320)
        XCTAssertEqual(portrait.height, 7_680)

        XCTAssertNil(StageSnapshotSize(width: 7_680, height: 7_680))
        XCTAssertNil(StageSnapshotSize(width: Int.max, height: 2))
    }
}
