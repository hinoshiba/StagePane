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
}
