import CoreGraphics

/// Geometry for the exact IOSurface frame accepted by one presentation
/// renderer. `contentRect` is top-left-origin and expressed inside
/// `surfaceSize`; it can be inset while ScreenCaptureKit preserves aspect.
public struct SourcePresentationGeometry: Equatable, Sendable {
    public let surfaceSize: CGSize
    public let contentRect: CGRect

    public init?(surfaceSize: CGSize, contentRect: CGRect) {
        guard surfaceSize.isFiniteAndNonEmpty,
              contentRect.isFiniteAndNonEmpty else { return nil }

        let minX = max(0, min(contentRect.minX, surfaceSize.width))
        let minY = max(0, min(contentRect.minY, surfaceSize.height))
        let maxX = max(0, min(contentRect.maxX, surfaceSize.width))
        let maxY = max(0, min(contentRect.maxY, surfaceSize.height))
        guard maxX > minX, maxY > minY else { return nil }

        self.surfaceSize = surfaceSize
        self.contentRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}

/// Shared geometry for the live Stage layer, private crop editor, pointer, and
/// one-shot Audience snapshot paths.
///
/// Returned rectangles use a top-left origin. The caller performs the one Y
/// flip required at an AppKit layer boundary.
public enum SourceCropProjection {
    /// Returns the frame for the complete source image after its selected crop
    /// is aspect-fitted into `destinationSize`. The returned frame can extend
    /// beyond the destination; clipping it reveals exactly `sourceCrop`.
    public static func sourceFrame(
        sourceSize: CGSize,
        sourceCrop: NormalizedSourceRect,
        destinationSize: CGSize
    ) -> CGRect? {
        sourceFrame(
            sourceSize: sourceSize,
            cropRect: CGRect(
                x: sourceCrop.x,
                y: sourceCrop.y,
                width: sourceCrop.width,
                height: sourceCrop.height
            ),
            destinationSize: destinationSize
        )
    }

    /// Returns the complete accepted IOSurface frame after converting a crop
    /// from source-content coordinates through that frame's actual contentRect.
    public static func sourceFrame(
        presentation: SourcePresentationGeometry,
        sourceCrop: NormalizedSourceRect,
        destinationSize: CGSize
    ) -> CGRect? {
        guard let surfaceCrop = surfaceCropRect(
            presentation: presentation,
            sourceCrop: sourceCrop
        ) else { return nil }
        return sourceFrame(
            sourceSize: presentation.surfaceSize,
            cropRect: surfaceCrop,
            destinationSize: destinationSize
        )
    }

    /// Converts a source-content crop to a normalized IOSurface rectangle.
    /// This same rectangle can reject a laser whose center is outside the crop.
    public static func surfaceCropRect(
        presentation: SourcePresentationGeometry,
        sourceCrop: NormalizedSourceRect
    ) -> CGRect? {
        let content = presentation.contentRect
        let surface = presentation.surfaceSize
        let minX = (content.minX + content.width * CGFloat(sourceCrop.x)) /
            surface.width
        let minY = (content.minY + content.height * CGFloat(sourceCrop.y)) /
            surface.height
        let maxX = (content.minX + content.width * CGFloat(
            sourceCrop.x + sourceCrop.width
        )) / surface.width
        let maxY = (content.minY + content.height * CGFloat(
            sourceCrop.y + sourceCrop.height
        )) / surface.height
        guard minX.isFinite, minY.isFinite, maxX.isFinite, maxY.isFinite else {
            return nil
        }
        let boundedMinX = min(max(minX, 0), 1)
        let boundedMinY = min(max(minY, 0), 1)
        let boundedMaxX = min(max(maxX, 0), 1)
        let boundedMaxY = min(max(maxY, 0), 1)
        let crop = CGRect(
            x: boundedMinX,
            y: boundedMinY,
            width: boundedMaxX - boundedMinX,
            height: boundedMaxY - boundedMinY
        )
        guard crop.isFiniteAndNonEmpty else { return nil }
        return crop
    }

    /// Expands a normalized IOSurface crop into a concrete frame inside a
    /// complete rendered surface. The result keeps the top-left origin used by
    /// the rest of the projection API; AppKit callers perform the Y flip when
    /// installing it as a Core Animation mask.
    ///
    /// Masking the rendered surface to this frame is required when the crop's
    /// aspect ratio differs from its destination tile. Otherwise, pixels just
    /// outside the selected crop can remain visible in the aspect-fit margin.
    public static func visibleSurfaceFrame(
        surfaceCrop: CGRect,
        surfaceSize: CGSize
    ) -> CGRect? {
        guard surfaceSize.isFiniteAndNonEmpty,
              surfaceCrop.isFiniteAndNonEmpty else { return nil }

        let minX = min(max(surfaceCrop.minX, 0), 1)
        let minY = min(max(surfaceCrop.minY, 0), 1)
        let maxX = min(max(surfaceCrop.maxX, 0), 1)
        let maxY = min(max(surfaceCrop.maxY, 0), 1)
        guard maxX > minX, maxY > minY else { return nil }

        let frame = CGRect(
            x: surfaceSize.width * minX,
            y: surfaceSize.height * minY,
            width: surfaceSize.width * (maxX - minX),
            height: surfaceSize.height * (maxY - minY)
        )
        guard frame.isFiniteAndNonEmpty else { return nil }
        return frame
    }

    /// Locates a source-space crop over a full-source aspect-fit preview.
    public static func selectionFrame(
        sourceSize: CGSize,
        sourceCrop: NormalizedSourceRect,
        destinationSize: CGSize
    ) -> CGRect? {
        guard let fullSourceFrame = sourceFrame(
            sourceSize: sourceSize,
            sourceCrop: .fullSource,
            destinationSize: destinationSize
        ) else { return nil }

        return CGRect(
            x: fullSourceFrame.minX + fullSourceFrame.width * CGFloat(sourceCrop.x),
            y: fullSourceFrame.minY + fullSourceFrame.height * CGFloat(sourceCrop.y),
            width: fullSourceFrame.width * CGFloat(sourceCrop.width),
            height: fullSourceFrame.height * CGFloat(sourceCrop.height)
        )
    }

    private static func sourceFrame(
        sourceSize: CGSize,
        cropRect: CGRect,
        destinationSize: CGSize
    ) -> CGRect? {
        guard sourceSize.isFiniteAndNonEmpty,
              cropRect.isFiniteAndNonEmpty,
              destinationSize.isFiniteAndNonEmpty else { return nil }

        let croppedSize = CGSize(
            width: sourceSize.width * cropRect.width,
            height: sourceSize.height * cropRect.height
        )
        guard croppedSize.isFiniteAndNonEmpty else { return nil }

        let scale = min(
            destinationSize.width / croppedSize.width,
            destinationSize.height / croppedSize.height
        )
        guard scale.isFinite, scale > 0 else { return nil }

        let visibleSize = CGSize(
            width: croppedSize.width * scale,
            height: croppedSize.height * scale
        )
        let fullSourceSize = CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
        let frame = CGRect(
            x: (destinationSize.width - visibleSize.width) / 2 -
                sourceSize.width * cropRect.minX * scale,
            y: (destinationSize.height - visibleSize.height) / 2 -
                sourceSize.height * cropRect.minY * scale,
            width: fullSourceSize.width,
            height: fullSourceSize.height
        )
        guard frame.isFiniteAndNonEmpty else { return nil }
        return frame
    }
}

private extension CGSize {
    var isFiniteAndNonEmpty: Bool {
        width.isFinite && height.isFinite && width > 0 && height > 0
    }
}

private extension CGRect {
    var isFiniteAndNonEmpty: Bool {
        origin.x.isFinite && origin.y.isFinite && size.isFiniteAndNonEmpty
    }
}
