import StagePaneCore
import SwiftUI

/// Owns the presentation ink for the current in-memory Stage session.
///
/// Strokes are deliberately not persisted. Both the private preview and the
/// public Stage observe the same normalized document, so changing either
/// window's size never changes where the ink appears.
@MainActor
final class StageAnnotationStore: ObservableObject {
    private static let maximumStrokes = 256
    private static let maximumPointsPerStroke = 4_096
    private static let maximumTotalPoints = 32_768
    private static let minimumPointDistance: CGFloat = 1.5
    private static let preferencesKey = "stage.inkPreferences"

    @Published private(set) var document = StageAnnotationDocument()
    @Published private(set) var preferences: StageInkPreferences
    @Published private(set) var isEraserAtCapacity = false

    private let defaults: UserDefaults
    private var activeStrokeID: UUID?
    private var lastCanvasPoint: CGPoint?
    private var totalPointCount = 0

    var isEmpty: Bool { document.strokes.isEmpty }
    var canUndo: Bool { !document.strokes.isEmpty }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.preferencesKey),
           let storedPreferences = try? JSONDecoder().decode(
               StageInkPreferences.self,
               from: data
           ) {
            preferences = storedPreferences
        } else {
            preferences = .defaultPreferences
        }
    }

    func selectTool(_ tool: StageInkTool) {
        updatePreferences(tool: tool)
    }

    func selectColor(_ colorPreset: StageInkColorPreset) {
        updatePreferences(colorPreset: colorPreset)
    }

    func setNormalizedWidth(_ normalizedWidth: Double) {
        updatePreferences(normalizedWidth: normalizedWidth)
    }

    func setEraserNormalizedWidth(_ normalizedWidth: Double) {
        updatePreferences(eraserNormalizedWidth: normalizedWidth)
    }

    @discardableResult
    func beginStroke(at location: CGPoint, canvasSize: CGSize) -> Bool {
        endStroke()
        if preferences.tool == .eraser {
            // Never evict the ink an eraser is meant to edit. At the hard
            // memory bound, ignore a new erase gesture rather than silently
            // changing the visible document before that gesture is recorded.
            guard document.containsInkStroke else { return false }
            guard document.strokes.count < Self.maximumStrokes,
                  totalPointCount < Self.maximumTotalPoints else {
                reportEraserCapacityIfNeeded()
                return false
            }
        } else {
            isEraserAtCapacity = false
            while document.strokes.count >= Self.maximumStrokes ||
                    totalPointCount >= Self.maximumTotalPoints,
                  let oldestStroke = document.strokes.first {
                totalPointCount = max(0, totalPointCount - oldestStroke.points.count)
                _ = document.removeStroke(oldestStroke.id)
            }
        }
        let strokeID = UUID()
        guard let point = StageAnnotationPoint(point: location, in: canvasSize) else {
            return false
        }
        guard document.beginStroke(
            id: strokeID,
            at: point,
            kind: preferences.tool.strokeKind,
            style: preferences.style
        ) else { return false }
        totalPointCount += 1
        activeStrokeID = strokeID
        lastCanvasPoint = location
        isEraserAtCapacity = false
        return true
    }

    func appendPoint(at location: CGPoint, canvasSize: CGSize) {
        guard let activeStrokeID,
              let stroke = document.strokes.last(where: { $0.id == activeStrokeID }),
              stroke.points.count < Self.maximumPointsPerStroke,
              totalPointCount < Self.maximumTotalPoints,
              let point = StageAnnotationPoint(point: location, in: canvasSize) else { return }
        if let lastCanvasPoint {
            let distance = hypot(
                location.x - lastCanvasPoint.x,
                location.y - lastCanvasPoint.y
            )
            guard distance >= Self.minimumPointDistance else { return }
        }
        if document.append(point, to: activeStrokeID) {
            totalPointCount += 1
            lastCanvasPoint = location
        }
    }

    func endStroke() {
        activeStrokeID = nil
        lastCanvasPoint = nil
    }

    func undo() {
        endStroke()
        guard let lastStroke = document.strokes.last else { return }
        if document.removeStroke(lastStroke.id) {
            totalPointCount = max(0, totalPointCount - lastStroke.points.count)
            isEraserAtCapacity = false
        }
    }

    func removeAll() {
        endStroke()
        document.removeAll()
        totalPointCount = 0
        isEraserAtCapacity = false
    }

    private func updatePreferences(
        tool: StageInkTool? = nil,
        colorPreset: StageInkColorPreset? = nil,
        normalizedWidth: Double? = nil,
        eraserNormalizedWidth: Double? = nil
    ) {
        endStroke()
        let updatedPreferences = StageInkPreferences(
            tool: tool ?? preferences.tool,
            colorPreset: colorPreset ?? preferences.colorPreset,
            normalizedWidth: normalizedWidth ?? preferences.normalizedWidth,
            eraserNormalizedWidth:
                eraserNormalizedWidth ?? preferences.eraserNormalizedWidth
        )
        guard updatedPreferences != preferences else { return }
        preferences = updatedPreferences
        if updatedPreferences.tool != .eraser {
            isEraserAtCapacity = false
        }
        if let data = try? JSONEncoder().encode(updatedPreferences) {
            defaults.set(data, forKey: Self.preferencesKey)
        }
    }

    private func reportEraserCapacityIfNeeded() {
        guard !isEraserAtCapacity else { return }
        isEraserAtCapacity = true
        AccessibilityNotification.Announcement(L10n.text(
            "手書きの操作上限です。取り消すか、すべて消してから続けてください。",
            "The drawing action limit was reached. Undo or clear the drawing to continue."
        )).post()
    }
}

/// Read-only vector ink shared by the private preview and public Stage.
struct StageAnnotationOverlay: View {
    @ObservedObject var store: StageAnnotationStore

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            // All annotation actions share one isolated layer. Destination-out
            // therefore subtracts only earlier ink in this document, never the
            // captured source, Stage background, watermark, or pointer.
            context.drawLayer { annotationLayer in
                for stroke in store.document.strokes {
                    guard let lineWidth = stroke.style.lineWidth(in: size),
                          let firstPoint = stroke.points.first?.point(in: size) else {
                        continue
                    }
                    var strokeContext = annotationLayer
                    let color: Color
                    switch stroke.kind {
                    case .ink:
                        strokeContext.blendMode = .normal
                        color = Color(
                            red: stroke.style.color.red,
                            green: stroke.style.color.green,
                            blue: stroke.style.color.blue,
                            opacity: stroke.style.color.alpha
                        )
                    case .eraser:
                        strokeContext.blendMode = .destinationOut
                        color = .white
                    }

                    if stroke.points.count == 1 {
                        let radius = lineWidth / 2
                        strokeContext.fill(
                            Path(ellipseIn: CGRect(
                                x: firstPoint.x - radius,
                                y: firstPoint.y - radius,
                                width: lineWidth,
                                height: lineWidth
                            )),
                            with: .color(color)
                        )
                        continue
                    }

                    var path = Path()
                    path.move(to: firstPoint)
                    for point in stroke.points.dropFirst() {
                        guard let renderedPoint = point.point(in: size) else { continue }
                        path.addLine(to: renderedPoint)
                    }
                    strokeContext.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
