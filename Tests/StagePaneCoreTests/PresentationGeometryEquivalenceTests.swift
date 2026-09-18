import CoreGraphics
import XCTest
@testable import StagePaneCore

final class PresentationGeometryEquivalenceTests: XCTestCase {
    private static let tolerance =
        PresentationGeometryEquivalence.maximumDestinationFraction *
        PresentationGeometryEquivalence.minimumCropFraction

    private static let crops: [NormalizedSourceRect] = [
        .fullSource,
        NormalizedSourceRect(x: 0.25, y: 0.1, width: 0.5, height: 0.4),
        NormalizedSourceRect(x: 0.9, y: 0.9, width: 0.05, height: 0.05),
        NormalizedSourceRect(x: 0.4, y: 0.4, width: 0.01, height: 0.01)
    ]

    private static let destinations: [CGSize] = [
        CGSize(width: 1_280, height: 720),
        CGSize(width: 640, height: 640),
        CGSize(width: 300, height: 900),
        CGSize(width: 4_096, height: 2_304)
    ]

    /// The worst legal magnification: the tightest crop
    /// ``NormalizedSourceRect`` can hold, which is also the crop the predicate
    /// takes its bound at.
    private static let tightestCrop = NormalizedSourceRect(
        x: 0.4, y: 0.4, width: 0.01, height: 0.01
    )

    /// The largest destination the live Stage presents into.
    private static let stageDestination = CGSize(width: 4_096, height: 2_304)

    /// The Audience export ceiling
    /// (``StageSnapshotSize/maximumDimension``), which the same committed
    /// layout has to survive.
    private static let exportCeilingDestination = CGSize(
        width: 7_680, height: 4_320
    )

    func testNilPublishedGeometryRequiresTransition() throws {
        let incoming = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: 0, y: 0, width: 960, height: 540)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: nil,
                incoming: incoming
            ),
            .requiresTransition
        )
    }

    func testIdenticalGeometryIsIdentical() throws {
        let published = try geometry(
            surface: CGSize(width: 800, height: 600),
            content: CGRect(x: 0, y: 40, width: 800, height: 520)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: published
            ),
            .identical
        )
    }

    func testProportionalSurfaceChangeIsLayoutEquivalent() throws {
        for (published, incoming) in try proportionalPairs() {
            // Today's guard is an exact equality test, so every one of these
            // pairs hides the tile, flushes the hidden state and only then
            // reveals it again.
            XCTAssertNotEqual(published, incoming)
            XCTAssertEqual(
                PresentationGeometryEquivalence.relation(
                    published: published,
                    incoming: incoming
                ),
                .layoutEquivalent
            )
        }
    }

    func testLayoutEquivalentChangeKeepsEverySourceFrameAndMask() throws {
        for (published, incoming) in try proportionalPairs() {
            for crop in Self.crops {
                for destination in Self.destinations {
                    let publishedFrame = try XCTUnwrap(
                        SourceCropProjection.sourceFrame(
                            presentation: published,
                            sourceCrop: crop,
                            destinationSize: destination
                        )
                    )
                    let incomingFrame = try XCTUnwrap(
                        SourceCropProjection.sourceFrame(
                            presentation: incoming,
                            sourceCrop: crop,
                            destinationSize: destination
                        )
                    )

                    XCTAssertEqual(
                        publishedFrame.minX, incomingFrame.minX, accuracy: 1e-6
                    )
                    XCTAssertEqual(
                        publishedFrame.minY, incomingFrame.minY, accuracy: 1e-6
                    )
                    XCTAssertEqual(
                        publishedFrame.width, incomingFrame.width, accuracy: 1e-6
                    )
                    XCTAssertEqual(
                        publishedFrame.height, incomingFrame.height, accuracy: 1e-6
                    )

                    // The mask is a normalized rectangle scaled by the laid-out
                    // bounds, so compare the rendered edge rather than the
                    // normalized one.
                    let publishedMask = try XCTUnwrap(
                        SourceCropProjection.surfaceCropRect(
                            presentation: published,
                            sourceCrop: crop
                        )
                    )
                    let incomingMask = try XCTUnwrap(
                        SourceCropProjection.surfaceCropRect(
                            presentation: incoming,
                            sourceCrop: crop
                        )
                    )
                    XCTAssertEqual(
                        publishedMask.minX * publishedFrame.width,
                        incomingMask.minX * incomingFrame.width,
                        accuracy: 1e-6
                    )
                    XCTAssertEqual(
                        publishedMask.maxX * publishedFrame.width,
                        incomingMask.maxX * incomingFrame.width,
                        accuracy: 1e-6
                    )
                    XCTAssertEqual(
                        publishedMask.minY * publishedFrame.height,
                        incomingMask.minY * incomingFrame.height,
                        accuracy: 1e-6
                    )
                    XCTAssertEqual(
                        publishedMask.maxY * publishedFrame.height,
                        incomingMask.maxY * incomingFrame.height,
                        accuracy: 1e-6
                    )
                }
            }
        }
    }

    func testAspectChangeRequiresTransition() throws {
        let published = try geometry(
            surface: CGSize(width: 640, height: 360),
            content: CGRect(x: 0, y: 0, width: 640, height: 360)
        )
        let incoming = try geometry(
            surface: CGSize(width: 640, height: 400),
            content: CGRect(x: 0, y: 0, width: 640, height: 400)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: incoming
            ),
            .requiresTransition
        )

        // The rejection is necessary, not merely conservative: the projected
        // source frame genuinely moves, so presenting the incoming surface
        // through the published layout would misregister it.
        let destination = CGSize(width: 1_280, height: 720)
        let publishedFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: published,
            sourceCrop: .fullSource,
            destinationSize: destination
        ))
        let incomingFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: incoming,
            sourceCrop: .fullSource,
            destinationSize: destination
        ))

        XCTAssertNotEqual(publishedFrame, incomingFrame)
        assertRect(publishedFrame, x: 0, y: 0, width: 1_280, height: 720)
        assertRect(incomingFrame, x: 64, y: 0, width: 1_152, height: 720)
    }

    func testNewLetterboxPaddingRequiresTransition() throws {
        let published = try geometry(
            surface: CGSize(width: 640, height: 360),
            content: CGRect(x: 0, y: 0, width: 640, height: 360)
        )
        let incoming = try geometry(
            surface: CGSize(width: 640, height: 360),
            content: CGRect(x: 0, y: 20, width: 640, height: 320)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: incoming
            ),
            .requiresTransition
        )
    }

    func testReconfigurationRoundingChangeRequiresTransition() throws {
        // Two surfaces one source is fitted to when the independent even-pixel
        // rounding lands differently. Their normalized content edges differ by
        // about 1.8e-4, nearly three orders of magnitude above the tolerance,
        // so a padded reconfiguration still takes the full handshake.
        let published = try geometry(
            surface: CGSize(width: 960, height: 541),
            content: CGRect(x: 0, y: 0.5, width: 960, height: 540)
        )
        let incoming = try geometry(
            surface: CGSize(width: 800, height: 451),
            content: CGRect(x: 0, y: 0.5, width: 800, height: 450)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: incoming
            ),
            .requiresTransition
        )
    }

    func testHorizontalToleranceBoundaryIsAdmitted() throws {
        let published = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: 0, y: 0, width: 960, height: 540)
        )
        let shift = Self.tolerance * 960
        let incoming = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: shift, y: 0, width: 960 - shift, height: 540)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: incoming
            ),
            .layoutEquivalent
        )
        XCTAssertLessThan(
            try renderedDelta(
                published: published,
                incoming: incoming,
                crop: Self.tightestCrop,
                destination: Self.stageDestination
            ),
            0.5
        )
    }

    func testVerticalToleranceBoundaryIsAdmitted() throws {
        // The exact mirror of the horizontal case. The two axes carry
        // independent tolerances, and this predicate is what decides whether a
        // frame may be presented through a layout AppKit committed for another
        // surface, so an axis whose only rejections sit orders of magnitude
        // outside it is an axis nothing actually holds in place.
        let published = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: 0, y: 0, width: 960, height: 540)
        )
        let shift = Self.tolerance * 540
        let incoming = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: 0, y: shift, width: 960, height: 540 - shift)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: incoming
            ),
            .layoutEquivalent
        )
        XCTAssertLessThan(
            try renderedDelta(
                published: published,
                incoming: incoming,
                crop: Self.tightestCrop,
                destination: Self.stageDestination
            ),
            0.5
        )
    }

    func testSurfaceAspectToleranceBoundaryIsAdmitted() throws {
        // Both geometries hold the identical normalized contentRect on both
        // axes, so the surface aspect is the only quantity this pair moves and
        // the only tolerance it can be admitted on.
        let published = try geometry(
            surface: CGSize(width: 1_728, height: 1_080),
            content: CGRect(x: 0, y: 0, width: 1_728, height: 1_080)
        )
        let width = 1_728 * (1 + Self.tolerance)
        let incoming = try geometry(
            surface: CGSize(width: width, height: 1_080),
            content: CGRect(x: 0, y: 0, width: width, height: 1_080)
        )

        // The pair really does sit on the aspect boundary rather than well
        // inside it, which is the whole point of the case.
        let publishedAspect =
            published.surfaceSize.width / published.surfaceSize.height
        let incomingAspect =
            incoming.surfaceSize.width / incoming.surfaceSize.height
        XCTAssertEqual(
            abs(incomingAspect - publishedAspect) / publishedAspect,
            Self.tolerance,
            accuracy: Self.tolerance * 1e-3
        )
        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: incoming
            ),
            .layoutEquivalent
        )
        XCTAssertLessThan(
            try renderedDelta(
                published: published,
                incoming: incoming,
                crop: Self.tightestCrop,
                destination: Self.stageDestination
            ),
            0.5
        )
    }

    func testWorstCaseAdmittedErrorStaysWithinTheDocumentedBound() throws {
        // Four content edges and the surface aspect are admitted on five
        // independent budgets, so the error the predicate can really admit is
        // the one that spends all of them at once and in the directions that
        // compound. A single-edge shift on a surface whose aspect ties with
        // the destination measures a best case instead, which is what the
        // published bound must not be derived from.
        let fullContent = try geometry(
            surface: CGSize(width: 1_728, height: 1_080),
            content: CGRect(x: 0, y: 0, width: 1_728, height: 1_080)
        )
        // A surface the reconfiguration deadband can legitimately leave with a
        // small letterbox baked in, so the content occupies only part of each
        // axis and the tolerances are scaled rather than whole.
        let letterboxed = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: 48, y: 27, width: 864, height: 486)
        )
        let pairs = [
            (fullContent, try maximallyPerturbed(
                fullContent, minX: 0, maxX: -1, minY: 1, maxY: -1, aspect: 1
            )),
            (letterboxed, try maximallyPerturbed(
                letterboxed, minX: -1, maxX: -1, minY: -1, maxY: 1, aspect: -1
            ))
        ]

        for (published, incoming) in pairs {
            XCTAssertEqual(
                PresentationGeometryEquivalence.relation(
                    published: published,
                    incoming: incoming
                ),
                .layoutEquivalent
            )
            // The documented bound, at the crop it is documented for: under
            // half a point on the largest Stage destination, and still under
            // one point at the Audience export ceiling.
            XCTAssertLessThan(
                try renderedDelta(
                    published: published,
                    incoming: incoming,
                    crop: Self.tightestCrop,
                    destination: Self.stageDestination
                ),
                0.5
            )
            XCTAssertLessThan(
                try renderedDelta(
                    published: published,
                    incoming: incoming,
                    crop: Self.tightestCrop,
                    destination: Self.exportCeilingDestination
                ),
                1
            )
        }
    }

    func testShiftBeyondToleranceRequiresTransition() throws {
        let published = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: 0, y: 0, width: 960, height: 540)
        )
        let shift = Self.tolerance * 960 * 4
        let incoming = try geometry(
            surface: CGSize(width: 960, height: 540),
            content: CGRect(x: shift, y: 0, width: 960 - shift, height: 540)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: incoming
            ),
            .requiresTransition
        )

        // Every axis has to be rejected on its own budget. A vertical or
        // aspect allowance that was widened by orders of magnitude would
        // otherwise still satisfy every other rejection in this suite, because
        // those sit thousands of times outside their boundary.
        let verticalShift = Self.tolerance * 540 * 4
        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: published,
                incoming: try geometry(
                    surface: CGSize(width: 960, height: 540),
                    content: CGRect(
                        x: 0,
                        y: verticalShift,
                        width: 960,
                        height: 540 - verticalShift
                    )
                )
            ),
            .requiresTransition
        )

        let aspectPublished = try geometry(
            surface: CGSize(width: 1_728, height: 1_080),
            content: CGRect(x: 0, y: 0, width: 1_728, height: 1_080)
        )
        let aspectWidth = 1_728 * (1 + Self.tolerance * 4)
        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: aspectPublished,
                incoming: try geometry(
                    surface: CGSize(width: aspectWidth, height: 1_080),
                    content: CGRect(
                        x: 0, y: 0, width: aspectWidth, height: 1_080
                    )
                )
            ),
            .requiresTransition
        )

        // Half a surface point is a rejected shift, not an absorbed one: it
        // renders as tens of destination points at an aggressive crop.
        let wide = try geometry(
            surface: CGSize(width: 1_200, height: 800),
            content: CGRect(x: 0, y: 0, width: 1_200, height: 800)
        )
        let shifted = try geometry(
            surface: CGSize(width: 1_200, height: 800),
            content: CGRect(x: 0.5, y: 0, width: 1_199.5, height: 800)
        )

        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: wide,
                incoming: shifted
            ),
            .requiresTransition
        )
    }

    func testRelationIsReflexiveAndSymmetric() throws {
        var table = try proportionalPairs()
        table.append((
            try geometry(
                surface: CGSize(width: 640, height: 360),
                content: CGRect(x: 0, y: 0, width: 640, height: 360)
            ),
            try geometry(
                surface: CGSize(width: 640, height: 400),
                content: CGRect(x: 0, y: 0, width: 640, height: 400)
            )
        ))
        table.append((
            try geometry(
                surface: CGSize(width: 640, height: 360),
                content: CGRect(x: 0, y: 0, width: 640, height: 360)
            ),
            try geometry(
                surface: CGSize(width: 640, height: 360),
                content: CGRect(x: 0, y: 20, width: 640, height: 320)
            )
        ))
        table.append((
            try geometry(
                surface: CGSize(width: 960, height: 541),
                content: CGRect(x: 0, y: 0.5, width: 960, height: 540)
            ),
            try geometry(
                surface: CGSize(width: 800, height: 451),
                content: CGRect(x: 0, y: 0.5, width: 800, height: 450)
            )
        ))

        for (published, incoming) in table {
            XCTAssertEqual(
                PresentationGeometryEquivalence.relation(
                    published: published,
                    incoming: published
                ),
                .identical
            )
            XCTAssertEqual(
                PresentationGeometryEquivalence.relation(
                    published: incoming,
                    incoming: incoming
                ),
                .identical
            )
            // A jitter alternating between two values must not alternate
            // between hiding and not hiding.
            XCTAssertEqual(
                PresentationGeometryEquivalence.relation(
                    published: published,
                    incoming: incoming
                ),
                PresentationGeometryEquivalence.relation(
                    published: incoming,
                    incoming: published
                )
            )
        }
    }

    func testDegenerateInputFailsClosed() throws {
        // The failable initializer is the only way to build a geometry, so the
        // smallest content extent it accepts is the worst input the predicate
        // can ever see.
        let degenerate = try geometry(
            surface: CGSize(width: 1_000, height: 1_000),
            content: CGRect(x: 0, y: 0, width: 1e-9, height: 1e-9)
        )
        let unrelated = try geometry(
            surface: CGSize(width: 1_000, height: 1_000),
            content: CGRect(x: 0, y: 0, width: 1_000, height: 1_000)
        )

        XCTAssertNotEqual(
            PresentationGeometryEquivalence.relation(
                published: degenerate,
                incoming: unrelated
            ),
            .layoutEquivalent
        )
        XCTAssertNotEqual(
            PresentationGeometryEquivalence.relation(
                published: unrelated,
                incoming: degenerate
            ),
            .layoutEquivalent
        )

        let squashed = try geometry(
            surface: CGSize(width: 1_000, height: 996),
            content: CGRect(x: 0, y: 0, width: 1_000, height: 996)
        )
        XCTAssertEqual(
            PresentationGeometryEquivalence.relation(
                published: unrelated,
                incoming: squashed
            ),
            .requiresTransition
        )
    }

    private func proportionalPairs() throws -> [(
        SourcePresentationGeometry, SourcePresentationGeometry
    )] {
        [
            (
                try geometry(
                    surface: CGSize(width: 960, height: 540),
                    content: CGRect(x: 0, y: 0, width: 960, height: 540)
                ),
                try geometry(
                    surface: CGSize(width: 800, height: 450),
                    content: CGRect(x: 0, y: 0, width: 800, height: 450)
                )
            ),
            (
                try geometry(
                    surface: CGSize(width: 640, height: 360),
                    content: CGRect(x: 0, y: 0, width: 640, height: 360)
                ),
                try geometry(
                    surface: CGSize(width: 960, height: 540),
                    content: CGRect(x: 0, y: 0, width: 960, height: 540)
                )
            ),
            (
                try geometry(
                    surface: CGSize(width: 800, height: 600),
                    content: CGRect(x: 0, y: 40, width: 800, height: 520)
                ),
                try geometry(
                    surface: CGSize(width: 1_600, height: 1_200),
                    content: CGRect(x: 0, y: 80, width: 1_600, height: 1_040)
                )
            )
        ]
    }

    /// Builds the most perturbed geometry `relation` still admits against
    /// `published`, moving each normalized content edge and the surface aspect
    /// by the sign given, each by its own tolerance.
    ///
    /// Every perturbation stops one ten-thousandth short of its boundary,
    /// because the boundary itself is a floating-point tie: `relation`
    /// compares rounded quotients, so a pair built exactly on it is admitted
    /// or rejected by the last bit of a division rather than by the policy
    /// under test. A ten-thousandth is far tighter than any change to the
    /// policy this pins could hide behind.
    private func maximallyPerturbed(
        _ published: SourcePresentationGeometry,
        minX minXSign: CGFloat,
        maxX maxXSign: CGFloat,
        minY minYSign: CGFloat,
        maxY maxYSign: CGFloat,
        aspect aspectSign: CGFloat
    ) throws -> SourcePresentationGeometry {
        let surface = published.surfaceSize
        let content = published.contentRect
        let widthFraction = content.width / surface.width
        let heightFraction = content.height / surface.height
        let margin = Self.tolerance * 0.9999
        let horizontal = margin * widthFraction
        let vertical = margin * heightFraction
        let aspect = margin * min(1, widthFraction, heightFraction)

        let width = surface.width * (1 + aspectSign * aspect)
        let height = surface.height
        let lowerX = content.minX / surface.width + minXSign * horizontal
        let upperX = content.maxX / surface.width + maxXSign * horizontal
        let lowerY = content.minY / surface.height + minYSign * vertical
        let upperY = content.maxY / surface.height + maxYSign * vertical
        return try geometry(
            surface: CGSize(width: width, height: height),
            content: CGRect(
                x: lowerX * width,
                y: lowerY * height,
                width: (upperX - lowerX) * width,
                height: (upperY - lowerY) * height
            )
        )
    }

    /// The largest disagreement the two geometries produce in anything the
    /// committed layout is made of: every edge and extent of the projected
    /// source frame, and both mask edges on each axis multiplied by the frame
    /// extent that mask edge is scaled by.
    private func renderedDelta(
        published: SourcePresentationGeometry,
        incoming: SourcePresentationGeometry,
        crop: NormalizedSourceRect,
        destination: CGSize
    ) throws -> CGFloat {
        let publishedFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: published,
            sourceCrop: crop,
            destinationSize: destination
        ))
        let incomingFrame = try XCTUnwrap(SourceCropProjection.sourceFrame(
            presentation: incoming,
            sourceCrop: crop,
            destinationSize: destination
        ))
        let publishedMask = try XCTUnwrap(SourceCropProjection.surfaceCropRect(
            presentation: published,
            sourceCrop: crop
        ))
        let incomingMask = try XCTUnwrap(SourceCropProjection.surfaceCropRect(
            presentation: incoming,
            sourceCrop: crop
        ))

        return [
            abs(publishedFrame.minX - incomingFrame.minX),
            abs(publishedFrame.minY - incomingFrame.minY),
            abs(publishedFrame.width - incomingFrame.width),
            abs(publishedFrame.height - incomingFrame.height),
            abs(
                publishedMask.minX * publishedFrame.width -
                    incomingMask.minX * incomingFrame.width
            ),
            abs(
                publishedMask.maxX * publishedFrame.width -
                    incomingMask.maxX * incomingFrame.width
            ),
            abs(
                publishedMask.minY * publishedFrame.height -
                    incomingMask.minY * incomingFrame.height
            ),
            abs(
                publishedMask.maxY * publishedFrame.height -
                    incomingMask.maxY * incomingFrame.height
            )
        ].max() ?? 0
    }

    private func geometry(
        surface: CGSize,
        content: CGRect
    ) throws -> SourcePresentationGeometry {
        try XCTUnwrap(SourcePresentationGeometry(
            surfaceSize: surface,
            contentRect: content
        ))
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
        XCTAssertEqual(rect.minX, x, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(rect.minY, y, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(rect.width, width, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(
            rect.height, height, accuracy: 1e-6, file: file, line: line
        )
    }
}
