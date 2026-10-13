import CoreGraphics
import XCTest
@testable import StagePaneCore

final class StageMagnifierGeometryTests: XCTestCase {
    func testFocusRemainsAtLensCenterAndSizeMatchesAcrossCanvases() throws {
        let preview = try XCTUnwrap(StageMagnifierGeometry(
            canvasSize: CGSize(width: 1_000, height: 600),
            normalizedPosition: CGPoint(x: 0.5, y: 0.5)
        ))
        let audience = try XCTUnwrap(StageMagnifierGeometry(
            canvasSize: CGSize(width: 2_000, height: 1_200),
            normalizedPosition: CGPoint(x: 0.5, y: 0.5)
        ))

        assertRect(preview.lensFrame, CGRect(x: 392, y: 192, width: 216, height: 216))
        assertRect(preview.sampledStageRect, CGRect(x: 446, y: 246, width: 108, height: 108))
        assertRect(audience.lensFrame, preview.lensFrame.applying(
            CGAffineTransform(scaleX: 2, y: 2)
        ))
        assertRect(audience.sampledStageRect, preview.sampledStageRect.applying(
            CGAffineTransform(scaleX: 2, y: 2)
        ))
    }

    func testChangingMagnificationPreservesLensSizeAndFocus() throws {
        let sizes: [Double] = [2, 3, 4]
        for magnification in sizes {
            let geometry = try XCTUnwrap(StageMagnifierGeometry(
                canvasSize: CGSize(width: 1_000, height: 600),
                normalizedPosition: CGPoint(x: 0.6, y: 0.4),
                magnification: magnification
            ))
            XCTAssertEqual(geometry.lensFrame.width, 216)
            XCTAssertEqual(geometry.sampledStageRect.width, 216 / magnification)
            XCTAssertEqual(geometry.sampledStageRect.midX, 600)
            XCTAssertEqual(geometry.sampledStageRect.midY, 240)
        }
    }

    func testEdgeLensStaysInsideCanvasAndSamplesOnlyVisiblePixels() throws {
        let geometry = try XCTUnwrap(StageMagnifierGeometry(
            canvasSize: CGSize(width: 1_000, height: 600),
            normalizedPosition: CGPoint(x: 0, y: 0.5)
        ))
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: geometry.canvasSize,
            contentRect: CGRect(origin: .zero, size: geometry.canvasSize)
        ))
        let projection = try XCTUnwrap(geometry.sourceProjection(
            presentation: presentation,
            sourceCrop: .fullSource,
            destinationFrame: CGRect(origin: .zero, size: geometry.canvasSize)
        ))

        XCTAssertEqual(geometry.lensFrame.minX, 0)
        XCTAssertEqual(geometry.sampledStageRect.midX, 0)
        assertRect(projection.normalizedSurfaceRect,
                   CGRect(x: 0, y: 0.41, width: 0.054, height: 0.18))
        assertRect(projection.lensRect, CGRect(x: 108, y: 0, width: 108, height: 216))
    }

    func testPaddedSurfaceCropMapsToCorrectAcceptedPixels() throws {
        let geometry = try XCTUnwrap(StageMagnifierGeometry(
            canvasSize: CGSize(width: 800, height: 450),
            normalizedPosition: CGPoint(x: 0.5, y: 0.5)
        ))
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 960, height: 540),
            contentRect: CGRect(x: 120, y: 45, width: 720, height: 450)
        ))
        let projection = try XCTUnwrap(geometry.sourceProjection(
            presentation: presentation,
            sourceCrop: NormalizedSourceRect(x: 0.25, y: 0.2, width: 0.5, height: 0.6),
            destinationFrame: CGRect(x: 0, y: 0, width: 800, height: 450)
        ))

        assertRect(projection.normalizedSurfaceRect,
                   CGRect(x: 0.4746875, y: 0.455, width: 0.050625, height: 0.09))
        assertRect(projection.lensRect, CGRect(x: 0, y: 0, width: 162, height: 162))
    }

    func testLetterboxMarginsDoNotSampleExcludedSourcePixels() throws {
        let geometry = try XCTUnwrap(StageMagnifierGeometry(
            canvasSize: CGSize(width: 1_000, height: 600),
            normalizedPosition: CGPoint(x: 0.1, y: 0.5)
        ))
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 1_000, height: 600),
            contentRect: CGRect(x: 0, y: 0, width: 1_000, height: 600)
        ))
        XCTAssertNil(geometry.sourceProjection(
            presentation: presentation,
            sourceCrop: NormalizedSourceRect(x: 0.3, y: 0, width: 0.4, height: 1),
            destinationFrame: CGRect(x: 0, y: 0, width: 1_000, height: 600)
        ))
    }

    func testPartlyOverlappingTileIsClippedAndPlacedInsideLens() throws {
        let geometry = try XCTUnwrap(StageMagnifierGeometry(
            canvasSize: CGSize(width: 1_000, height: 600),
            normalizedPosition: CGPoint(x: 0.5, y: 0.5)
        ))
        let presentation = try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: CGSize(width: 300, height: 300),
            contentRect: CGRect(x: 0, y: 0, width: 300, height: 300)
        ))
        let projection = try XCTUnwrap(geometry.sourceProjection(
            presentation: presentation,
            sourceCrop: .fullSource,
            destinationFrame: CGRect(x: 500, y: 200, width: 300, height: 300)
        ))
        assertRect(projection.normalizedSurfaceRect,
                   CGRect(x: 0, y: 46.0 / 300, width: 0.18, height: 0.36))
        assertRect(projection.lensRect, CGRect(x: 108, y: 0, width: 108, height: 216))
    }

    func testInvalidCanvasPositionAndMagnificationAreRejected() {
        let validSize = CGSize(width: 800, height: 450)
        let center = CGPoint(x: 0.5, y: 0.5)
        for size in [CGSize.zero, CGSize(width: CGFloat.infinity, height: 450)] {
            XCTAssertNil(StageMagnifierGeometry(canvasSize: size, normalizedPosition: center))
        }
        for point in [CGPoint(x: -CGFloat.infinity, y: 0), CGPoint(x: 1.1, y: 0.5)] {
            XCTAssertNil(StageMagnifierGeometry(canvasSize: validSize, normalizedPosition: point))
        }
        for scale in [Double.nan, Double.infinity, 0, -2] {
            XCTAssertNil(StageMagnifierGeometry(
                canvasSize: validSize,
                normalizedPosition: center,
                magnification: scale
            ))
        }
    }

    private func assertRect(
        _ actual: CGRect,
        _ expected: CGRect,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.minX, expected.minX, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(actual.minY, expected.minY, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(actual.width, expected.width, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(actual.height, expected.height, accuracy: 0.000_001, file: file, line: line)
    }
}
