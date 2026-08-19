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
        let scale = min(
            1,
            Double(boundedMaximumWidth) / sourceWidth,
            Double(boundedMaximumHeight) / sourceHeight,
            Double(hardMaximumDimension) / sourceWidth,
            Double(hardMaximumDimension) / sourceHeight
        )
        return Self(
            width: evenDimension(
                Int((sourceWidth * scale).rounded()),
                maximum: boundedMaximumWidth
            ),
            height: evenDimension(
                Int((sourceHeight * scale).rounded()),
                maximum: boundedMaximumHeight
            )
        )
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
}
