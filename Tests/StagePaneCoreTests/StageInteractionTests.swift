import XCTest
@testable import StagePaneCore

final class StageInteractionTests: XCTestCase {
    func testModesRoundTrip() throws {
        XCTAssertEqual(StageInteractionMode.allCases, [.arrange, .crop, .annotate, .magnify])

        for mode in StageInteractionMode.allCases {
            let data = try JSONEncoder().encode(mode)
            XCTAssertEqual(try JSONDecoder().decode(StageInteractionMode.self, from: data), mode)
        }
    }

    func testDrawingAndMagnifyingSuppressTheAudiencePointerWithoutChangingPreference() {
        XCTAssertFalse(StageInteractionMode.arrange.suppressesAudiencePointer)
        XCTAssertFalse(StageInteractionMode.crop.suppressesAudiencePointer)
        XCTAssertTrue(StageInteractionMode.annotate.suppressesAudiencePointer)
        XCTAssertTrue(StageInteractionMode.magnify.suppressesAudiencePointer)

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
            XCTAssertEqual(
                StageInteractionMode.magnify.audiencePointerStyle(preferred: preferredStyle),
                .hidden
            )
        }
    }
}
