import CoreGraphics

/// A cursor-following lens in the same top-left canvas coordinates as the
/// composition. Its size is proportional so Preview and Audience agree.
public struct StageMagnifierGeometry: Equatable, Sendable {
    public let canvasSize: CGSize
    public let magnification: CGFloat
    public let lensFrame: CGRect
    public let sampledStageRect: CGRect

    public init?(
        canvasSize: CGSize,
        normalizedPosition: CGPoint,
        magnification: Double = 2
    ) {
        guard canvasSize.width.isFinite, canvasSize.height.isFinite,
              canvasSize.width > 0, canvasSize.height > 0,
              normalizedPosition.x.isFinite, normalizedPosition.y.isFinite,
              (0...1).contains(normalizedPosition.x),
              (0...1).contains(normalizedPosition.y),
              magnification.isFinite, (1...8).contains(magnification) else {
            return nil
        }

        let diameter = min(canvasSize.width, canvasSize.height) * 0.36
        let radius = diameter / 2
        let focus = CGPoint(
            x: normalizedPosition.x * canvasSize.width,
            y: normalizedPosition.y * canvasSize.height
        )
        let center = CGPoint(
            x: min(max(focus.x, radius), canvasSize.width - radius),
            y: min(max(focus.y, radius), canvasSize.height - radius)
        )
        let sampledDiameter = diameter / CGFloat(magnification)
        self.canvasSize = canvasSize
        self.magnification = CGFloat(magnification)
        self.lensFrame = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: diameter,
            height: diameter
        )
        // Keep the inspected point at the lens center even when the lens itself
        // must move inward to remain visible at a canvas edge.
        self.sampledStageRect = CGRect(
            x: focus.x - sampledDiameter / 2,
            y: focus.y - sampledDiameter / 2,
            width: sampledDiameter,
            height: sampledDiameter
        )
    }

    /// Projects only pixels visible in the tile, its selected crop, and the
    /// inspected region. Empty aspect-fit margins never expose excluded pixels.
    public func sourceProjection(
        presentation: SourcePresentationGeometry,
        sourceCrop: NormalizedSourceRect,
        destinationFrame: CGRect
    ) -> StageMagnifierSourceProjection? {
        guard destinationFrame.minX.isFinite, destinationFrame.minY.isFinite,
              let sourceFrame = SourceCropProjection.sourceFrame(
                presentation: presentation,
                sourceCrop: sourceCrop,
                destinationSize: destinationFrame.size
              ), let surfaceCrop = SourceCropProjection.surfaceCropRect(
                presentation: presentation,
                sourceCrop: sourceCrop
              ), let localVisibleFrame = SourceCropProjection.visibleSurfaceFrame(
                surfaceCrop: surfaceCrop,
                surfaceSize: sourceFrame.size
              ) else { return nil }

        let stageSourceFrame = sourceFrame.offsetBy(
            dx: destinationFrame.minX,
            dy: destinationFrame.minY
        )
        let visibleFrame = localVisibleFrame.offsetBy(
            dx: stageSourceFrame.minX,
            dy: stageSourceFrame.minY
        )
        let intersection = visibleFrame
            .intersection(destinationFrame)
            .intersection(CGRect(origin: .zero, size: canvasSize))
            .intersection(sampledStageRect)
        guard !intersection.isNull, !intersection.isEmpty else { return nil }

        return StageMagnifierSourceProjection(
            normalizedSurfaceRect: CGRect(
                x: (intersection.minX - stageSourceFrame.minX) / sourceFrame.width,
                y: (intersection.minY - stageSourceFrame.minY) / sourceFrame.height,
                width: intersection.width / sourceFrame.width,
                height: intersection.height / sourceFrame.height
            ),
            lensRect: CGRect(
                x: (intersection.minX - sampledStageRect.minX) * magnification,
                y: (intersection.minY - sampledStageRect.minY) * magnification,
                width: intersection.width * magnification,
                height: intersection.height * magnification
            )
        )
    }
}

public struct StageMagnifierSourceProjection: Equatable, Sendable {
    /// Top-left-origin crop in the complete accepted capture surface.
    public let normalizedSurfaceRect: CGRect
    /// Top-left-origin destination inside the circular lens's square bounds.
    public let lensRect: CGRect
}
