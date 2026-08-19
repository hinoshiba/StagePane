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

    @Published private(set) var document = StageAnnotationDocument()

    private var activeStrokeID: UUID?
    private var lastCanvasPoint: CGPoint?
    private var totalPointCount = 0

    var isEmpty: Bool { document.strokes.isEmpty }
    var canUndo: Bool { !document.strokes.isEmpty }

    func beginStroke(at location: CGPoint, canvasSize: CGSize) {
        endStroke()
        while document.strokes.count >= Self.maximumStrokes ||
                totalPointCount >= Self.maximumTotalPoints,
              let oldestStroke = document.strokes.first {
            totalPointCount = max(0, totalPointCount - oldestStroke.points.count)
            _ = document.removeStroke(oldestStroke.id)
        }
        let strokeID = UUID()
        guard let point = StageAnnotationPoint(point: location, in: canvasSize) else { return }
        guard document.beginStroke(id: strokeID, at: point) else { return }
        totalPointCount += 1
        activeStrokeID = strokeID
        lastCanvasPoint = location
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
        }
    }

    func removeAll() {
        endStroke()
        document.removeAll()
        totalPointCount = 0
    }
}

/// Read-only vector ink shared by the private preview and public Stage.
struct StageAnnotationOverlay: View {
    @ObservedObject var store: StageAnnotationStore

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            for stroke in store.document.strokes {
                guard let lineWidth = stroke.style.lineWidth(in: size),
                      let firstPoint = stroke.points.first?.point(in: size) else { continue }
                let color = Color(
                    red: stroke.style.color.red,
                    green: stroke.style.color.green,
                    blue: stroke.style.color.blue,
                    opacity: stroke.style.color.alpha
                )

                if stroke.points.count == 1 {
                    let radius = lineWidth / 2
                    context.fill(
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
                context.stroke(
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
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
