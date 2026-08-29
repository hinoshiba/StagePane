import Foundation

/// Native source geometry reconstructed from ScreenCaptureKit frame metadata.
///
/// `contentRect` is expressed in points in the output surface, while
/// `contentScale` describes the scale from the original source into that
/// surface. Dividing the two recovers the source's current point dimensions.
public struct CaptureSourceGeometry: Equatable, Sendable {
    public let pointWidth: Double
    public let pointHeight: Double
    public let pointPixelScale: Double

    public init?(
        surfaceContentPointWidth: Double,
        surfaceContentPointHeight: Double,
        contentScale: Double,
        pointPixelScale: Double
    ) {
        guard surfaceContentPointWidth.isFinite,
              surfaceContentPointHeight.isFinite,
              contentScale.isFinite,
              pointPixelScale.isFinite,
              surfaceContentPointWidth > 0,
              surfaceContentPointHeight > 0,
              contentScale > 0,
              pointPixelScale > 0 else { return nil }

        let pointWidth = surfaceContentPointWidth / contentScale
        let pointHeight = surfaceContentPointHeight / contentScale
        guard pointWidth.isFinite,
              pointHeight.isFinite,
              pointWidth > 0,
              pointHeight > 0 else { return nil }

        self.pointWidth = pointWidth
        self.pointHeight = pointHeight
        self.pointPixelScale = pointPixelScale
    }
}

/// Pixel dimensions for one source's IOSurface-backed capture output.
///
/// The result retains the source aspect ratio, never upscales past the source's
/// native pixel size, and fits inside the tile's pixel budget. Letterboxing is
/// therefore applied exactly once by the presentation layer, not baked into an
/// intermediate Stage-shaped capture surface.
public struct CaptureSurfaceSize: Equatable, Sendable {
    public static let defaultMaximumPixelCount = 3_840 * 2_160

    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public static func fitted(
        sourcePointWidth: Double,
        sourcePointHeight: Double,
        pointPixelScale: Double,
        maximumWidth: Int,
        maximumHeight: Int,
        hardMaximumDimension: Int = 3840
    ) -> Self {
        let boundedMaximumWidth = max(2, min(maximumWidth, hardMaximumDimension))
        let boundedMaximumHeight = max(2, min(maximumHeight, hardMaximumDimension))
        guard sourcePointWidth.isFinite,
              sourcePointHeight.isFinite,
              pointPixelScale.isFinite,
              sourcePointWidth > 0,
              sourcePointHeight > 0,
              pointPixelScale > 0 else {
            return Self(
                width: evenDimension(boundedMaximumWidth, maximum: boundedMaximumWidth),
                height: evenDimension(boundedMaximumHeight, maximum: boundedMaximumHeight)
            )
        }

        let sourceWidth = sourcePointWidth * pointPixelScale
        let sourceHeight = sourcePointHeight * pointPixelScale
        guard sourceWidth.isFinite,
              sourceHeight.isFinite,
              sourceWidth > 0,
              sourceHeight > 0 else {
            return Self(width: 2, height: 2)
        }
        let scale = min(
            1,
            Double(boundedMaximumWidth) / sourceWidth,
            Double(boundedMaximumHeight) / sourceHeight,
            Double(hardMaximumDimension) / sourceWidth,
            Double(hardMaximumDimension) / sourceHeight
        )
        return Self(
            width: evenDimension(
                safeRoundedDimension(sourceWidth * scale, maximum: boundedMaximumWidth),
                maximum: boundedMaximumWidth
            ),
            height: evenDimension(
                safeRoundedDimension(sourceHeight * scale, maximum: boundedMaximumHeight),
                maximum: boundedMaximumHeight
            )
        )
    }

    /// Budgets a full-source capture surface so the selected local crop has
    /// enough pixels for its Stage tile. The stream still contains the complete
    /// picker-approved source; crop geometry only raises the useful local
    /// resolution, bounded by native size, dimension, and total pixel caps.
    public static func fittedForVisibleRegion(
        sourcePointWidth: Double,
        sourcePointHeight: Double,
        pointPixelScale: Double,
        visibleRegion: NormalizedSourceRect,
        maximumVisibleWidth: Int,
        maximumVisibleHeight: Int,
        hardMaximumDimension: Int = 3_840,
        hardMaximumPixelCount: Int = CaptureSurfaceSize.defaultMaximumPixelCount
    ) -> Self {
        let requestedFullWidth = fullSurfaceBudget(
            visibleDimension: maximumVisibleWidth,
            cropFraction: visibleRegion.width,
            hardMaximumDimension: hardMaximumDimension
        )
        let requestedFullHeight = fullSurfaceBudget(
            visibleDimension: maximumVisibleHeight,
            cropFraction: visibleRegion.height,
            hardMaximumDimension: hardMaximumDimension
        )
        let fitted = fitted(
            sourcePointWidth: sourcePointWidth,
            sourcePointHeight: sourcePointHeight,
            pointPixelScale: pointPixelScale,
            maximumWidth: requestedFullWidth,
            maximumHeight: requestedFullHeight,
            hardMaximumDimension: hardMaximumDimension
        )
        return fitted.limitedToPixelCount(
            max(4, hardMaximumPixelCount),
            maximumWidth: requestedFullWidth,
            maximumHeight: requestedFullHeight
        )
    }

    public static func fittedForVisibleRegion(
        source: CaptureSourceGeometry,
        visibleRegion: NormalizedSourceRect,
        maximumVisibleWidth: Int,
        maximumVisibleHeight: Int,
        hardMaximumDimension: Int = 3_840,
        hardMaximumPixelCount: Int = CaptureSurfaceSize.defaultMaximumPixelCount
    ) -> Self {
        fittedForVisibleRegion(
            sourcePointWidth: source.pointWidth,
            sourcePointHeight: source.pointHeight,
            pointPixelScale: source.pointPixelScale,
            visibleRegion: visibleRegion,
            maximumVisibleWidth: maximumVisibleWidth,
            maximumVisibleHeight: maximumVisibleHeight,
            hardMaximumDimension: hardMaximumDimension,
            hardMaximumPixelCount: hardMaximumPixelCount
        )
    }

    private static func fullSurfaceBudget(
        visibleDimension: Int,
        cropFraction: Double,
        hardMaximumDimension: Int
    ) -> Int {
        let boundedVisibleDimension = max(2, min(visibleDimension, hardMaximumDimension))
        let safeFraction = min(
            max(cropFraction, NormalizedSourceRect.absoluteMinimumDimension),
            1
        )
        let requested = (Double(boundedVisibleDimension) / safeFraction).rounded(.up)
        guard requested.isFinite, requested > 0 else { return 2 }
        if requested >= Double(hardMaximumDimension) {
            return max(2, hardMaximumDimension)
        }
        return max(2, Int(requested))
    }

    private func limitedToPixelCount(
        _ maximumPixelCount: Int,
        maximumWidth: Int,
        maximumHeight: Int
    ) -> Self {
        guard width > maximumPixelCount / height else {
            return self
        }
        let pixelCount = Double(width) * Double(height)
        let scale = sqrt(Double(maximumPixelCount) / pixelCount)
        guard scale.isFinite, scale > 0 else { return Self(width: 2, height: 2) }
        var reducedWidth = Self.evenFloorDimension(
            Int((Double(width) * scale).rounded(.down)),
            maximum: maximumWidth
        )
        var reducedHeight = Self.evenFloorDimension(
            Int((Double(height) * scale).rounded(.down)),
            maximum: maximumHeight
        )

        // An extremely thin source can hit the mandatory two-pixel floor on
        // one axis after proportional scaling. Reduce the other axis again so
        // even those pathological aspect ratios honor the hard area cap.
        if reducedWidth > maximumPixelCount / reducedHeight {
            if reducedWidth >= reducedHeight {
                reducedWidth = Self.evenFloorDimension(
                    maximumPixelCount / reducedHeight,
                    maximum: min(maximumWidth, reducedWidth)
                )
            } else {
                reducedHeight = Self.evenFloorDimension(
                    maximumPixelCount / reducedWidth,
                    maximum: min(maximumHeight, reducedHeight)
                )
            }
        }
        return Self(width: reducedWidth, height: reducedHeight)
    }

    public static func fitted(
        source: CaptureSourceGeometry,
        maximumWidth: Int,
        maximumHeight: Int,
        hardMaximumDimension: Int = 3840
    ) -> Self {
        fitted(
            sourcePointWidth: source.pointWidth,
            sourcePointHeight: source.pointHeight,
            pointPixelScale: source.pointPixelScale,
            maximumWidth: maximumWidth,
            maximumHeight: maximumHeight,
            hardMaximumDimension: hardMaximumDimension
        )
    }

    private static func evenDimension(_ value: Int, maximum: Int) -> Int {
        let bounded = max(2, min(value, maximum))
        if bounded.isMultiple(of: 2) { return bounded }
        if bounded < maximum { return bounded + 1 }
        return max(2, bounded - 1)
    }

    private static func safeRoundedDimension(_ value: Double, maximum: Int) -> Int {
        guard value.isFinite, value > 0 else { return 2 }
        if value >= Double(maximum) { return maximum }
        return Int(value.rounded())
    }

    /// Rounds downward so reducing an already over-budget surface can never
    /// exceed the requested total pixel cap by rounding either side upward.
    private static func evenFloorDimension(_ value: Int, maximum: Int) -> Int {
        let bounded = max(2, min(value, maximum))
        if bounded.isMultiple(of: 2) { return bounded }
        return max(2, bounded - 1)
    }
}
