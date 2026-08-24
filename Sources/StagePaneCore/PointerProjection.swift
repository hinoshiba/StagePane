import CoreGraphics

/// Geometry reported by ScreenCaptureKit for one complete video frame.
/// All rectangles use the framework's top-left-origin point coordinate space.
public struct PointerFrameGeometry: Equatable, Sendable {
    public let screenRect: CGRect
    public let contentRect: CGRect
    public let surfacePointSize: CGSize
    public let boundingRect: CGRect?

    public init(
        screenRect: CGRect,
        contentRect: CGRect,
        surfacePointSize: CGSize,
        boundingRect: CGRect? = nil
    ) {
        self.screenRect = screenRect
        self.contentRect = contentRect
        self.surfacePointSize = surfacePointSize
        self.boundingRect = boundingRect
    }

    /// Maps a Quartz global pointer location into a normalized IOSurface point.
    /// Returns nil whenever the pointer is outside the reported captured area.
    public func normalizedPosition(for globalPointer: CGPoint) -> CGPoint? {
        guard globalPointer.isFinite,
              screenRect.isFiniteAndNonEmpty,
              contentRect.isFiniteAndNonEmpty,
              surfacePointSize.isFiniteAndNonEmpty,
              screenRect.containsInclusive(globalPointer) else { return nil }

        let horizontal = (globalPointer.x - screenRect.minX) / screenRect.width
        let vertical = (globalPointer.y - screenRect.minY) / screenRect.height
        let surfacePoint = CGPoint(
            x: contentRect.minX + horizontal * contentRect.width,
            y: contentRect.minY + vertical * contentRect.height
        )

        if let boundingRect,
           boundingRect.isFiniteAndNonEmpty,
           !boundingRect.containsInclusive(surfacePoint) {
            return nil
        }

        let normalized = CGPoint(
            x: surfacePoint.x / surfacePointSize.width,
            y: surfacePoint.y / surfacePointSize.height
        )
        guard normalized.isFinite,
              (0 ... 1).contains(normalized.x),
              (0 ... 1).contains(normalized.y) else { return nil }
        return normalized
    }

    /// Inverts `normalizedPosition(for:)` using the exact geometry attached to
    /// the displayed complete frame. Positions in surface padding or a
    /// reported bounding gap are rejected instead of being sent elsewhere.
    public func globalPosition(for normalizedPosition: CGPoint) -> CGPoint? {
        guard normalizedPosition.isFinite,
              (0 ... 1).contains(normalizedPosition.x),
              (0 ... 1).contains(normalizedPosition.y),
              screenRect.isFiniteAndNonEmpty,
              contentRect.isFiniteAndNonEmpty,
              surfacePointSize.isFiniteAndNonEmpty else { return nil }

        let surfacePoint = CGPoint(
            x: normalizedPosition.x * surfacePointSize.width,
            y: normalizedPosition.y * surfacePointSize.height
        )
        guard contentRect.containsInclusive(surfacePoint) else { return nil }
        if let boundingRect,
           boundingRect.isFiniteAndNonEmpty,
           !boundingRect.containsInclusive(surfacePoint) {
            return nil
        }

        let horizontal = (surfacePoint.x - contentRect.minX) / contentRect.width
        let vertical = (surfacePoint.y - contentRect.minY) / contentRect.height
        guard horizontal.isFinite,
              vertical.isFinite,
              (0 ... 1).contains(horizontal),
              (0 ... 1).contains(vertical) else { return nil }
        return CGPoint(
            x: screenRect.minX + horizontal * screenRect.width,
            y: screenRect.minY + vertical * screenRect.height
        )
    }
}

public enum PointerProjection {
    /// Places a normalized, top-left-origin surface point into the same
    /// aspect-fit rectangle used by AVSampleBufferDisplayLayer.
    /// The result remains top-left-origin; AppKit flips Y once at its layer edge.
    public static func stagePoint(
        normalizedPosition: CGPoint,
        surfaceSize: CGSize,
        stageSize: CGSize
    ) -> CGPoint? {
        guard normalizedPosition.isFinite,
              (0 ... 1).contains(normalizedPosition.x),
              (0 ... 1).contains(normalizedPosition.y),
              surfaceSize.isFiniteAndNonEmpty,
              stageSize.isFiniteAndNonEmpty else { return nil }

        let scale = min(
            stageSize.width / surfaceSize.width,
            stageSize.height / surfaceSize.height
        )
        guard scale.isFinite, scale > 0 else { return nil }

        let fittedSize = CGSize(
            width: surfaceSize.width * scale,
            height: surfaceSize.height * scale
        )
        let origin = CGPoint(
            x: (stageSize.width - fittedSize.width) / 2,
            y: (stageSize.height - fittedSize.height) / 2
        )
        return CGPoint(
            x: origin.x + normalizedPosition.x * fittedSize.width,
            y: origin.y + normalizedPosition.y * fittedSize.height
        )
    }
}

private extension CGPoint {
    var isFinite: Bool { x.isFinite && y.isFinite }
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

    func containsInclusive(_ point: CGPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}
