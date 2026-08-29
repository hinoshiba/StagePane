import XCTest
@testable import StagePaneCore

final class StageInteractionTests: XCTestCase {
    func testModesAreArrangeCropAndAnnotate() throws {
        XCTAssertEqual(StageInteractionMode.allCases, [.arrange, .crop, .annotate])

        for mode in StageInteractionMode.allCases {
            let data = try JSONEncoder().encode(mode)
            XCTAssertEqual(try JSONDecoder().decode(StageInteractionMode.self, from: data), mode)
        }
    }

    func testOnlyDrawModeSuppressesTheAudiencePointer() {
        XCTAssertFalse(StageInteractionMode.arrange.suppressesAudiencePointer)
        XCTAssertFalse(StageInteractionMode.crop.suppressesAudiencePointer)
        XCTAssertTrue(StageInteractionMode.annotate.suppressesAudiencePointer)

        for preferredStyle in PointerStyle.allCases {
            XCTAssertEqual(
                StageInteractionMode.arrange.audiencePointerStyle(
                    preferred: preferredStyle
                ),
                preferredStyle
            )
            XCTAssertEqual(
                StageInteractionMode.crop.audiencePointerStyle(
                    preferred: preferredStyle
                ),
                preferredStyle
            )
            XCTAssertEqual(
                StageInteractionMode.annotate.audiencePointerStyle(
                    preferred: preferredStyle
                ),
                .hidden
            )
        }
    }
}
