import CoreGraphics
import XCTest
@testable import StagePaneCore

final class StageContentGeometryTests: XCTestCase {
    func testSquareSourceFrameCanMoveToBothVisibleCanvasEdges() throws {
        let frame = try XCTUnwrap(StageContentGeometry.frame(
            sourceSize: CGSize(width: 900, height: 900),
            sourceCrop: .fullSource,
            layoutFrame: .fullCanvas,
            canvasSize: CGSize(width: 1_600, height: 900)
        ))

        assertRect(frame, x: 0.21875, y: 0, width: 0.5625, height: 1)
        assertRect(
            frame.moved(byX: -1, y: 0),
            x: 0, y: 0, width: 0.5625, height: 1
        )
        assertRect(
            frame.moved(byX: 1, y: 0),
            x: 0.4375, y: 0, width: 0.5625, height: 1
        )
    }

    func testVisibleFrameRemovesVerticalMarginsInPortraitCanvas() throws {
        let frame = try XCTUnwrap(StageContentGeometry.frame(
            sourceSize: CGSize(width: 1_600, height: 900),
            sourceCrop: .fullSource,
            layoutFrame: NormalizedStageRect(x: 0.1, y: 0.2, width: 0.8, height: 0.6),
            canvasSize: CGSize(width: 900, height: 1_600)
        ))

        assertRect(frame, x: 0.1, y: 0.3734375, width: 0.8, height: 0.253125)
    }

    func testTightFramePreservesDisplayedSourceTransformAndIsIdempotent() throws {
        let canvasSize = CGSize(width: 1_600, height: 900)
        let sourceSize = CGSize(width: 1_280, height: 720)
        let layout = NormalizedStageRect(x: 0.1, y: 0.15, width: 0.7, height: 0.6)
        let crops: [NormalizedSourceRect] = [
            .fullSource,
            NormalizedSourceRect(x: 0.1, y: 0.25, width: 0.3, height: 0.7),
            NormalizedSourceRect(x: 0.2, y: 0.15, width: 0.75, height: 0.2)
        ]

        for crop in crops {
            let tight = try XCTUnwrap(StageContentGeometry.frame(
                sourceSize: sourceSize,
                sourceCrop: crop,
                layoutFrame: layout,
                canvasSize: canvasSize
            ))
            let repeated = try XCTUnwrap(StageContentGeometry.frame(
                sourceSize: sourceSize,
                sourceCrop: crop,
                layoutFrame: tight,
                canvasSize: canvasSize
            ))
            assertRect(
                repeated,
                x: tight.x, y: tight.y, width: tight.width, height: tight.height
            )

            let originalTransform = try sourceFrameInCanvas(
                sourceSize: sourceSize,
                crop: crop,
                frame: layout,
                canvasSize: canvasSize
            )
            let tightenedTransform = try sourceFrameInCanvas(
                sourceSize: sourceSize,
                crop: crop,
                frame: tight,
                canvasSize: canvasSize
            )
            XCTAssertEqual(originalTransform.minX, tightenedTransform.minX, accuracy: 0.000_001)
            XCTAssertEqual(originalTransform.minY, tightenedTransform.minY, accuracy: 0.000_001)
            XCTAssertEqual(originalTransform.width, tightenedTransform.width, accuracy: 0.000_001)
            XCTAssertEqual(originalTransform.height, tightenedTransform.height, accuracy: 0.000_001)
        }
    }

    func testResizeProjectsPhysicalTranslationAndPreservesTopLeft() throws {
        let frame = NormalizedStageRect(x: 0.1, y: 0.15, width: 0.4, height: 0.4)
        // The content is 640 × 360 points. A half-diagonal drag scales it 1.5×.
        let resized = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: CGSize(width: 320, height: 180),
            canvasSize: CGSize(width: 1_600, height: 900)
        ))

        assertRect(resized, x: 0.1, y: 0.15, width: 0.6, height: 0.6)
    }

    func testPerpendicularDragDoesNotResizeContent() throws {
        let frame = NormalizedStageRect(x: 0.1, y: 0.15, width: 0.4, height: 0.4)
        let resized = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: CGSize(width: -180, height: 320),
            canvasSize: CGSize(width: 1_600, height: 900)
        ))

        assertRect(resized, x: frame.x, y: frame.y, width: frame.width, height: frame.height)
    }

    func testResizeAtCanvasEdgeKeepsBothDimensionsProportional() throws {
        let frame = NormalizedStageRect(x: 0.6, y: 0.1, width: 0.3, height: 0.4)
        let resized = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: CGSize(width: 1_000, height: 1_000),
            canvasSize: CGSize(width: 1_600, height: 900)
        ))

        assertRect(resized, x: 0.6, y: 0.1, width: 0.4, height: 0.4 * 4 / 3)
        XCTAssertEqual(resized.width / frame.width, resized.height / frame.height, accuracy: 0.000_001)
    }

    func testResizeAtBottomEdgeKeepsTopLeftAndAspectRatio() throws {
        let frame = NormalizedStageRect(x: 0.1, y: 0.6, width: 0.3, height: 0.2)
        let resized = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: CGSize(width: 1_000, height: 1_000),
            canvasSize: CGSize(width: 1_600, height: 900)
        ))

        assertRect(resized, x: 0.1, y: 0.6, width: 0.6, height: 0.4)
    }

    func testThinCropUsesAspectFitMinimumAndNeverGrowsOnZeroDrag() throws {
        let frame = NormalizedStageRect(x: 0.4, y: 0.2, width: 0.02, height: 0.5)
        let canvasSize = CGSize(width: 1_600, height: 900)
        let unchanged = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: .zero,
            canvasSize: canvasSize
        ))
        let shrunk = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: CGSize(width: -1_000, height: -1_000),
            canvasSize: canvasSize
        ))

        XCTAssertEqual(unchanged, frame)
        assertRect(shrunk, x: 0.4, y: 0.2, width: 0.004, height: 0.1)
    }

    func testAlreadySmallContentDoesNotGrowAtStartOrWhenShrinking() throws {
        let frame = NormalizedStageRect(x: 0.2, y: 0.3, width: 0.02, height: 0.05)
        for translation in [CGSize.zero, CGSize(width: -50, height: -50)] {
            let resized = try XCTUnwrap(StageContentGeometry.resizedFrame(
                frame,
                translation: translation,
                canvasSize: CGSize(width: 1_600, height: 900)
            ))
            XCTAssertEqual(resized, frame)
        }
    }

    func testResizeMinimumUsesOneCommonScale() throws {
        let frame = NormalizedStageRect(x: 0.1, y: 0.15, width: 0.4, height: 0.2)
        let resized = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: CGSize(width: -1_000, height: -1_000),
            canvasSize: CGSize(width: 1_600, height: 900)
        ))

        assertRect(resized, x: 0.1, y: 0.15, width: 0.1, height: 0.05)
    }

    func testZeroMinimumStillProducesPositiveProportionalDimensions() throws {
        let frame = NormalizedStageRect(x: 0.1, y: 0.15, width: 0.4, height: 0.2)
        let resized = try XCTUnwrap(StageContentGeometry.resizedFrame(
            frame,
            translation: CGSize(width: -1_000, height: -1_000),
            canvasSize: CGSize(width: 1_600, height: 900),
            minimumDimension: 0
        ))

        XCTAssertGreaterThan(resized.width, 0)
        XCTAssertGreaterThan(resized.height, 0)
        XCTAssertEqual(resized.width / resized.height, 2, accuracy: 0.000_001)
    }

    func testInvalidCanvasSourceAndResizeInputsAreRejected() {
        for canvasSize in [
            CGSize.zero,
            CGSize(width: -10, height: 100),
            CGSize(width: CGFloat.infinity, height: 100),
            CGSize(width: 100, height: CGFloat.nan)
        ] {
            XCTAssertNil(StageContentGeometry.frame(
                sourceSize: CGSize(width: 100, height: 100),
                sourceCrop: .fullSource,
                layoutFrame: .fullCanvas,
                canvasSize: canvasSize
            ))
            XCTAssertNil(StageContentGeometry.resizedFrame(
                .fullCanvas,
                translation: .zero,
                canvasSize: canvasSize
            ))
        }
        XCTAssertNil(StageContentGeometry.frame(
            sourceSize: .zero,
            sourceCrop: .fullSource,
            layoutFrame: .fullCanvas,
            canvasSize: CGSize(width: 100, height: 100)
        ))
        XCTAssertNil(StageContentGeometry.resizedFrame(
            .fullCanvas,
            translation: CGSize(width: CGFloat.nan, height: 0),
            canvasSize: CGSize(width: 100, height: 100)
        ))
        XCTAssertNil(StageContentGeometry.resizedFrame(
            .fullCanvas,
            translation: .zero,
            canvasSize: CGSize(width: 100, height: 100),
            minimumDimension: .infinity
        ))
    }

    private func sourceFrameInCanvas(
        sourceSize: CGSize,
        crop: NormalizedSourceRect,
        frame: NormalizedStageRect,
        canvasSize: CGSize
    ) throws -> CGRect {
        let sourceFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            sourceSize: sourceSize,
            sourceCrop: crop,
            destinationSize: CGSize(
                width: canvasSize.width * CGFloat(frame.width),
                height: canvasSize.height * CGFloat(frame.height)
            )
        ))
        return sourceFrame.offsetBy(
            dx: canvasSize.width * CGFloat(frame.x),
            dy: canvasSize.height * CGFloat(frame.y)
        )
    }

    private func assertRect(
        _ rect: NormalizedStageRect,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(rect.x, x, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(rect.y, y, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(rect.width, width, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(rect.height, height, accuracy: 0.000_001, file: file, line: line)
    }
}
