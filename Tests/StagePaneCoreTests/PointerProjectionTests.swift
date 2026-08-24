import CoreGraphics
import XCTest
@testable import StagePaneCore

final class PointerProjectionTests: XCTestCase {
    func testRetinaFrameCenterMapsToSurfaceCenter() {
        let geometry = PointerFrameGeometry(
            screenRect: CGRect(x: 100, y: 200, width: 800, height: 600),
            contentRect: CGRect(x: 120, y: 0, width: 720, height: 540),
            surfacePointSize: CGSize(width: 960, height: 540),
            boundingRect: CGRect(x: 120, y: 0, width: 720, height: 540)
        )

        XCTAssertEqual(
            geometry.normalizedPosition(for: CGPoint(x: 500, y: 500)),
            CGPoint(x: 0.5, y: 0.5)
        )
    }

    func testNegativeDisplayOriginMapsCorrectly() {
        let geometry = PointerFrameGeometry(
            screenRect: CGRect(x: -1920, y: 0, width: 1920, height: 1080),
            contentRect: CGRect(x: 0, y: 0, width: 960, height: 540),
            surfacePointSize: CGSize(width: 960, height: 540)
        )

        XCTAssertEqual(
            geometry.normalizedPosition(for: CGPoint(x: -960, y: 540)),
            CGPoint(x: 0.5, y: 0.5)
        )
    }

    func testGlobalProjectionRoundTripsDisplayedFrameGeometry() {
        let geometry = PointerFrameGeometry(
            screenRect: CGRect(x: -1500, y: 120, width: 1200, height: 800),
            contentRect: CGRect(x: 80, y: 20, width: 900, height: 600),
            surfacePointSize: CGSize(width: 1060, height: 640),
            boundingRect: CGRect(x: 80, y: 20, width: 900, height: 600)
        )
        let global = CGPoint(x: -900, y: 520)
        let normalized = geometry.normalizedPosition(for: global)

        XCTAssertNotNil(normalized)
        XCTAssertEqual(geometry.globalPosition(for: normalized!), global)
        XCTAssertNil(geometry.globalPosition(for: CGPoint(x: 0.01, y: 0.5)))
    }

    func testPointerOutsideScreenOrBoundingRectIsHidden() {
        let geometry = PointerFrameGeometry(
            screenRect: CGRect(x: 0, y: 0, width: 1000, height: 800),
            contentRect: CGRect(x: 100, y: 50, width: 800, height: 640),
            surfacePointSize: CGSize(width: 1000, height: 750),
            boundingRect: CGRect(x: 300, y: 200, width: 400, height: 300)
        )

        XCTAssertNil(geometry.normalizedPosition(for: CGPoint(x: -1, y: 400)))
        XCTAssertNil(geometry.normalizedPosition(for: CGPoint(x: 50, y: 50)))
        XCTAssertNotNil(geometry.normalizedPosition(for: CGPoint(x: 500, y: 400)))
    }

    func testStagePointMatchesAspectFitInSquareView() {
        XCTAssertEqual(
            PointerProjection.stagePoint(
                normalizedPosition: CGPoint(x: 0.5, y: 0.5),
                surfaceSize: CGSize(width: 1920, height: 1080),
                stageSize: CGSize(width: 800, height: 800)
            ),
            CGPoint(x: 400, y: 400)
        )
        XCTAssertEqual(
            PointerProjection.stagePoint(
                normalizedPosition: CGPoint(x: 0.5, y: 0),
                surfaceSize: CGSize(width: 1920, height: 1080),
                stageSize: CGSize(width: 800, height: 800)
            ),
            CGPoint(x: 400, y: 175)
        )
    }

    func testInvalidGeometryIsRejected() {
        let valid = CGPoint(x: 0.5, y: 0.5)
        XCTAssertNil(
            PointerFrameGeometry(
                screenRect: .zero,
                contentRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                surfacePointSize: CGSize(width: 1, height: 1)
            ).normalizedPosition(for: .zero)
        )
        XCTAssertNil(
            PointerProjection.stagePoint(
                normalizedPosition: valid,
                surfaceSize: CGSize(width: CGFloat.infinity, height: 1),
                stageSize: CGSize(width: 100, height: 100)
            )
        )
        XCTAssertNil(
            PointerProjection.stagePoint(
                normalizedPosition: CGPoint(x: CGFloat.nan, y: 0),
                surfaceSize: CGSize(width: 1, height: 1),
                stageSize: CGSize(width: 100, height: 100)
            )
        )
    }
}
