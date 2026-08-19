import CoreGraphics

/// Determines what a pointer gesture in the private Stage preview means.
///
/// The modes are deliberately mutually exclusive: a drag must never both
/// rearrange a source and inject input into another process.
public enum StageInteractionMode: String, CaseIterable, Codable, Sendable {
    case arrange
    case control
    case annotate

    public var forwardsPointerInput: Bool {
        self == .control
    }

    public var recordsAnnotations: Bool {
        self == .annotate
    }
}

/// The geometry needed to inverse-project a preview point into one source.
/// Every coordinate uses a top-left origin.
public struct StageInteractionSource: Equatable, Sendable {
    public let id: StageSourceID
    public let stageFrame: NormalizedStageRect
    public let contentSize: CGSize

    public init(
        id: StageSourceID,
        stageFrame: NormalizedStageRect,
        contentSize: CGSize
    ) {
        self.id = id
        self.stageFrame = stageFrame
        self.contentSize = contentSize
    }
}

/// A unique hit in the visible, aspect-fitted content of a Stage source.
public struct StageInteractionHit: Equatable, Sendable {
    public let sourceID: StageSourceID
    public let normalizedSourcePoint: CGPoint

    public init(sourceID: StageSourceID, normalizedSourcePoint: CGPoint) {
        self.sourceID = sourceID
        self.normalizedSourcePoint = normalizedSourcePoint
    }
}

public enum StageInteractionProjection {
    /// Resolves the visible frontmost source. Sources are ordered back-to-front,
    /// matching `StageLayout`. A top tile's black aspect-fit padding occludes
    /// lower tiles, so a click in that padding is rejected rather than passed
    /// through to content the user cannot see.
    public static func frontmostHit(
        at stagePoint: CGPoint,
        stageSize: CGSize,
        sources: [StageInteractionSource]
    ) -> StageInteractionHit? {
        guard stagePoint.isFinite,
              stageSize.isFiniteAndNonEmpty else { return nil }

        for source in sources.reversed() {
            let tileRect = CGRect(
                x: stageSize.width * CGFloat(source.stageFrame.x),
                y: stageSize.height * CGFloat(source.stageFrame.y),
                width: stageSize.width * CGFloat(source.stageFrame.width),
                height: stageSize.height * CGFloat(source.stageFrame.height)
            )
            guard tileRect.isFiniteAndNonEmpty,
                  tileRect.containsInclusive(stagePoint) else { continue }
            guard let normalizedPoint = normalizedSourcePoint(
                for: stagePoint,
                stageSize: stageSize,
                sourceFrame: source.stageFrame,
                sourceContentSize: source.contentSize
            ) else { return nil }
            return StageInteractionHit(
                sourceID: source.id,
                normalizedSourcePoint: normalizedPoint
            )
        }
        return nil
    }

    /// Resolves a preview point only when exactly one source's visible content
    /// contains it. Overlapping tiles are rejected rather than choosing a
    /// destination from z-order, because input injection must never guess.
    public static func uniqueHit(
        at stagePoint: CGPoint,
        stageSize: CGSize,
        sources: [StageInteractionSource]
    ) -> StageInteractionHit? {
        guard stagePoint.isFinite,
              stageSize.isFiniteAndNonEmpty else { return nil }

        var resolvedHit: StageInteractionHit?
        for source in sources {
            guard let normalizedPoint = normalizedSourcePoint(
                for: stagePoint,
                stageSize: stageSize,
                sourceFrame: source.stageFrame,
                sourceContentSize: source.contentSize
            ) else { continue }
            guard resolvedHit == nil else { return nil }
            resolvedHit = StageInteractionHit(
                sourceID: source.id,
                normalizedSourcePoint: normalizedPoint
            )
        }
        return resolvedHit
    }

    /// Inverts the `.resizeAspect` projection used by the sample-buffer layer.
    /// Points in the tile's letterbox or pillarbox return nil.
    public static func normalizedSourcePoint(
        for stagePoint: CGPoint,
        stageSize: CGSize,
        sourceFrame: NormalizedStageRect,
        sourceContentSize: CGSize
    ) -> CGPoint? {
        guard stagePoint.isFinite,
              stageSize.isFiniteAndNonEmpty,
              sourceContentSize.isFiniteAndNonEmpty else { return nil }

        let tileRect = CGRect(
            x: stageSize.width * CGFloat(sourceFrame.x),
            y: stageSize.height * CGFloat(sourceFrame.y),
            width: stageSize.width * CGFloat(sourceFrame.width),
            height: stageSize.height * CGFloat(sourceFrame.height)
        )
        guard tileRect.isFiniteAndNonEmpty,
              tileRect.containsInclusive(stagePoint) else { return nil }

        let scale = min(
            tileRect.width / sourceContentSize.width,
            tileRect.height / sourceContentSize.height
        )
        guard scale.isFinite, scale > 0 else { return nil }

        let fittedSize = CGSize(
            width: sourceContentSize.width * scale,
            height: sourceContentSize.height * scale
        )
        let fittedRect = CGRect(
            x: tileRect.minX + (tileRect.width - fittedSize.width) / 2,
            y: tileRect.minY + (tileRect.height - fittedSize.height) / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
        guard fittedRect.containsInclusive(stagePoint) else { return nil }

        let point = CGPoint(
            x: (stagePoint.x - fittedRect.minX) / fittedRect.width,
            y: (stagePoint.y - fittedRect.minY) / fittedRect.height
        )
        guard point.isFinite,
              (0 ... 1).contains(point.x),
              (0 ... 1).contains(point.y) else { return nil }
        return point
    }

    /// Projects a normalized source point into the global top-left-origin
    /// rectangle reported by ScreenCaptureKit for that exact source window.
    public static func globalPoint(
        for normalizedSourcePoint: CGPoint,
        sourceGlobalFrame: CGRect
    ) -> CGPoint? {
        guard normalizedSourcePoint.isFinite,
              (0 ... 1).contains(normalizedSourcePoint.x),
              (0 ... 1).contains(normalizedSourcePoint.y),
              sourceGlobalFrame.isFiniteAndNonEmpty else { return nil }
        return CGPoint(
            x: sourceGlobalFrame.minX + normalizedSourcePoint.x * sourceGlobalFrame.width,
            y: sourceGlobalFrame.minY + normalizedSourcePoint.y * sourceGlobalFrame.height
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
