import CoreGraphics
import XCTest
@testable import StagePaneCore

final class StageInteractionTests: XCTestCase {
    private let sourceA = StageSourceID(rawValue: "source-a")
    private let sourceB = StageSourceID(rawValue: "source-b")

    func testModesKeepArrangementControlAndAnnotationExclusive() throws {
        XCTAssertFalse(StageInteractionMode.arrange.forwardsPointerInput)
        XCTAssertFalse(StageInteractionMode.arrange.recordsAnnotations)
        XCTAssertTrue(StageInteractionMode.control.forwardsPointerInput)
        XCTAssertFalse(StageInteractionMode.control.recordsAnnotations)
        XCTAssertFalse(StageInteractionMode.annotate.forwardsPointerInput)
        XCTAssertTrue(StageInteractionMode.annotate.recordsAnnotations)

        let data = try JSONEncoder().encode(StageInteractionMode.annotate)
        XCTAssertEqual(try JSONDecoder().decode(StageInteractionMode.self, from: data), .annotate)
    }

    func testInverseProjectionRejectsLetterboxAndMapsVisibleContent() {
        let frame = NormalizedStageRect.fullCanvas
        let canvas = CGSize(width: 800, height: 800)
        let widescreen = CGSize(width: 1920, height: 1080)

        XCTAssertNil(StageInteractionProjection.normalizedSourcePoint(
            for: CGPoint(x: 400, y: 100),
            stageSize: canvas,
            sourceFrame: frame,
            sourceContentSize: widescreen
        ))
        XCTAssertEqual(StageInteractionProjection.normalizedSourcePoint(
            for: CGPoint(x: 400, y: 175),
            stageSize: canvas,
            sourceFrame: frame,
            sourceContentSize: widescreen
        ), CGPoint(x: 0.5, y: 0))
        XCTAssertEqual(StageInteractionProjection.normalizedSourcePoint(
            for: CGPoint(x: 400, y: 400),
            stageSize: canvas,
            sourceFrame: frame,
            sourceContentSize: widescreen
        ), CGPoint(x: 0.5, y: 0.5))
    }

    func testInverseProjectionAccountsForSourceTilePosition() {
        let point = StageInteractionProjection.normalizedSourcePoint(
            for: CGPoint(x: 600, y: 300),
            stageSize: CGSize(width: 800, height: 600),
            sourceFrame: NormalizedStageRect(x: 0.5, y: 0, width: 0.5, height: 1),
            sourceContentSize: CGSize(width: 400, height: 600)
        )

        XCTAssertEqual(point, CGPoint(x: 0.5, y: 0.5))
    }

    func testUniqueHitRejectsOverlappingVisibleSources() {
        let canvas = CGSize(width: 1000, height: 1000)
        let sources = [
            StageInteractionSource(
                id: sourceA,
                stageFrame: .fullCanvas,
                contentSize: canvas
            ),
            StageInteractionSource(
                id: sourceB,
                stageFrame: NormalizedStageRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5),
                contentSize: CGSize(width: 500, height: 500)
            )
        ]

        XCTAssertEqual(
            StageInteractionProjection.uniqueHit(
                at: CGPoint(x: 250, y: 250),
                stageSize: canvas,
                sources: sources
            ),
            StageInteractionHit(sourceID: sourceA, normalizedSourcePoint: CGPoint(x: 0.25, y: 0.25))
        )
        XCTAssertNil(StageInteractionProjection.uniqueHit(
            at: CGPoint(x: 750, y: 750),
            stageSize: canvas,
            sources: sources
        ))
    }

    func testFrontmostHitUsesStageZOrderAndNeverClicksThroughItsPadding() {
        let canvas = CGSize(width: 1000, height: 1000)
        let sources = [
            StageInteractionSource(
                id: sourceA,
                stageFrame: .fullCanvas,
                contentSize: canvas
            ),
            StageInteractionSource(
                id: sourceB,
                stageFrame: .fullCanvas,
                contentSize: CGSize(width: 1600, height: 400)
            )
        ]

        XCTAssertEqual(
            StageInteractionProjection.frontmostHit(
                at: CGPoint(x: 500, y: 500),
                stageSize: canvas,
                sources: sources
            )?.sourceID,
            sourceB
        )
        XCTAssertNil(StageInteractionProjection.frontmostHit(
            at: CGPoint(x: 500, y: 100),
            stageSize: canvas,
            sources: sources
        ))
    }

    func testUniqueHitIgnoresAnotherTilesLetterbox() {
        let sources = [
            StageInteractionSource(
                id: sourceA,
                stageFrame: .fullCanvas,
                contentSize: CGSize(width: 1000, height: 1000)
            ),
            StageInteractionSource(
                id: sourceB,
                stageFrame: .fullCanvas,
                contentSize: CGSize(width: 1600, height: 400)
            )
        ]

        XCTAssertEqual(
            StageInteractionProjection.uniqueHit(
                at: CGPoint(x: 500, y: 100),
                stageSize: CGSize(width: 1000, height: 1000),
                sources: sources
            )?.sourceID,
            sourceA
        )
    }

    func testGlobalProjectionSupportsNegativeDisplayOrigins() {
        XCTAssertEqual(
            StageInteractionProjection.globalPoint(
                for: CGPoint(x: 0.25, y: 0.75),
                sourceGlobalFrame: CGRect(x: -1920, y: -100, width: 1600, height: 900)
            ),
            CGPoint(x: -1520, y: 575)
        )
    }

    func testInvalidProjectionGeometryIsRejected() {
        XCTAssertNil(StageInteractionProjection.normalizedSourcePoint(
            for: CGPoint(x: CGFloat.nan, y: 0),
            stageSize: CGSize(width: 100, height: 100),
            sourceFrame: .fullCanvas,
            sourceContentSize: CGSize(width: 100, height: 100)
        ))
        XCTAssertNil(StageInteractionProjection.globalPoint(
            for: CGPoint(x: 1.01, y: 0.5),
            sourceGlobalFrame: CGRect(x: 0, y: 0, width: 100, height: 100)
        ))
    }
}
