import XCTest
@testable import StagePaneCore

final class CaptureSurfaceStabilityTests: XCTestCase {
    func testReportedSourceJitterCannotOscillateTheConfiguredSurface() {
        let anchor = CaptureSurfaceSize.fitted(
            sourcePointWidth: 1_440,
            sourcePointHeight: 900,
            pointPixelScale: 2,
            maximumWidth: 1_920,
            maximumHeight: 1_080
        )
        XCTAssertEqual(anchor, CaptureSurfaceSize(width: 1_728, height: 1_080))

        let reportedWidths = [
            1_440.6, 1_439.4, 1_440.6, 1_439.4, 1_440.6, 1_439.4
        ]
        var current = anchor
        for (step, reportedWidth) in reportedWidths.enumerated() {
            let target = CaptureSurfaceSize.fitted(
                sourcePointWidth: reportedWidth,
                sourcePointHeight: 900,
                pointPixelScale: 2,
                maximumWidth: 1_920,
                maximumHeight: 1_080
            )
            if step == 0 {
                // This is exactly the comparison the debounced observer used to
                // make: two freshly recomputed fits, which differ here, so a
                // full stream reconfiguration and one hide/reveal cycle were
                // armed on every single step of this jitter.
                XCTAssertNotEqual(target, anchor)
                XCTAssertEqual(
                    target, CaptureSurfaceSize(width: 1_730, height: 1_080)
                )
            }

            XCTAssertFalse(
                CaptureSurfaceStability.exceedsReconfigurationDeadband(
                    applied: current,
                    target: target
                ),
                "step \(step) left the deadband"
            )
            current = CaptureSurfaceStability.resolvedSurfaceSize(
                applied: current,
                target: target
            )
            XCTAssertEqual(current, anchor, "step \(step) moved the surface")
        }
    }

    func testEvenRoundingFlipsAreAbsorbed() {
        let flips = [(1_280, 1_282), (1_280, 1_278), (1_920, 1_918), (902, 904)]
        for (applied, target) in flips {
            XCTAssertFalse(
                CaptureSurfaceStability.exceedsReconfigurationDeadband(
                    applied: CaptureSurfaceSize(width: applied, height: 720),
                    target: CaptureSurfaceSize(width: target, height: 720)
                ),
                "width \(applied) -> \(target)"
            )
            XCTAssertFalse(
                CaptureSurfaceStability.exceedsReconfigurationDeadband(
                    applied: CaptureSurfaceSize(width: 720, height: applied),
                    target: CaptureSurfaceSize(width: 720, height: target)
                ),
                "height \(applied) -> \(target)"
            )
        }
    }

    func testGenuineResizeIsAdopted() {
        let applied = CaptureSurfaceSize(width: 1_280, height: 720)
        let target = CaptureSurfaceSize(width: 1_600, height: 900)

        XCTAssertTrue(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: applied,
                target: target
            )
        )
        XCTAssertEqual(
            CaptureSurfaceStability.resolvedSurfaceSize(
                applied: applied,
                target: target
            ),
            target
        )
        XCTAssertTrue(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: applied,
                target: CaptureSurfaceSize(width: 1_280, height: 640)
            )
        )
    }

    func testDeadbandReanchorsWithoutRatcheting() {
        XCTAssertTrue(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: CaptureSurfaceSize(width: 1_280, height: 720),
                target: CaptureSurfaceSize(width: 1_400, height: 720)
            )
        )
        // Once 1400 is applied, the band follows it instead of staying centred
        // on the size that was replaced.
        XCTAssertFalse(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: CaptureSurfaceSize(width: 1_400, height: 720),
                target: CaptureSurfaceSize(width: 1_382, height: 720)
            )
        )
    }

    func testSmallSurfaceUsesThePixelFloor() {
        XCTAssertFalse(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: CaptureSurfaceSize(width: 20, height: 20),
                target: CaptureSurfaceSize(width: 24, height: 20)
            )
        )
        XCTAssertTrue(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: CaptureSurfaceSize(width: 20, height: 20),
                target: CaptureSurfaceSize(width: 26, height: 20)
            )
        )
    }

    func testNonPositiveAppliedDimensionAlwaysExceeds() {
        // The documented fail-open rule. No app path can reach it today,
        // because every applied size is seeded from a fit whose axes are
        // floored at two, but the band is anchored to a value this type does
        // not own: if that anchor ever moves, an applied zero would otherwise
        // be treated as a surface worth staying near, and the pixel floor
        // alone would then suppress the first real reconfiguration.
        //
        // Every target here sits inside that floor, so the rule is the only
        // thing that can decide the outcome: a distant target leaves the band
        // on its own and would pin nothing.
        XCTAssertTrue(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: CaptureSurfaceSize(width: 0, height: 720),
                target: CaptureSurfaceSize(width: 2, height: 720)
            )
        )
        XCTAssertTrue(
            CaptureSurfaceStability.exceedsReconfigurationDeadband(
                applied: CaptureSurfaceSize(width: 1_280, height: -2),
                target: CaptureSurfaceSize(width: 1_280, height: 2)
            )
        )
        XCTAssertEqual(
            CaptureSurfaceStability.resolvedSurfaceSize(
                applied: CaptureSurfaceSize(width: 0, height: 0),
                target: CaptureSurfaceSize(width: 2, height: 2)
            ),
            CaptureSurfaceSize(width: 2, height: 2)
        )
    }

    func testNilAppliedAdoptsTarget() {
        let target = CaptureSurfaceSize(width: 1_920, height: 1_080)

        XCTAssertEqual(
            CaptureSurfaceStability.resolvedSurfaceSize(
                applied: nil,
                target: target
            ),
            target
        )
    }

    func testRetainedSurfaceStillHonoursEveryCap() {
        let rows: [RetentionCase] = [
            RetentionCase(
                sourcePointWidth: 1_440,
                sourcePointHeight: 900,
                pointPixelScale: 2,
                crop: .fullSource,
                appliedBudgetWidth: 1_920,
                appliedBudgetHeight: 1_080,
                targetSourcePointWidth: 1_440.6,
                targetBudgetWidth: 1_920,
                targetBudgetHeight: 1_080,
                applied: CaptureSurfaceSize(width: 1_728, height: 1_080),
                target: CaptureSurfaceSize(width: 1_730, height: 1_080),
                resolved: CaptureSurfaceSize(width: 1_728, height: 1_080)
            ),
            // An aggressive crop raises the full-source budget past every cap,
            // so the fit is already cap-bound and metadata wobble cannot move
            // it at all. The retained value is still a fit, which is what the
            // caps below are asserted against.
            RetentionCase(
                sourcePointWidth: 3_000,
                sourcePointHeight: 2_000,
                pointPixelScale: 2,
                crop: NormalizedSourceRect(
                    x: 0, y: 0, width: 0.01, height: 0.01
                ),
                appliedBudgetWidth: 3_840,
                appliedBudgetHeight: 3_840,
                targetSourcePointWidth: 3_000.6,
                targetBudgetWidth: 3_840,
                targetBudgetHeight: 3_840,
                applied: CaptureSurfaceSize(width: 3_526, height: 2_350),
                target: CaptureSurfaceSize(width: 3_526, height: 2_350),
                resolved: CaptureSurfaceSize(width: 3_526, height: 2_350)
            ),
            RetentionCase(
                sourcePointWidth: 5_120,
                sourcePointHeight: 2_880,
                pointPixelScale: 2,
                crop: NormalizedSourceRect(
                    x: 0.1, y: 0.1, width: 0.2, height: 0.3
                ),
                appliedBudgetWidth: 3_840,
                appliedBudgetHeight: 2_160,
                targetSourcePointWidth: 5_120.6,
                targetBudgetWidth: 3_840,
                targetBudgetHeight: 2_160,
                applied: CaptureSurfaceSize(width: 3_840, height: 2_160),
                target: CaptureSurfaceSize(width: 3_840, height: 2_160),
                resolved: CaptureSurfaceSize(width: 3_840, height: 2_160)
            ),
            RetentionCase(
                sourcePointWidth: 160,
                sourcePointHeight: 120,
                pointPixelScale: 1,
                crop: .fullSource,
                appliedBudgetWidth: 400,
                appliedBudgetHeight: 400,
                targetSourcePointWidth: 160.6,
                targetBudgetWidth: 400,
                targetBudgetHeight: 400,
                applied: CaptureSurfaceSize(width: 160, height: 120),
                target: CaptureSurfaceSize(width: 162, height: 120),
                resolved: CaptureSurfaceSize(width: 160, height: 120)
            ),
            RetentionCase(
                sourcePointWidth: 1_920,
                sourcePointHeight: 1_080,
                pointPixelScale: 1,
                crop: NormalizedSourceRect(
                    x: 0, y: 0, width: 0.5, height: 0.5
                ),
                appliedBudgetWidth: 1_280,
                appliedBudgetHeight: 720,
                targetSourcePointWidth: 1_920.6,
                targetBudgetWidth: 1_280,
                targetBudgetHeight: 720,
                applied: CaptureSurfaceSize(width: 1_920, height: 1_080),
                target: CaptureSurfaceSize(width: 1_922, height: 1_080),
                resolved: CaptureSurfaceSize(width: 1_920, height: 1_080)
            ),
            // A budget that shrinks instead of growing: the retained surface
            // is now larger than the target on both axes, which is the
            // direction the rest of this table never moves in.
            RetentionCase(
                sourcePointWidth: 1_440,
                sourcePointHeight: 900,
                pointPixelScale: 2,
                crop: .fullSource,
                appliedBudgetWidth: 1_920,
                appliedBudgetHeight: 1_080,
                targetSourcePointWidth: 1_440,
                targetBudgetWidth: 1_900,
                targetBudgetHeight: 1_060,
                applied: CaptureSurfaceSize(width: 1_728, height: 1_080),
                target: CaptureSurfaceSize(width: 1_696, height: 1_060),
                resolved: CaptureSurfaceSize(width: 1_728, height: 1_080)
            )
        ]

        for (index, row) in rows.enumerated() {
            let applied = CaptureSurfaceSize.fittedForVisibleRegion(
                sourcePointWidth: row.sourcePointWidth,
                sourcePointHeight: row.sourcePointHeight,
                pointPixelScale: row.pointPixelScale,
                visibleRegion: row.crop,
                maximumVisibleWidth: row.appliedBudgetWidth,
                maximumVisibleHeight: row.appliedBudgetHeight
            )
            let target = CaptureSurfaceSize.fittedForVisibleRegion(
                sourcePointWidth: row.targetSourcePointWidth,
                sourcePointHeight: row.sourcePointHeight,
                pointPixelScale: row.pointPixelScale,
                visibleRegion: row.crop,
                maximumVisibleWidth: row.targetBudgetWidth,
                maximumVisibleHeight: row.targetBudgetHeight
            )
            let resolved = CaptureSurfaceStability.resolvedSurfaceSize(
                applied: applied,
                target: target
            )

            XCTAssertEqual(applied, row.applied, "row \(index) applied fit")
            XCTAssertEqual(target, row.target, "row \(index) target fit")
            XCTAssertEqual(resolved, row.resolved, "row \(index) decision")

            // Whichever of the two the policy kept, the stream is left on a
            // previous `fitted` output, so the per-dimension and total pixel
            // caps hold without this policy knowing what they are.
            XCTAssertLessThanOrEqual(resolved.width, 3_840)
            XCTAssertLessThanOrEqual(resolved.height, 3_840)
            XCTAssertLessThanOrEqual(
                resolved.width * resolved.height,
                CaptureSurfaceSize.defaultMaximumPixelCount
            )
        }
    }

    func testSubThresholdSourceJitterDoesNotArmReconfiguration() throws {
        let previous = try XCTUnwrap(CaptureSourceGeometry(
            surfaceContentPointWidth: 1_440,
            surfaceContentPointHeight: 900,
            contentScale: 1,
            pointPixelScale: 2
        ))
        let jittered = try XCTUnwrap(CaptureSourceGeometry(
            surfaceContentPointWidth: 1_440.6,
            surfaceContentPointHeight: 900,
            contentScale: 1,
            pointPixelScale: 2
        ))

        // The replaced half-point rule would have fired on exactly this wobble
        // and armed the 250 ms reconfiguration debounce.
        XCTAssertGreaterThanOrEqual(
            abs(jittered.pointWidth - previous.pointWidth), 0.5
        )
        XCTAssertFalse(
            CaptureSourceGeometryChange.isMeaningful(
                jittered,
                comparedTo: previous
            )
        )
    }

    func testSourceChangeThresholdIsRelativeWithAPointFloor() throws {
        // Both point axes are exercised, because either one alone changes the
        // aspect the surface has to follow: a user dragging only the bottom
        // edge of a shared window leaves the width and the backing scale
        // untouched, and if that is not meaningful the debounce is never armed
        // and the tile keeps a stale aspect for the rest of the session.
        let rows: [(CaptureSourceGeometry, CaptureSourceGeometry, Bool)] = [
            (try source(3_000, 2_000), try source(3_001, 2_000), false),
            (try source(3_000, 2_000), try source(3_040, 2_000), true),
            (try source(3_000, 2_000), try source(3_000, 2_001), false),
            (try source(3_000, 2_000), try source(3_000, 2_040), true),
            (try source(160, 120), try source(163, 120), true),
            (try source(160, 120), try source(160, 123), true),
            // One percent of a small source is below the even-pixel
            // granularity the fit rounds to, so the two-point floor decides
            // instead. These rows are small enough that the relative term is
            // well under the floor, and they bracket it from both sides: a
            // lower floor would make the 1.5-point rows meaningful and restore
            // the half-point hair trigger this change removed, and a higher
            // one would stop following a real two-point resize.
            (try source(80, 60), try source(81.5, 60), false),
            (try source(80, 60), try source(80, 61.5), false),
            (try source(80, 60), try source(82, 60), true),
            (try source(80, 60), try source(80, 62), true)
        ]

        for (previous, candidate, expected) in rows {
            XCTAssertEqual(
                CaptureSourceGeometryChange.isMeaningful(
                    candidate,
                    comparedTo: previous
                ),
                expected,
                "\(previous.pointWidth)x\(previous.pointHeight) -> " +
                    "\(candidate.pointWidth)x\(candidate.pointHeight)"
            )
        }

        // A backing-scale change alters the native pixel size and is never
        // metadata noise.
        XCTAssertTrue(CaptureSourceGeometryChange.isMeaningful(
            try source(160, 120, pointPixelScale: 1),
            comparedTo: try source(160, 120)
        ))

        XCTAssertTrue(CaptureSourceGeometryChange.isMeaningful(
            try source(3_000, 2_000),
            comparedTo: nil
        ))
    }

    /// One retention decision with the fit on each side of it written out.
    ///
    /// Naming the two fits and the expected outcome is the point of the table:
    /// `resolvedSurfaceSize` returns one of its own arguments by construction,
    /// so asserting only that the result is one of them cannot fail whatever
    /// the policy does.
    private struct RetentionCase {
        let sourcePointWidth: Double
        let sourcePointHeight: Double
        let pointPixelScale: Double
        let crop: NormalizedSourceRect
        let appliedBudgetWidth: Int
        let appliedBudgetHeight: Int
        let targetSourcePointWidth: Double
        let targetBudgetWidth: Int
        let targetBudgetHeight: Int
        let applied: CaptureSurfaceSize
        let target: CaptureSurfaceSize
        let resolved: CaptureSurfaceSize
    }

    private func source(
        _ pointWidth: Double,
        _ pointHeight: Double,
        pointPixelScale: Double = 2
    ) throws -> CaptureSourceGeometry {
        try XCTUnwrap(CaptureSourceGeometry(
            surfaceContentPointWidth: pointWidth,
            surfaceContentPointHeight: pointHeight,
            contentScale: 1,
            pointPixelScale: pointPixelScale
        ))
    }
}

final class CaptureStreamConfigurationRequestTests: XCTestCase {
    private let running = CaptureStreamConfigurationRequest(
        surfaceWidth: 1_728,
        surfaceHeight: 1_080,
        showsCursor: false
    )

    func testLandingOnTheRunningConfigurationCostsNoReconfiguration() {
        // A picker content replacement that resolves to the shape the stream is
        // already running used to pay one reconfiguration back to the
        // filter-derived size and a second from the first real frame. Both were
        // visible on the shared Stage as a hide/reveal cycle.
        XCTAssertFalse(
            running.requiresReconfiguration(
                to: CaptureStreamConfigurationRequest(
                    surfaceWidth: 1_728,
                    surfaceHeight: 1_080,
                    showsCursor: false
                )
            )
        )
    }

    func testEachConfiguredValueIsEnoughOnItsOwn() {
        XCTAssertTrue(
            running.requiresReconfiguration(
                to: CaptureStreamConfigurationRequest(
                    surfaceWidth: 1_730,
                    surfaceHeight: 1_080,
                    showsCursor: false
                )
            )
        )
        XCTAssertTrue(
            running.requiresReconfiguration(
                to: CaptureStreamConfigurationRequest(
                    surfaceWidth: 1_728,
                    surfaceHeight: 1_082,
                    showsCursor: false
                )
            )
        )
        XCTAssertTrue(
            running.requiresReconfiguration(
                to: CaptureStreamConfigurationRequest(
                    surfaceWidth: 1_728,
                    surfaceHeight: 1_080,
                    showsCursor: true
                )
            )
        )
    }

    func testTheDecisionIsSymmetricAndRepeatable() {
        let target = CaptureStreamConfigurationRequest(
            surfaceWidth: 1_280,
            surfaceHeight: 720,
            showsCursor: true
        )
        XCTAssertTrue(running.requiresReconfiguration(to: target))
        XCTAssertTrue(target.requiresReconfiguration(to: running))
        // Once the target is adopted as the requested configuration, repeating
        // the same commit must be free, which is what stops a commit loop from
        // reconfiguring forever.
        XCTAssertFalse(target.requiresReconfiguration(to: target))
    }
}
