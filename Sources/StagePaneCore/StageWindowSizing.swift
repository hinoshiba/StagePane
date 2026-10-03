import CoreGraphics
import Foundation

/// Content sizes for the visible share window, expressed in points.
///
/// Pixel-to-point conversion belongs to the window's backing store. These
/// rules only choose a size after the caller has made that conversion; they
/// do not describe the resolution transmitted by another application.
public enum StageWindowSizing {
    /// Centers a canvas of the requested shape inside its host without
    /// stretching either axis. Full-screen matte belongs to the host, rather
    /// than to the audience canvas exported at the preset's pixel dimensions.
    public static func fittedCanvasRect(
        in bounds: CGRect,
        aspectRatio: Double
    ) -> CGRect? {
        guard isValid(bounds.size),
              bounds.origin.x.isFinite,
              bounds.origin.y.isFinite,
              bounds.maxX.isFinite,
              bounds.maxY.isFinite,
              aspectRatio.isFinite,
              aspectRatio > 0 else { return nil }

        let height = min(bounds.height, bounds.width / aspectRatio)
        let size = CGSize(width: min(bounds.width, height * aspectRatio), height: height)
        guard isValid(size) else { return nil }
        return CGRect(
            x: bounds.minX + (bounds.width - size.width) / 2,
            y: bounds.minY + (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    public static func minimumContentSize(for preset: StagePreset) -> CGSize {
        let longestSide = 480.0
        if preset.aspectRatio >= 1 {
            return CGSize(width: longestSide, height: longestSide / preset.aspectRatio)
        }
        return CGSize(width: longestSide * preset.aspectRatio, height: longestSide)
    }

    public static func suggestedContentSize(for preset: StagePreset) -> CGSize {
        let suggested = preset.suggestedPointSize
        let minimum = minimumContentSize(for: preset)
        let scale = max(
            1,
            minimum.width / suggested.width,
            minimum.height / suggested.height
        )
        return CGSize(width: suggested.width * scale, height: suggested.height * scale)
    }

    /// Enlarges toward a target while retaining the Stage shape and fitting
    /// the screen's available content area. Existing user dimensions are never
    /// reduced, including when a display change leaves the window oversized.
    /// A nil result means no enlargement can satisfy all of those conditions.
    public static func enlargedContentSize(
        current: CGSize,
        target: CGSize,
        available: CGSize,
        aspectRatio: Double
    ) -> CGSize? {
        guard isValid(current),
              isValid(target),
              isValid(available),
              aspectRatio.isFinite,
              aspectRatio > 0,
              current.width <= available.width,
              current.height <= available.height else { return nil }

        let maximumWidth = min(target.width, available.width)
        let maximumHeight = min(target.height, available.height)
        let widthAtMaximumHeight = maximumHeight * aspectRatio
        let result: CGSize
        if widthAtMaximumHeight < maximumWidth {
            result = CGSize(width: widthAtMaximumHeight, height: maximumHeight)
        } else {
            result = CGSize(width: maximumWidth, height: maximumWidth / aspectRatio)
        }

        guard isValid(result),
              result.width <= maximumWidth,
              result.height <= maximumHeight,
              result.width >= current.width,
              result.height >= current.height,
              result.width > current.width || result.height > current.height else {
            return nil
        }
        return result
    }

    private static func isValid(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0
    }
}
