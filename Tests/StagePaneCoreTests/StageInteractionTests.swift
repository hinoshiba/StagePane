import XCTest
@testable import StagePaneCore

final class StageInteractionTests: XCTestCase {
    func testModesAreArrangeAndAnnotateOnly() throws {
        XCTAssertEqual(StageInteractionMode.allCases, [.arrange, .annotate])

        for mode in StageInteractionMode.allCases {
            let data = try JSONEncoder().encode(mode)
            XCTAssertEqual(try JSONDecoder().decode(StageInteractionMode.self, from: data), mode)
        }
    }

    func testOnlyDrawModeSuppressesTheAudiencePointer() {
        XCTAssertFalse(StageInteractionMode.arrange.suppressesAudiencePointer)
        XCTAssertTrue(StageInteractionMode.annotate.suppressesAudiencePointer)

        for preferredStyle in PointerStyle.allCases {
            XCTAssertEqual(
                StageInteractionMode.arrange.audiencePointerStyle(
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
