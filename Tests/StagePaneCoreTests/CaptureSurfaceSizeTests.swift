import XCTest
@testable import StagePaneCore

final class CaptureSurfaceSizeTests: XCTestCase {
    func testFrameMetadataRecoversNativeSourceGeometry() throws {
        let geometry = try XCTUnwrap(CaptureSourceGeometry(
            surfaceContentPointWidth: 720,
            surfaceContentPointHeight: 405,
            contentScale: 0.75,
            pointPixelScale: 2
        ))

        XCTAssertEqual(geometry.pointWidth, 960)
        XCTAssertEqual(geometry.pointHeight, 540)
        XCTAssertEqual(geometry.pointPixelScale, 2)
        XCTAssertEqual(
            CaptureSurfaceSize.fitted(
                source: geometry,
                maximumWidth: 1920,
                maximumHeight: 1080
            ),
            CaptureSurfaceSize(width: 1920, height: 1080)
        )
    }

    func testInvalidFrameMetadataIsRejected() {
        XCTAssertNil(CaptureSourceGeometry(
            surfaceContentPointWidth: 720,
            surfaceContentPointHeight: 405,
            contentScale: 0,
            pointPixelScale: 2
        ))
        XCTAssertNil(CaptureSourceGeometry(
            surfaceContentPointWidth: .nan,
            surfaceContentPointHeight: 405,
            contentScale: 1,
            pointPixelScale: 2
        ))
    }

    func testNativeSourceIsNotUpscaled() {
        XCTAssertEqual(
            CaptureSurfaceSize.fitted(
                sourcePointWidth: 400,
                sourcePointHeight: 300,
                pointPixelScale: 2,
                maximumWidth: 1920,
                maximumHeight: 1080
            ),
            CaptureSurfaceSize(width: 800, height: 600)
        )
    }

    func testSourceAspectFitsTilePixelBudget() {
        XCTAssertEqual(
            CaptureSurfaceSize.fitted(
                sourcePointWidth: 1920,
                sourcePointHeight: 1080,
                pointPixelScale: 1,
                maximumWidth: 902,
                maximumHeight: 1036
            ),
            CaptureSurfaceSize(width: 902, height: 508)
        )
    }

    func testPortraitSourceFitsHeightWithoutStageShapedPadding() {
        XCTAssertEqual(
            CaptureSurfaceSize.fitted(
                sourcePointWidth: 900,
                sourcePointHeight: 1600,
                pointPixelScale: 2,
                maximumWidth: 900,
                maximumHeight: 900
            ),
            CaptureSurfaceSize(width: 506, height: 900)
        )
    }

    func testInvalidSourceFallsBackToTileBudget() {
        XCTAssertEqual(
            CaptureSurfaceSize.fitted(
                sourcePointWidth: 0,
                sourcePointHeight: .nan,
                pointPixelScale: 0,
                maximumWidth: 901,
                maximumHeight: 507
            ),
            CaptureSurfaceSize(width: 900, height: 506)
        )
    }

    func testFiniteInputsWhoseProductOverflowsDoNotTrap() {
        XCTAssertEqual(
            CaptureSurfaceSize.fitted(
                sourcePointWidth: .greatestFiniteMagnitude,
                sourcePointHeight: 100,
                pointPixelScale: 2,
                maximumWidth: 1_920,
                maximumHeight: 1_080
            ),
            CaptureSurfaceSize(width: 2, height: 2)
        )
    }

    func testCropReceivesVisibleTileResolutionWithoutUpscalingPastNative() {
        let halfCrop = NormalizedSourceRect(
            x: 0.25,
            y: 0.25,
            width: 0.5,
            height: 0.5
        )

        XCTAssertEqual(
            CaptureSurfaceSize.fittedForVisibleRegion(
                sourcePointWidth: 1_920,
                sourcePointHeight: 1_080,
                pointPixelScale: 1,
                visibleRegion: halfCrop,
                maximumVisibleWidth: 960,
                maximumVisibleHeight: 540
            ),
            CaptureSurfaceSize(width: 1_920, height: 1_080)
        )
        XCTAssertEqual(
            CaptureSurfaceSize.fittedForVisibleRegion(
                sourcePointWidth: 640,
                sourcePointHeight: 360,
                pointPixelScale: 1,
                visibleRegion: halfCrop,
                maximumVisibleWidth: 960,
                maximumVisibleHeight: 540
            ),
            CaptureSurfaceSize(width: 640, height: 360)
        )
    }

    func testCropSurfaceHonorsTotalPixelCapAndEvenDimensions() {
        let tightCrop = NormalizedSourceRect(
            x: 0.45,
            y: 0.45,
            width: 0.1,
            height: 0.1
        )

        let size = CaptureSurfaceSize.fittedForVisibleRegion(
            sourcePointWidth: 4_000,
            sourcePointHeight: 4_000,
            pointPixelScale: 1,
            visibleRegion: tightCrop,
            maximumVisibleWidth: 1_920,
            maximumVisibleHeight: 1_080
        )

        XCTAssertLessThanOrEqual(
            size.width * size.height,
            CaptureSurfaceSize.defaultMaximumPixelCount
        )
        XCTAssertTrue(size.width.isMultiple(of: 2))
        XCTAssertTrue(size.height.isMultiple(of: 2))
        XCTAssertLessThanOrEqual(size.width, 3_840)
        XCTAssertLessThanOrEqual(size.height, 3_840)
    }

    func testCropSurfaceNeverRoundsAnOddPixelCapReductionUpward() {
        let size = CaptureSurfaceSize.fittedForVisibleRegion(
            sourcePointWidth: 3_001,
            sourcePointHeight: 3_001,
            pointPixelScale: 1,
            visibleRegion: NormalizedSourceRect(
                x: 0.25,
                y: 0.25,
                width: 0.5,
                height: 0.5
            ),
            maximumVisibleWidth: 2_001,
            maximumVisibleHeight: 2_001,
            hardMaximumPixelCount: 1_000_001
        )

        XCTAssertLessThanOrEqual(size.width * size.height, 1_000_001)
        XCTAssertTrue(size.width.isMultiple(of: 2))
        XCTAssertTrue(size.height.isMultiple(of: 2))
    }

    func testCropSurfaceHonorsTinyPixelCapForExtremeAspectRatio() {
        let size = CaptureSurfaceSize.fittedForVisibleRegion(
            sourcePointWidth: 3_840,
            sourcePointHeight: 2,
            pointPixelScale: 1,
            visibleRegion: .fullSource,
            maximumVisibleWidth: 3_840,
            maximumVisibleHeight: 2,
            hardMaximumPixelCount: 4
        )

        XCTAssertEqual(size, CaptureSurfaceSize(width: 2, height: 2))
    }

    func testPixelCapComparisonDoesNotLoseAnIntegerAtDoubleBoundary() {
        let maximumPixelCount = Int.max
        let size = CaptureSurfaceSize.fittedForVisibleRegion(
            sourcePointWidth: 4_294_967_296,
            sourcePointHeight: 2_147_483_648,
            pointPixelScale: 1,
            visibleRegion: .fullSource,
            maximumVisibleWidth: 4_294_967_296,
            maximumVisibleHeight: 2_147_483_648,
            hardMaximumDimension: Int.max,
            hardMaximumPixelCount: maximumPixelCount
        )

        XCTAssertLessThanOrEqual(size.width, maximumPixelCount / size.height)
        XCTAssertTrue(size.width.isMultiple(of: 2))
        XCTAssertTrue(size.height.isMultiple(of: 2))
    }
}
