import CoreGraphics

/// How one incoming IOSurface geometry relates to the geometry AppKit has
/// already been told to lay out.
///
/// `layoutEquivalent` is deliberately distinct from `identical`: the two
/// geometries are not equal, but every rectangle the presentation layer
/// derives from them is the same rectangle, so the already committed layout
/// describes the incoming surface too.
public enum PresentationGeometryRelation: Equatable, Sendable {
    case identical
    case layoutEquivalent
    case requiresTransition
}

/// Decides whether a complete frame may be presented through the layout that
/// is already committed for the published geometry, or whether it must first
/// suppress the tile and wait for AppKit to acknowledge a new layout.
///
/// `AVSampleBufferDisplayLayer` presents an enqueued IOSurface outside
/// `CATransaction` control, so a surface may never be presented through a
/// layout that describes a different surface. The escape is that absolute
/// surface size cancels out of the crop projection:
/// ``SourceCropProjection/surfaceCropRect(presentation:sourceCrop:)`` divides
/// `contentRect` by `surfaceSize`, and the projected source frame multiplies
/// every output by `surfaceSize * min(destination / (surfaceSize * crop))`, so
/// only the surface aspect ratio and the normalized `contentRect` survive.
/// Two geometries that agree on those two things therefore produce the same
/// committed layout, whatever their pixel dimensions are.
///
/// That proof rests on exactly three properties of the presentation layer, and
/// this predicate must be re-derived if any of them changes:
/// `videoGravity = .resizeAspect` (SampleBufferRenderer.swift:144), the display
/// layer's frame being the host view's `bounds`
/// (SampleBufferRenderer.swift:1422, 1449, 1493), and the visible surface mask
/// being a normalized rectangle scaled by `bounds.size`
/// (SampleBufferRenderer.swift:1500-1520).
public enum PresentationGeometryEquivalence {
    /// The largest error this predicate may admit on any single measured
    /// quantity, expressed as a fraction of the destination extent rather than
    /// as a pixel count. A fraction does not silently degrade when a Stage
    /// window or an Audience export grows.
    ///
    /// The bound the predicate really offers is the compounded one, not this
    /// one: the four content-rect-relative edges and the surface aspect are
    /// each admitted up to their own tolerance, so the worst admitted pair
    /// spends several of these budgets at once rather than one. Measured at
    /// the tightest legal crop, that worst case renders as under half a point
    /// on a 4,096-point destination and under one point at the 7,680-point
    /// export ceiling (``StageSnapshotSize/maximumDimension``);
    /// `testWorstCaseAdmittedErrorStaysWithinTheDocumentedBound` measures both
    /// figures against pairs that spend every budget at once. The
    /// single-quantity value is deliberately a quarter of what those two
    /// figures alone would allow, because it is the compounded case, not the
    /// single-edge one, that has to satisfy them.
    public static let maximumDestinationFraction: CGFloat = 1.0 / 32_768.0

    /// The tightest crop ``NormalizedSourceRect`` can hold. The projection
    /// magnifies a normalized surface error by `1 / cropFraction`, and the
    /// render queue legitimately cannot know any consumer's crop — the Stage
    /// uses the applied crop while the Crop editor shows the source uncropped
    /// — so the bound is taken at the worst legal crop instead of being
    /// plumbed across targets.
    public static let minimumCropFraction: CGFloat =
        CGFloat(NormalizedSourceRect.absoluteMinimumDimension)

    /// Classifies `incoming` against the geometry currently published to
    /// AppKit.
    ///
    /// A nil `published` geometry always requires a transition: it is the
    /// fail-closed state every lifecycle boundary writes, and the reveal that
    /// follows is what arms the Audience PNG acknowledgement, so a frame may
    /// never slip past it. Anything that is not exactly equal is admitted
    /// only when all four content-rect-relative normalized edges and the
    /// surface aspect match within a tolerance whose compounded worst case, at
    /// every legal crop, renders below half a point on a 4,096-point
    /// destination and below one point at the 7,680-point export ceiling.
    public static func relation(
        published: SourcePresentationGeometry?,
        incoming: SourcePresentationGeometry
    ) -> PresentationGeometryRelation {
        guard let published else { return .requiresTransition }
        if published == incoming { return .identical }

        let publishedSurface = published.surfaceSize
        let incomingSurface = incoming.surfaceSize
        guard publishedSurface.width.isFinite,
              publishedSurface.height.isFinite,
              incomingSurface.width.isFinite,
              incomingSurface.height.isFinite,
              publishedSurface.width > 0,
              publishedSurface.height > 0,
              incomingSurface.width > 0,
              incomingSurface.height > 0 else { return .requiresTransition }

        // Every admitted error is measured against the published content
        // extent, because that extent is what the projection divides the
        // destination by. A degenerate extent would make the comparison
        // meaningless, so it fails closed rather than dividing by it.
        let publishedWidthFraction =
            published.contentRect.width / publishedSurface.width
        let publishedHeightFraction =
            published.contentRect.height / publishedSurface.height
        guard publishedWidthFraction.isFinite,
              publishedHeightFraction.isFinite,
              publishedWidthFraction > 0,
              publishedHeightFraction > 0 else { return .requiresTransition }

        // The tolerance is scaled by the published content fraction instead of
        // the deltas being divided by it, so an admitted comparison performs no
        // division by a quantity that is allowed to approach zero. This runs on
        // the render queue for every frame, so it also allocates nothing.
        let tolerance = maximumDestinationFraction * minimumCropFraction
        let horizontalTolerance = tolerance * publishedWidthFraction
        let verticalTolerance = tolerance * publishedHeightFraction
        guard edgesMatch(
            incoming.contentRect.minX, incoming.contentRect.maxX,
            over: incomingSurface.width,
            published: published.contentRect.minX, published.contentRect.maxX,
            over: publishedSurface.width,
            tolerance: horizontalTolerance
        ), edgesMatch(
            incoming.contentRect.minY, incoming.contentRect.maxY,
            over: incomingSurface.height,
            published: published.contentRect.minY, published.contentRect.maxY,
            over: publishedSurface.height,
            tolerance: verticalTolerance
        ) else { return .requiresTransition }

        // The surface aspect is the only other quantity the committed layout
        // depends on. Comparing it relatively, and scaling the allowance by
        // the smaller content fraction, keeps the same destination-point bound
        // when the content occupies only part of the surface.
        let publishedAspect = publishedSurface.width / publishedSurface.height
        let incomingAspect = incomingSurface.width / incomingSurface.height
        guard publishedAspect.isFinite,
              incomingAspect.isFinite,
              publishedAspect > 0 else { return .requiresTransition }
        let aspectDelta = abs(incomingAspect - publishedAspect) / publishedAspect
        let aspectTolerance = tolerance * min(
            1, publishedWidthFraction, publishedHeightFraction
        )
        guard aspectDelta.isFinite,
              aspectDelta <= aspectTolerance else { return .requiresTransition }

        return .layoutEquivalent
    }

    /// Compares both normalized content edges on one axis. Both are required
    /// because a surface can keep one edge while moving the other, which moves
    /// the content extent and therefore the projected scale.
    private static func edgesMatch(
        _ incomingLower: CGFloat,
        _ incomingUpper: CGFloat,
        over incomingExtent: CGFloat,
        published publishedLower: CGFloat,
        _ publishedUpper: CGFloat,
        over publishedExtent: CGFloat,
        tolerance: CGFloat
    ) -> Bool {
        let lowerDelta = abs(
            incomingLower / incomingExtent - publishedLower / publishedExtent
        )
        let upperDelta = abs(
            incomingUpper / incomingExtent - publishedUpper / publishedExtent
        )
        return lowerDelta.isFinite && lowerDelta <= tolerance &&
            upperDelta.isFinite && upperDelta <= tolerance
    }
}
