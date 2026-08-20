import CoreGraphics
import Foundation

/// A top-left-origin point in the shared Stage canvas.
///
/// Keeping ink in normalized Stage coordinates lets the same document render
/// over both the private preview and the public Stage at any output size.
public struct StageAnnotationPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let pressure: Double

    public init(x: Double, y: Double, pressure: Double = 1) {
        self.x = Self.unitValue(x)
        self.y = Self.unitValue(y)
        self.pressure = Self.unitValue(pressure, fallback: 1)
    }

    public init?(point: CGPoint, in canvasSize: CGSize, pressure: Double = 1) {
        guard point.x.isFinite,
              point.y.isFinite,
              canvasSize.width.isFinite,
              canvasSize.height.isFinite,
              canvasSize.width > 0,
              canvasSize.height > 0 else { return nil }
        self.init(
            x: Double(point.x / canvasSize.width),
            y: Double(point.y / canvasSize.height),
            pressure: pressure
        )
    }

    public func point(in canvasSize: CGSize) -> CGPoint? {
        guard canvasSize.width.isFinite,
              canvasSize.height.isFinite,
              canvasSize.width > 0,
              canvasSize.height > 0 else { return nil }
        return CGPoint(
            x: canvasSize.width * CGFloat(x),
            y: canvasSize.height * CGFloat(y)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case x
        case y
        case pressure
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            x: try container.decode(Double.self, forKey: .x),
            y: try container.decode(Double.self, forKey: .y),
            pressure: try container.decodeIfPresent(Double.self, forKey: .pressure) ?? 1
        )
    }

    private static func unitValue(_ value: Double, fallback: Double = 0) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, 0), 1)
    }
}

/// Display-P3-independent sRGB components for one annotation stroke.
public struct StageInkColor: Codable, Equatable, Sendable {
    public static let red = StageInkColor(red: 1, green: 0.12, blue: 0.10)

    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.unitValue(red)
        self.green = Self.unitValue(green)
        self.blue = Self.unitValue(blue)
        self.alpha = Self.unitValue(alpha, fallback: 1)
    }

    private enum CodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case alpha
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            red: try container.decode(Double.self, forKey: .red),
            green: try container.decode(Double.self, forKey: .green),
            blue: try container.decode(Double.self, forKey: .blue),
            alpha: try container.decodeIfPresent(Double.self, forKey: .alpha) ?? 1
        )
    }

    private static func unitValue(_ value: Double, fallback: Double = 0) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, 0), 1)
    }
}

public struct StageInkStyle: Codable, Equatable, Sendable {
    public static let minimumNormalizedWidth = 0.0005
    public static let maximumNormalizedWidth = 0.10
    public static let defaultStyle = StageInkStyle(color: .red, normalizedWidth: 0.006)

    public let color: StageInkColor
    /// A fraction of the shorter Stage canvas dimension.
    public let normalizedWidth: Double

    public init(color: StageInkColor, normalizedWidth: Double) {
        self.color = color
        guard normalizedWidth.isFinite else {
            self.normalizedWidth = Self.defaultNormalizedWidth
            return
        }
        self.normalizedWidth = min(
            max(normalizedWidth, Self.minimumNormalizedWidth),
            Self.maximumNormalizedWidth
        )
    }

    public func lineWidth(in canvasSize: CGSize) -> CGFloat? {
        guard canvasSize.width.isFinite,
              canvasSize.height.isFinite,
              canvasSize.width > 0,
              canvasSize.height > 0 else { return nil }
        return min(canvasSize.width, canvasSize.height) * CGFloat(normalizedWidth)
    }

    private static let defaultNormalizedWidth = 0.006

    private enum CodingKeys: String, CodingKey {
        case color
        case normalizedWidth
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            color: try container.decode(StageInkColor.self, forKey: .color),
            normalizedWidth: try container.decode(Double.self, forKey: .normalizedWidth)
        )
    }
}

/// The mark-making behavior selected in the private Stage Workspace.
public enum StageInkTool: String, CaseIterable, Codable, Hashable, Sendable {
    case pen
    case highlighter
    case eraser

    public static let defaultTool = StageInkTool.pen

    /// Highlighter strokes remain translucent when copied or saved as an
    /// audience image; pen strokes are fully opaque. Eraser color is ignored
    /// by the renderer, but stays transparent for forward-safe serialization.
    public var opacity: Double {
        switch self {
        case .pen: 1
        case .highlighter: 0.36
        case .eraser: 0
        }
    }

    public var strokeKind: StageAnnotationStrokeKind {
        self == .eraser ? .eraser : .ink
    }
}

/// A small, presentation-oriented palette that remains legible over video,
/// slides, and both light and dark application content.
public enum StageInkColorPreset: String, CaseIterable, Codable, Hashable, Sendable {
    case red
    case yellow
    case green
    case blue
    case white

    public static let defaultPreset = StageInkColorPreset.red

    public var color: StageInkColor {
        switch self {
        case .red:
            .red
        case .yellow:
            StageInkColor(red: 1, green: 0.78, blue: 0.05)
        case .green:
            StageInkColor(red: 0.22, green: 0.88, blue: 0.46)
        case .blue:
            StageInkColor(red: 0.17, green: 0.72, blue: 1)
        case .white:
            StageInkColor(red: 1, green: 1, blue: 1)
        }
    }
}

/// The locally remembered drawing-tool selection. Annotation strokes are not
/// part of this value and remain memory-only for the current app session.
public struct StageInkPreferences: Codable, Equatable, Sendable {
    public static let minimumNormalizedWidth = 0.002
    public static let maximumNormalizedWidth = 0.03
    public static let minimumEraserNormalizedWidth = 0.008
    public static let maximumEraserNormalizedWidth = 0.08
    public static let defaultEraserNormalizedWidth = 0.03
    public static let defaultPreferences = StageInkPreferences(
        tool: .defaultTool,
        colorPreset: .defaultPreset,
        normalizedWidth: StageInkStyle.defaultStyle.normalizedWidth,
        eraserNormalizedWidth: defaultEraserNormalizedWidth
    )

    public let tool: StageInkTool
    public let colorPreset: StageInkColorPreset
    /// A fraction of the shorter Stage canvas dimension.
    public let normalizedWidth: Double
    /// The diameter of the vector eraser as a fraction of the shorter Stage
    /// canvas dimension. It is remembered independently from ink width.
    public let eraserNormalizedWidth: Double

    public init(
        tool: StageInkTool,
        colorPreset: StageInkColorPreset,
        normalizedWidth: Double,
        eraserNormalizedWidth: Double = Self.defaultEraserNormalizedWidth
    ) {
        self.tool = tool
        self.colorPreset = colorPreset
        if normalizedWidth.isFinite {
            self.normalizedWidth = min(
                max(normalizedWidth, Self.minimumNormalizedWidth),
                Self.maximumNormalizedWidth
            )
        } else {
            self.normalizedWidth = StageInkStyle.defaultStyle.normalizedWidth
        }
        if eraserNormalizedWidth.isFinite {
            self.eraserNormalizedWidth = min(
                max(eraserNormalizedWidth, Self.minimumEraserNormalizedWidth),
                Self.maximumEraserNormalizedWidth
            )
        } else {
            self.eraserNormalizedWidth = Self.defaultEraserNormalizedWidth
        }
    }

    public var style: StageInkStyle {
        let baseColor = colorPreset.color
        return StageInkStyle(
            color: StageInkColor(
                red: baseColor.red,
                green: baseColor.green,
                blue: baseColor.blue,
                alpha: tool.opacity
            ),
            normalizedWidth: tool == .eraser ? eraserNormalizedWidth : normalizedWidth
        )
    }

    private enum CodingKeys: String, CodingKey {
        case tool
        case colorPreset
        case normalizedWidth
        case eraserNormalizedWidth
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            tool: try container.decode(StageInkTool.self, forKey: .tool),
            colorPreset: try container.decode(StageInkColorPreset.self, forKey: .colorPreset),
            normalizedWidth: try container.decode(Double.self, forKey: .normalizedWidth),
            eraserNormalizedWidth: try container.decodeIfPresent(
                Double.self,
                forKey: .eraserNormalizedWidth
            ) ?? Self.defaultEraserNormalizedWidth
        )
    }
}

/// Whether a vector gesture adds visible ink or subtracts from earlier ink.
///
/// Eraser gestures are kept in document order instead of destructively
/// rewriting older strokes, so Undo can reveal exactly what the gesture erased.
public enum StageAnnotationStrokeKind: String, Codable, Equatable, Sendable {
    case ink
    case eraser
}

public struct StageAnnotationStroke: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: StageAnnotationStrokeKind
    public let style: StageInkStyle
    public private(set) var points: [StageAnnotationPoint]

    public init(
        id: UUID = UUID(),
        kind: StageAnnotationStrokeKind = .ink,
        style: StageInkStyle = .defaultStyle,
        points: [StageAnnotationPoint] = []
    ) {
        self.id = id
        self.kind = kind
        self.style = style
        self.points = points
    }

    /// Adds a point unless it is identical to the current endpoint.
    @discardableResult
    public mutating func append(_ point: StageAnnotationPoint) -> Bool {
        guard points.last != point else { return false }
        points.append(point)
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case style
        case points
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            kind: try container.decodeIfPresent(
                StageAnnotationStrokeKind.self,
                forKey: .kind
            ) ?? .ink,
            style: try container.decode(StageInkStyle.self, forKey: .style),
            points: try container.decode([StageAnnotationPoint].self, forKey: .points)
        )
    }
}

/// An in-memory annotation document. Stroke order is rendering order.
public struct StageAnnotationDocument: Codable, Equatable, Sendable {
    public private(set) var strokes: [StageAnnotationStroke]

    public var containsInkStroke: Bool {
        strokes.contains(where: { $0.kind == .ink })
    }

    public init(strokes: [StageAnnotationStroke] = []) {
        var seen = Set<UUID>()
        self.strokes = strokes.filter { seen.insert($0.id).inserted }
    }

    @discardableResult
    public mutating func beginStroke(
        id: UUID = UUID(),
        at point: StageAnnotationPoint,
        kind: StageAnnotationStrokeKind = .ink,
        style: StageInkStyle = .defaultStyle
    ) -> Bool {
        guard !strokes.contains(where: { $0.id == id }),
              kind == .ink || containsInkStroke else { return false }
        strokes.append(StageAnnotationStroke(
            id: id,
            kind: kind,
            style: style,
            points: [point]
        ))
        return true
    }

    @discardableResult
    public mutating func append(
        _ point: StageAnnotationPoint,
        to strokeID: UUID
    ) -> Bool {
        guard let index = strokes.firstIndex(where: { $0.id == strokeID }) else {
            return false
        }
        return strokes[index].append(point)
    }

    @discardableResult
    public mutating func removeStroke(_ strokeID: UUID) -> Bool {
        guard let index = strokes.firstIndex(where: { $0.id == strokeID }) else {
            return false
        }
        strokes.remove(at: index)
        return true
    }

    public mutating func removeAll() {
        strokes.removeAll(keepingCapacity: true)
    }

    private enum CodingKeys: String, CodingKey {
        case strokes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            strokes: try container.decode([StageAnnotationStroke].self, forKey: .strokes)
        )
    }
}
