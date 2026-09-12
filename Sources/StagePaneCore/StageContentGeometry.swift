import CoreGraphics

/// Editing geometry for the visible source pixels in a Stage composition.
/// A layout tile may include empty aspect-fit margins; these helpers let the
/// user position and resize its content without those margins absorbing input.
public enum StageContentGeometry {
    /// Replaces a destination tile with its visible content bounds while
    /// preserving the displayed image's position and size.
    public static func frame(
        sourceSize: CGSize,
        sourceCrop: NormalizedSourceRect,
        layoutFrame: NormalizedStageRect,
        canvasSize: CGSize
    ) -> NormalizedStageRect? {
        guard isValid(canvasSize),
              let visibleFrame = SourceCropProjection.visibleContentFrame(
                sourceSize: sourceSize,
                sourceCrop: sourceCrop,
                destinationSize: CGSize(
                    width: canvasSize.width * CGFloat(layoutFrame.width),
                    height: canvasSize.height * CGFloat(layoutFrame.height)
                )
              ) else { return nil }

        let x = layoutFrame.x + Double(visibleFrame.minX / canvasSize.width)
        let y = layoutFrame.y + Double(visibleFrame.minY / canvasSize.height)
        let width = Double(visibleFrame.width / canvasSize.width)
        let height = Double(visibleFrame.height / canvasSize.height)
        guard x.isFinite, y.isFinite,
              width.isFinite, height.isFinite,
              width > 0, height > 0 else { return nil }
        return NormalizedStageRect(x: x, y: y, width: width, height: height)
    }

    /// Resizes from a fixed top-left corner, preserving the visible aspect
    /// ratio. Translation uses physical canvas coordinates so horizontal and
    /// vertical pointer movement have the same weight on any Stage preset.
    ///
    /// The minimum is an aspect-fit slot: the longer normalized dimension
    /// reaches it first, allowing narrow crops to retain their proportions.
    /// A source already below that minimum never grows merely by beginning an
    /// edit. Canvas edges limit both dimensions through one common scale.
    public static func resizedFrame(
        _ frame: NormalizedStageRect,
        translation: CGSize,
        canvasSize: CGSize,
        minimumDimension: Double = StageLayout.defaultMinimumDimension
    ) -> NormalizedStageRect? {
        guard isValid(canvasSize),
              translation.width.isFinite, translation.height.isFinite,
              minimumDimension.isFinite, minimumDimension >= 0 else { return nil }

        let width = Double(canvasSize.width) * frame.width
        let height = Double(canvasSize.height) * frame.height
        let longestSide = max(width, height)
        guard width.isFinite, height.isFinite,
              width > 0, height > 0 else { return nil }

        // Normalize the diagonal before projecting to avoid squaring very
        // large or small physical dimensions.
        let horizontal = width / longestSide
        let vertical = height / longestSide
        let deltaX = Double(translation.width) / longestSide
        let deltaY = Double(translation.height) / longestSide
        let requestedScale = 1 + (deltaX * horizontal + deltaY * vertical) /
            (horizontal * horizontal + vertical * vertical)
        guard requestedScale.isFinite else { return nil }

        let maximumScale = min(
            (1 - frame.x) / frame.width,
            (1 - frame.y) / frame.height
        )
        let minimum = min(minimumDimension, 1)
        let minimumScale = max(
            max(Double.ulpOfOne / frame.width, Double.ulpOfOne / frame.height),
            min(1, min(minimum / frame.width, minimum / frame.height))
        )
        let scale = min(max(requestedScale, minimumScale), maximumScale)
        guard scale.isFinite, scale > 0 else { return nil }
        if scale == 1 { return frame }

        return NormalizedStageRect(
            x: frame.x,
            y: frame.y,
            width: frame.width * scale,
            height: frame.height * scale
        )
    }

    private static func isValid(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite &&
            size.width > 0 && size.height > 0
    }
}
