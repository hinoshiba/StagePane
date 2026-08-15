import XCTest
@testable import StagePaneCore

final class StagePresetTests: XCTestCase {
    func testPresetAspectRatios() {
        XCTAssertEqual(StagePreset.widescreen.aspectRatio, 16.0 / 9.0, accuracy: 0.0001)
        XCTAssertEqual(StagePreset.standard.aspectRatio, 4.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(StagePreset.portrait.aspectRatio, 9.0 / 16.0, accuracy: 0.0001)
        XCTAssertEqual(StagePreset.square.aspectRatio, 1.0, accuracy: 0.0001)
    }

    func testSuggestedSizesPreserveAspectRatio() {
        for preset in StagePreset.allCases {
            let size = preset.suggestedPointSize
            XCTAssertEqual(size.width / size.height, preset.aspectRatio, accuracy: 0.0001)
            XCTAssertLessThanOrEqual(size.width, 960)
            XCTAssertLessThanOrEqual(size.height, 960)
        }
    }

    func testMessageNormalization() {
        XCTAssertEqual(StageMessage.normalized("  Back in a moment  ", fallback: "Fallback"), "Back in a moment")
        XCTAssertEqual(StageMessage.normalized("   ", fallback: "Fallback"), "Fallback")
        XCTAssertEqual(StageMessage.normalized(String(repeating: "x", count: 120), fallback: "Fallback").count, 80)
    }
}
