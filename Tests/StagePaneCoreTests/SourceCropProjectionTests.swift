import CoreGraphics
import XCTest
@testable import StagePaneCore

final class SourceCropProjectionTests: XCTestCase {
    func testCenteredCropFillsMatchingDestinationAspect() throws {
        let crop = NormalizedSourceRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let frame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            sourceSize: CGSize(width: 1_600, height: 900),
            sourceCrop: crop,
            destinationSize: CGSize(width: 800, height: 450)
        ))

        assertRect(frame, x: -400, y: -225, width: 1_600, height: 900)
    }

    func testCropIsAspectFitAndSelectionMatchesFullPreview() throws {
        let crop = NormalizedSourceRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let selection = try XCTUnwrap(SourceCropProjection.selectionFrame(
            sourceSize: CGSize(width: 1_600, height: 900),
            sourceCrop: crop,
            destinationSize: CGSize(width: 1_000, height: 1_000)
        ))

        assertRect(
            selection,
            x: 250,
            y: 359.375,
            width: 500,
            height: 281.25
        )
    }

    func testContentCropIsConvertedThroughPaddedSurfaceGeometry() throws {
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 960, height: 540),
            contentRect: CGRect(x: 120, y: 45, width: 720, height: 450)
        ))
        let crop = NormalizedSourceRect(x: 0.25, y: 0.2, width: 0.5, height: 0.6)
        let surfaceCrop = try XCTUnwrap(SourceCropProjection.surfaceCropRect(
            presentation: presentation,
            sourceCrop: crop
        ))

        assertRect(
            surfaceCrop,
            x: 0.3125,
            y: 0.25,
            width: 0.375,
            height: 0.5
        )
        let frame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: presentation,
            sourceCrop: crop,
            destinationSize: CGSize(width: 360, height: 270)
        ))
        assertRect(frame, x: -300, y: -135, width: 960, height: 540)
    }

    func testNarrowCropMasksExcludedPixelsInWideDestinationMargins() throws {
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 1_600, height: 900),
            contentRect: CGRect(x: 0, y: 0, width: 1_600, height: 900)
        ))
        let crop = NormalizedSourceRect(x: 0.25, y: 0, width: 0.5, height: 1)
        let sourceFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: presentation,
            sourceCrop: crop,
            destinationSize: CGSize(width: 1_600, height: 900)
        ))
        let visibleFrame = try projectedVisibleFrame(
            presentation: presentation,
            sourceCrop: crop,
            destinationSize: CGSize(width: 1_600, height: 900)
        )

        assertRect(sourceFrame, x: 0, y: 0, width: 1_600, height: 900)
        assertRect(visibleFrame, x: 400, y: 0, width: 800, height: 900)
        XCTAssertLessThan(sourceFrame.minX, visibleFrame.minX)
        XCTAssertGreaterThan(sourceFrame.maxX, visibleFrame.maxX)
    }

    func testShortCropMasksExcludedPixelsInTallDestinationMargins() throws {
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 1_600, height: 900),
            contentRect: CGRect(x: 0, y: 0, width: 1_600, height: 900)
        ))
        let crop = NormalizedSourceRect(x: 0, y: 0.25, width: 1, height: 0.5)
        let sourceFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: presentation,
            sourceCrop: crop,
            destinationSize: CGSize(width: 1_600, height: 900)
        ))
        let visibleFrame = try projectedVisibleFrame(
            presentation: presentation,
            sourceCrop: crop,
            destinationSize: CGSize(width: 1_600, height: 900)
        )

        assertRect(sourceFrame, x: 0, y: 0, width: 1_600, height: 900)
        assertRect(visibleFrame, x: 0, y: 225, width: 1_600, height: 450)
        XCTAssertLessThan(sourceFrame.minY, visibleFrame.minY)
        XCTAssertGreaterThan(sourceFrame.maxY, visibleFrame.maxY)
    }

    func testVisibleMaskHandlesPaddedSurfaceAndAspectMismatch() throws {
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 960, height: 540),
            contentRect: CGRect(x: 120, y: 45, width: 720, height: 450)
        ))
        let crop = NormalizedSourceRect(x: 0.25, y: 0.2, width: 0.5, height: 0.6)
        let destinationSize = CGSize(width: 800, height: 450)
        let sourceFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: presentation,
            sourceCrop: crop,
            destinationSize: destinationSize
        ))
        let visibleFrame = try projectedVisibleFrame(
            presentation: presentation,
            sourceCrop: crop,
            destinationSize: destinationSize
        )

        assertRect(sourceFrame, x: -400, y: -225, width: 1_600, height: 900)
        assertRect(visibleFrame, x: 100, y: 0, width: 600, height: 450)
    }

    func testMatchingCropAndDestinationAspectUsesEntireDestination() throws {
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 1_600, height: 900),
            contentRect: CGRect(x: 0, y: 0, width: 1_600, height: 900)
        ))
        let visibleFrame = try projectedVisibleFrame(
            presentation: presentation,
            sourceCrop: NormalizedSourceRect(
                x: 0.25,
                y: 0.25,
                width: 0.5,
                height: 0.5
            ),
            destinationSize: CGSize(width: 800, height: 450)
        )

        assertRect(visibleFrame, x: 0, y: 0, width: 800, height: 450)
    }

    func testPresentationGeometryClipsContentToTheSurface() throws {
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 100, height: 80),
            contentRect: CGRect(x: -10, y: 20, width: 80, height: 100)
        ))

        assertRect(presentation.contentRect, x: 0, y: 20, width: 70, height: 60)
        XCTAssertNil(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 100, height: 80),
            contentRect: CGRect(x: 120, y: 0, width: 10, height: 10)
        ))
    }

    func testSurfaceCropClampsFloatingPointDriftAtRightAndBottomEdges() throws {
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 1_147, height: 911),
            contentRect: CGRect(x: 894, y: 411, width: 253, height: 500)
        ))
        let crop = NormalizedSourceRect(
            x: 0.765_984_968_739_211_4,
            y: 0.7,
            width: 0.234_015_031_260_788_6,
            height: 0.3
        )
        let surfaceCrop = try XCTUnwrap(SourceCropProjection.surfaceCropRect(
            presentation: presentation,
            sourceCrop: crop
        ))

        XCTAssertEqual(surfaceCrop.maxX, 1)
        XCTAssertEqual(surfaceCrop.maxY, 1)
        XCTAssertGreaterThan(surfaceCrop.width, 0)
        XCTAssertGreaterThan(surfaceCrop.height, 0)
    }

    func testProjectionRejectsOverflowingOutputGeometry() {
        XCTAssertNil(SourceCropProjection.sourceFrame(
            sourceSize: CGSize(width: 100, height: 100),
            sourceCrop: NormalizedSourceRect(x: 0, y: 0, width: 0.01, height: 0.01),
            destinationSize: CGSize(
                width: CGFloat.greatestFiniteMagnitude / 2,
                height: CGFloat.greatestFiniteMagnitude / 2
            )
        ))
    }

    func testInvalidSizesAreRejected() {
        XCTAssertNil(SourceCropProjection.sourceFrame(
            sourceSize: .zero,
            sourceCrop: .fullSource,
            destinationSize: CGSize(width: 100, height: 100)
        ))
        XCTAssertNil(SourceCropProjection.selectionFrame(
            sourceSize: CGSize(width: 100, height: 100),
            sourceCrop: .fullSource,
            destinationSize: CGSize(width: CGFloat.infinity, height: 100)
        ))
        XCTAssertNil(SourceCropProjection.visibleSurfaceFrame(
            surfaceCrop: .zero,
            surfaceSize: CGSize(width: 100, height: 100)
        ))
        XCTAssertNil(SourceCropProjection.visibleSurfaceFrame(
            surfaceCrop: CGRect(x: 0, y: 0, width: 1, height: 1),
            surfaceSize: .zero
        ))
    }

    private func projectedVisibleFrame(
        presentation: SourcePresentationGeometry,
        sourceCrop: NormalizedSourceRect,
        destinationSize: CGSize
    ) throws -> CGRect {
        let sourceFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: presentation,
            sourceCrop: sourceCrop,
            destinationSize: destinationSize
        ))
        let surfaceCrop = try XCTUnwrap(SourceCropProjection.surfaceCropRect(
            presentation: presentation,
            sourceCrop: sourceCrop
        ))
        let localMask = try XCTUnwrap(SourceCropProjection.visibleSurfaceFrame(
            surfaceCrop: surfaceCrop,
            surfaceSize: sourceFrame.size
        ))
        return localMask.offsetBy(dx: sourceFrame.minX, dy: sourceFrame.minY)
    }

    private func assertRect(
        _ rect: CGRect,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(rect.minX, x, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(rect.minY, y, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(rect.width, width, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(rect.height, height, accuracy: 0.000_001, file: file, line: line)
    }
}
