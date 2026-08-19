import Foundation

/// An application-owned identifier that remains stable while a source is
/// moved, resized, encoded, or automatically rearranged.
public struct StageSourceID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A top-left-origin rectangle in a unit canvas.
///
/// Every value produced by this type is finite and contained by `0 ... 1`.
/// Width and height remain positive, even when malformed persisted input is
/// decoded. Layout operations apply their own, user-facing minimum size.
public struct NormalizedStageRect: Codable, Equatable, Sendable {
    public static let fullCanvas = NormalizedStageRect(x: 0, y: 0, width: 1, height: 1)

    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        minimumWidth: Double = 0,
        minimumHeight: Double = 0
    ) {
        let boundedMinimumWidth = Self.boundedMinimum(minimumWidth)
        let boundedMinimumHeight = Self.boundedMinimum(minimumHeight)
        let boundedWidth = Self.boundedDimension(width, minimum: boundedMinimumWidth)
        let boundedHeight = Self.boundedDimension(height, minimum: boundedMinimumHeight)

        self.width = boundedWidth
        self.height = boundedHeight
        self.x = Self.boundedOrigin(x, dimension: boundedWidth)
        self.y = Self.boundedOrigin(y, dimension: boundedHeight)
    }

    /// Applies a drag delta while retaining the tile's size and keeping it in
    /// the unit canvas.
    public func moved(byX deltaX: Double, y deltaY: Double) -> Self {
        return Self(
            x: x + Self.finiteOrZero(deltaX),
            y: y + Self.finiteOrZero(deltaY),
            width: width,
            height: height
        )
    }

    /// Clamps a proposed resize to the canvas and to the supplied minimums.
    /// The aspect ratio is intentionally unconstrained.
    public static func resized(
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        minimumWidth: Double,
        minimumHeight: Double
    ) -> Self {
        let boundedMinimumWidth = boundedMinimum(minimumWidth)
        let boundedMinimumHeight = boundedMinimum(minimumHeight)
        let boundedX = min(max(finiteOrZero(x), 0), 1 - boundedMinimumWidth)
        let boundedY = min(max(finiteOrZero(y), 0), 1 - boundedMinimumHeight)
        let boundedWidth = min(
            boundedDimension(width, minimum: boundedMinimumWidth),
            1 - boundedX
        )
        let boundedHeight = min(
            boundedDimension(height, minimum: boundedMinimumHeight),
            1 - boundedY
        )
        return Self(
            x: boundedX,
            y: boundedY,
            width: boundedWidth,
            height: boundedHeight,
            minimumWidth: boundedMinimumWidth,
            minimumHeight: boundedMinimumHeight
        )
    }

    private enum CodingKeys: String, CodingKey {
        case x
        case y
        case width
        case height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            x: try container.decode(Double.self, forKey: .x),
            y: try container.decode(Double.self, forKey: .y),
            width: try container.decode(Double.self, forKey: .width),
            height: try container.decode(Double.self, forKey: .height)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }

    private static func boundedMinimum(_ value: Double) -> Double {
        guard value.isFinite else { return Double.ulpOfOne }
        return min(max(value, Double.ulpOfOne), 1)
    }

    private static func boundedDimension(_ value: Double, minimum: Double) -> Double {
        guard value.isFinite else { return minimum }
        return min(max(value, minimum), 1)
    }

    private static func boundedOrigin(_ value: Double, dimension: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1 - dimension)
    }

    private static func finiteOrZero(_ value: Double) -> Double {
        value.isFinite ? value : 0
    }
}

public struct StageSourceLayout: Identifiable, Codable, Equatable, Sendable {
    public let id: StageSourceID
    public var frame: NormalizedStageRect

    public init(id: StageSourceID, frame: NormalizedStageRect) {
        self.id = id
        self.frame = frame
    }
}

/// A deterministic arrangement for the sources already present on a Stage.
///
/// Presets only change frames. Source identity and rendering order remain
/// untouched so selecting a quick layout never changes which source is on top.
public enum StageLayoutPreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case grid
    case sideBySide
    case stacked
    case pictureInPicture

    public var id: String { rawValue }
}

/// Ordered source tiles on a normalized stage canvas.
///
/// Ordering is explicit so rendering order and automatic placement are both
/// deterministic. Duplicate identifiers are ignored, retaining the first
/// occurrence.
public struct StageLayout: Codable, Equatable, Sendable {
    public static let defaultGap = 0.02
    public static let defaultMinimumDimension = 0.10

    public private(set) var sources: [StageSourceLayout]

    public init(sources: [StageSourceLayout] = []) {
        self.sources = Self.uniqueSources(sources)
    }

    public init(
        automaticallyArranging sourceIDs: [StageSourceID],
        gap: Double = StageLayout.defaultGap
    ) {
        let uniqueIDs = Self.uniqueIDs(sourceIDs)
        let frames = Self.automaticFrames(count: uniqueIDs.count, gap: gap)
        self.sources = zip(uniqueIDs, frames).map(StageSourceLayout.init)
    }

    public subscript(sourceID sourceID: StageSourceID) -> StageSourceLayout? {
        sources.first { $0.id == sourceID }
    }

    /// Adds a source and produces a fresh, even grid for all sources.
    @discardableResult
    public mutating func addSource(
        _ sourceID: StageSourceID,
        gap: Double = StageLayout.defaultGap
    ) -> Bool {
        guard self[sourceID: sourceID] == nil else { return false }
        let sourceIDs = sources.map(\.id) + [sourceID]
        self = Self(automaticallyArranging: sourceIDs, gap: gap)
        return true
    }

    /// Adds an explicitly positioned source without disturbing existing tiles.
    @discardableResult
    public mutating func addSource(
        _ sourceID: StageSourceID,
        frame: NormalizedStageRect
    ) -> Bool {
        guard self[sourceID: sourceID] == nil else { return false }
        sources.append(StageSourceLayout(id: sourceID, frame: frame))
        return true
    }

    /// Removes a source without moving the remaining tiles.
    @discardableResult
    public mutating func removeSource(_ sourceID: StageSourceID) -> Bool {
        guard let index = sources.firstIndex(where: { $0.id == sourceID }) else { return false }
        sources.remove(at: index)
        return true
    }

    /// Replaces current positions with the deterministic automatic grid while
    /// retaining source IDs and their order.
    public mutating func arrangeAutomatically(gap: Double = StageLayout.defaultGap) {
        apply(preset: .grid, gap: gap)
    }

    /// Applies a quick layout without replacing source values or changing
    /// their order. The presets are designed for StagePane's supported range
    /// of zero through four sources.
    public mutating func apply(
        preset: StageLayoutPreset,
        gap: Double = StageLayout.defaultGap
    ) {
        let frames = Self.frames(for: preset, sourceCount: sources.count, gap: gap)
        for index in sources.indices {
            sources[index].frame = frames[index]
        }
    }

    /// Returns the frames used by a quick layout in source-rendering order.
    public static func frames(
        for preset: StageLayoutPreset,
        sourceCount: Int,
        gap: Double = StageLayout.defaultGap
    ) -> [NormalizedStageRect] {
        switch preset {
        case .grid:
            automaticFrames(count: sourceCount, gap: gap)
        case .sideBySide:
            sideBySideFrames(count: sourceCount, gap: gap)
        case .stacked:
            stackedFrames(count: sourceCount, gap: gap)
        case .pictureInPicture:
            pictureInPictureFrames(count: sourceCount, gap: gap)
        }
    }

    /// Moves one tile by a normalized drag delta.
    @discardableResult
    public mutating func moveSource(
        _ sourceID: StageSourceID,
        byX deltaX: Double,
        y deltaY: Double
    ) -> Bool {
        guard let index = sources.firstIndex(where: { $0.id == sourceID }) else { return false }
        sources[index].frame = sources[index].frame.moved(byX: deltaX, y: deltaY)
        return true
    }

    /// Applies a proposed normalized frame, enforcing minimum dimensions and
    /// canvas bounds without constraining aspect ratio.
    @discardableResult
    public mutating func resizeSource(
        _ sourceID: StageSourceID,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        minimumWidth: Double = StageLayout.defaultMinimumDimension,
        minimumHeight: Double = StageLayout.defaultMinimumDimension
    ) -> Bool {
        guard let index = sources.firstIndex(where: { $0.id == sourceID }) else { return false }
        sources[index].frame = .resized(
            x: x,
            y: y,
            width: width,
            height: height,
            minimumWidth: minimumWidth,
            minimumHeight: minimumHeight
        )
        return true
    }

    /// Returns row-major, evenly spaced frames for a unit canvas.
    public static func automaticFrames(
        count: Int,
        gap: Double = StageLayout.defaultGap
    ) -> [NormalizedStageRect] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [.fullCanvas] }

        let columns = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        let largestAxisCount = max(columns, rows)
        let maximumGap = 0.5 / Double(largestAxisCount + 1)
        let actualGap = boundedGap(gap, maximum: maximumGap)
        let width = (1 - actualGap * Double(columns + 1)) / Double(columns)
        let height = (1 - actualGap * Double(rows + 1)) / Double(rows)

        return (0 ..< count).map { index in
            let column = index % columns
            let row = index / columns
            return NormalizedStageRect(
                x: actualGap + Double(column) * (width + actualGap),
                y: actualGap + Double(row) * (height + actualGap),
                width: width,
                height: height
            )
        }
    }

    private static func sideBySideFrames(
        count: Int,
        gap: Double
    ) -> [NormalizedStageRect] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [.fullCanvas] }

        let actualGap = boundedGap(gap, maximum: 0.5 / Double(count + 1))
        let width = (1 - actualGap * Double(count + 1)) / Double(count)
        let height = 1 - 2 * actualGap
        return (0 ..< count).map { index in
            NormalizedStageRect(
                x: actualGap + Double(index) * (width + actualGap),
                y: actualGap,
                width: width,
                height: height
            )
        }
    }

    private static func stackedFrames(
        count: Int,
        gap: Double
    ) -> [NormalizedStageRect] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [.fullCanvas] }

        let actualGap = boundedGap(gap, maximum: 0.5 / Double(count + 1))
        let width = 1 - 2 * actualGap
        let height = (1 - actualGap * Double(count + 1)) / Double(count)
        return (0 ..< count).map { index in
            NormalizedStageRect(
                x: actualGap,
                y: actualGap + Double(index) * (height + actualGap),
                width: width,
                height: height
            )
        }
    }

    private static func pictureInPictureFrames(
        count: Int,
        gap: Double
    ) -> [NormalizedStageRect] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [.fullCanvas] }

        // StagePane exposes at most four simultaneous sources. A grid remains
        // a safe deterministic recovery path for malformed future data.
        guard count <= 4 else { return automaticFrames(count: count, gap: gap) }

        let actualGap = boundedGap(gap, maximum: 0.08)
        let overlayWidth = 0.36
        let overlayHeight = 0.30
        let left = actualGap
        let right = 1 - actualGap - overlayWidth
        let top = actualGap
        let bottom = 1 - actualGap - overlayHeight
        let overlays = [
            NormalizedStageRect(
                x: right,
                y: bottom,
                width: overlayWidth,
                height: overlayHeight
            ),
            NormalizedStageRect(
                x: left,
                y: bottom,
                width: overlayWidth,
                height: overlayHeight
            ),
            NormalizedStageRect(
                x: right,
                y: top,
                width: overlayWidth,
                height: overlayHeight
            )
        ]
        return [.fullCanvas] + overlays.prefix(count - 1)
    }

    private static func boundedGap(_ gap: Double, maximum: Double) -> Double {
        let requestedGap = gap.isFinite ? max(gap, 0) : defaultGap
        return min(requestedGap, maximum)
    }

    /// A predictable initial placement that never moves existing sources.
    /// The first source fills the Stage; later sources arrive as editable
    /// picture-in-picture tiles at the remaining corners. Auto Arrange remains
    /// an explicit user action.
    public static func suggestedFrameForNewSource(
        occupiedFrames: [NormalizedStageRect]
    ) -> NormalizedStageRect {
        guard !occupiedFrames.isEmpty else { return .fullCanvas }
        let pictureInPictureFrames = [
            NormalizedStageRect(x: 0.52, y: 0.52, width: 0.46, height: 0.46),
            NormalizedStageRect(x: 0.02, y: 0.52, width: 0.46, height: 0.46),
            NormalizedStageRect(x: 0.52, y: 0.02, width: 0.46, height: 0.46),
            NormalizedStageRect(x: 0.02, y: 0.02, width: 0.46, height: 0.46)
        ]
        return pictureInPictureFrames.min { left, right in
            overlapArea(of: left, with: occupiedFrames) <
                overlapArea(of: right, with: occupiedFrames)
        } ?? pictureInPictureFrames[0]
    }

    private static func overlapArea(
        of candidate: NormalizedStageRect,
        with occupiedFrames: [NormalizedStageRect]
    ) -> Double {
        occupiedFrames.reduce(into: 0) { total, occupied in
            let overlapWidth = max(
                0,
                min(candidate.x + candidate.width, occupied.x + occupied.width) -
                    max(candidate.x, occupied.x)
            )
            let overlapHeight = max(
                0,
                min(candidate.y + candidate.height, occupied.y + occupied.height) -
                    max(candidate.y, occupied.y)
            )
            total += overlapWidth * overlapHeight
        }
    }

    private enum CodingKeys: String, CodingKey {
        case sources
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(sources: try container.decode([StageSourceLayout].self, forKey: .sources))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sources, forKey: .sources)
    }

    private static func uniqueSources(_ values: [StageSourceLayout]) -> [StageSourceLayout] {
        var seen = Set<StageSourceID>()
        return values.filter { seen.insert($0.id).inserted }
    }

    private static func uniqueIDs(_ values: [StageSourceID]) -> [StageSourceID] {
        var seen = Set<StageSourceID>()
        return values.filter { seen.insert($0).inserted }
    }
}
