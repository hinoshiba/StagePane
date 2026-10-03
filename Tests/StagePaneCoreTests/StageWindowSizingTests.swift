import CoreGraphics
import Foundation
import XCTest
@testable import StagePaneCore

final class StageWindowSizingTests: XCTestCase {
    func testWideCanvasAddsOnlyVerticalMatteOnSixteenByTenScreen() throws {
        let frame = try XCTUnwrap(StageWindowSizing.fittedCanvasRect(
            in: CGRect(x: 0, y: 0, width: 1440, height: 900),
            aspectRatio: StagePreset.widescreen.aspectRatio
        ))

        XCTAssertEqual(frame, CGRect(x: 0, y: 45, width: 1440, height: 810))
    }

    func testPortraitCanvasFitsEntireHeightWithoutStretching() throws {
        let frame = try XCTUnwrap(StageWindowSizing.fittedCanvasRect(
            in: CGRect(x: 0, y: 0, width: 1440, height: 900),
            aspectRatio: StagePreset.portrait.aspectRatio
        ))

        XCTAssertEqual(frame, CGRect(x: 466.875, y: 0, width: 506.25, height: 900))
    }

    func testSquareCanvasCentersVerticallyOnPortraitScreen() throws {
        let frame = try XCTUnwrap(StageWindowSizing.fittedCanvasRect(
            in: CGRect(x: 0, y: 0, width: 900, height: 1440),
            aspectRatio: StagePreset.square.aspectRatio
        ))

        XCTAssertEqual(frame, CGRect(x: 0, y: 270, width: 900, height: 900))
    }

    func testCanvasAlreadyMatchingPresetHasNoMatte() throws {
        let bounds = CGRect(x: 10, y: 20, width: 960, height: 540)
        let frame = try XCTUnwrap(StageWindowSizing.fittedCanvasRect(
            in: bounds,
            aspectRatio: StagePreset.widescreen.aspectRatio
        ))

        XCTAssertEqual(frame, bounds)
    }

    func testCanvasFitHonorsNonzeroOriginAndAllowsSmallerThanWindowMinimum() throws {
        let frame = try XCTUnwrap(StageWindowSizing.fittedCanvasRect(
            in: CGRect(x: 100, y: -50, width: 12, height: 12),
            aspectRatio: StagePreset.widescreen.aspectRatio
        ))

        XCTAssertEqual(frame, CGRect(x: 100, y: -47.375, width: 12, height: 6.75))
    }

    func testEveryPresetFitsAndCentersWithinDifferentScreenShapes() throws {
        for size in [
            CGSize(width: 1440, height: 900),
            CGSize(width: 900, height: 1440),
            CGSize(width: 960, height: 960),
            CGSize(width: 320, height: 200)
        ] {
            let bounds = CGRect(origin: CGPoint(x: -120, y: 80), size: size)
            for preset in StagePreset.allCases {
                let frame = try XCTUnwrap(StageWindowSizing.fittedCanvasRect(
                    in: bounds,
                    aspectRatio: preset.aspectRatio
                ))

                XCTAssertEqual(frame.width / frame.height, preset.aspectRatio, accuracy: 0.000_001)
                XCTAssertEqual(frame.midX, bounds.midX, accuracy: 0.000_001)
                XCTAssertEqual(frame.midY, bounds.midY, accuracy: 0.000_001)
                XCTAssertGreaterThanOrEqual(frame.minX, bounds.minX)
                XCTAssertGreaterThanOrEqual(frame.minY, bounds.minY)
                XCTAssertLessThanOrEqual(frame.maxX, bounds.maxX)
                XCTAssertLessThanOrEqual(frame.maxY, bounds.maxY)
                XCTAssertTrue(frame.width == bounds.width || frame.height == bounds.height)
            }
        }
    }

    func testCanvasFitRejectsInvalidHostGeometryAndAspectRatios() {
        for bounds in [
            CGRect.zero,
            CGRect(x: 0, y: 0, width: -1, height: 540),
            CGRect(x: 0, y: 0, width: 960, height: CGFloat.infinity),
            CGRect(x: CGFloat.nan, y: 0, width: 960, height: 540),
            CGRect(x: CGFloat.greatestFiniteMagnitude, y: 0,
                   width: CGFloat.greatestFiniteMagnitude, height: 540)
        ] {
            XCTAssertNil(StageWindowSizing.fittedCanvasRect(
                in: bounds,
                aspectRatio: StagePreset.widescreen.aspectRatio
            ))
        }
        for aspectRatio in [0.0, -1, .nan, .infinity] {
            XCTAssertNil(StageWindowSizing.fittedCanvasRect(
                in: CGRect(x: 0, y: 0, width: 960, height: 540),
                aspectRatio: aspectRatio
            ))
        }
    }

    func testMinimumContentSizeKeepsEveryPresetShape() {
        let expected: [StagePreset: CGSize] = [
            .widescreen: CGSize(width: 480, height: 270),
            .standard: CGSize(width: 480, height: 360),
            .portrait: CGSize(width: 270, height: 480),
            .square: CGSize(width: 480, height: 480)
        ]

        for preset in StagePreset.allCases {
            let minimum = StageWindowSizing.minimumContentSize(for: preset)
            XCTAssertEqual(minimum, expected[preset])
            XCTAssertEqual(minimum.width / minimum.height, preset.aspectRatio, accuracy: 0.000_001)
        }
    }

    func testSuggestedSizesKeepExistingInitialSizeAndHonorMinimum() {
        for preset in StagePreset.allCases {
            let suggested = StageWindowSizing.suggestedContentSize(for: preset)
            let minimum = StageWindowSizing.minimumContentSize(for: preset)

            XCTAssertEqual(suggested.width, preset.suggestedPointSize.width, accuracy: 0.000_001)
            XCTAssertEqual(suggested.height, preset.suggestedPointSize.height, accuracy: 0.000_001)
            XCTAssertGreaterThanOrEqual(suggested.width, minimum.width)
            XCTAssertGreaterThanOrEqual(suggested.height, minimum.height)
            XCTAssertEqual(suggested.width / suggested.height, preset.aspectRatio, accuracy: 0.000_001)
        }
    }

    func testSmallStageReachesTargetWhenScreenHasRoom() {
        XCTAssertEqual(
            StageWindowSizing.enlargedContentSize(
                current: CGSize(width: 480, height: 270),
                target: CGSize(width: 960, height: 540),
                available: CGSize(width: 1440, height: 900),
                aspectRatio: StagePreset.widescreen.aspectRatio
            ),
            CGSize(width: 960, height: 540)
        )
    }

    func testUnavailableTargetUsesLargestProportionalSizeThatFitsScreen() throws {
        let result = try XCTUnwrap(StageWindowSizing.enlargedContentSize(
            current: CGSize(width: 480, height: 270),
            target: CGSize(width: 1920, height: 1080),
            available: CGSize(width: 1280, height: 700),
            aspectRatio: StagePreset.widescreen.aspectRatio
        ))

        XCTAssertEqual(result.width, 700 * 16.0 / 9.0, accuracy: 0.000_001)
        XCTAssertEqual(result.height, 700)
    }

    func testPortraitEnlargesOnShortScreenWithoutRequiringLandscapeMinimumWidth() {
        XCTAssertEqual(
            StageWindowSizing.enlargedContentSize(
                current: CGSize(width: 270, height: 480),
                target: CGSize(width: 540, height: 960),
                available: CGSize(width: 1280, height: 700),
                aspectRatio: StagePreset.portrait.aspectRatio
            ),
            CGSize(width: 393.75, height: 700)
        )
    }

    func testAlreadyAtOrAboveTargetDoesNotShrink() {
        for current in [CGSize(width: 960, height: 540), CGSize(width: 1280, height: 720)] {
            XCTAssertNil(StageWindowSizing.enlargedContentSize(
                current: current,
                target: CGSize(width: 960, height: 540),
                available: CGSize(width: 1440, height: 900),
                aspectRatio: StagePreset.widescreen.aspectRatio
            ))
        }
    }

    func testWindowAlreadyLargerThanScreenIsLeftAlone() {
        for available in [CGSize(width: 900, height: 900), CGSize(width: 1440, height: 500)] {
            XCTAssertNil(StageWindowSizing.enlargedContentSize(
                current: CGSize(width: 960, height: 540),
                target: CGSize(width: 1920, height: 1080),
                available: available,
                aspectRatio: StagePreset.widescreen.aspectRatio
            ))
        }
    }

    func testTinyScreenOrNoExpansionRoomDoesNotShrink() {
        for available in [CGSize(width: 100, height: 60), CGSize(width: 480, height: 270)] {
            XCTAssertNil(StageWindowSizing.enlargedContentSize(
                current: CGSize(width: 480, height: 270),
                target: CGSize(width: 1920, height: 1080),
                available: available,
                aspectRatio: StagePreset.widescreen.aspectRatio
            ))
        }
    }

    func testDifferentCurrentShapeCannotShrinkEitherDimension() {
        XCTAssertNil(StageWindowSizing.enlargedContentSize(
            current: CGSize(width: 480, height: 480),
            target: CGSize(width: 960, height: 540),
            available: CGSize(width: 800, height: 600),
            aspectRatio: StagePreset.widescreen.aspectRatio
        ))
    }

    func testTargetRectangleIsFittedToRequestedShape() {
        XCTAssertEqual(
            StageWindowSizing.enlargedContentSize(
                current: CGSize(width: 480, height: 360),
                target: CGSize(width: 960, height: 540),
                available: CGSize(width: 1440, height: 900),
                aspectRatio: StagePreset.standard.aspectRatio
            ),
            CGSize(width: 720, height: 540)
        )
    }

    func testAllPresetEnlargementsHonorShapeTargetAndScreenBounds() throws {
        for preset in StagePreset.allCases {
            let current = StageWindowSizing.minimumContentSize(for: preset)
            let target = CGSize(width: preset.pixelWidth, height: preset.pixelHeight)
            let available = CGSize(width: 1000, height: 800)
            let result = try XCTUnwrap(StageWindowSizing.enlargedContentSize(
                current: current,
                target: target,
                available: available,
                aspectRatio: preset.aspectRatio
            ))

            XCTAssertEqual(result.width / result.height, preset.aspectRatio, accuracy: 0.000_001)
            XCTAssertGreaterThanOrEqual(result.width, current.width)
            XCTAssertGreaterThanOrEqual(result.height, current.height)
            XCTAssertLessThanOrEqual(result.width, target.width)
            XCTAssertLessThanOrEqual(result.height, target.height)
            XCTAssertLessThanOrEqual(result.width, available.width)
            XCTAssertLessThanOrEqual(result.height, available.height)
        }
    }

    func testInvalidDimensionsAndAspectRatiosAreRejected() {
        let valid = CGSize(width: 480, height: 270)
        let invalidSizes = [
            CGSize.zero,
            CGSize(width: -1, height: 270),
            CGSize(width: 480, height: 0),
            CGSize(width: CGFloat.nan, height: 270),
            CGSize(width: 480, height: CGFloat.infinity)
        ]
        for invalid in invalidSizes {
            XCTAssertNil(StageWindowSizing.enlargedContentSize(
                current: invalid, target: valid, available: valid, aspectRatio: 16.0 / 9.0
            ))
            XCTAssertNil(StageWindowSizing.enlargedContentSize(
                current: valid, target: invalid, available: valid, aspectRatio: 16.0 / 9.0
            ))
            XCTAssertNil(StageWindowSizing.enlargedContentSize(
                current: valid, target: valid, available: invalid, aspectRatio: 16.0 / 9.0
            ))
        }
        for aspectRatio in [0.0, -1, .nan, .infinity] {
            XCTAssertNil(StageWindowSizing.enlargedContentSize(
                current: valid, target: valid, available: valid, aspectRatio: aspectRatio
            ))
        }
    }
}
