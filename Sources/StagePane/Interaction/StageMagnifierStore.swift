import Combine
import CoreGraphics

/// Ephemeral attention state shared by the private canvas and audience Stage.
/// Kept separate from AppController so mouse movement only redraws the lens.
@MainActor
final class StageMagnifierStore: ObservableObject {
    @Published private(set) var position: CGPoint?
    @Published private(set) var focusRequest: UInt64 = 0
    @Published var magnification: Double = 2

    func move(to location: CGPoint, in size: CGSize) {
        guard size.width.isFinite, size.height.isFinite,
              size.width > 0, size.height > 0,
              location.x.isFinite, location.y.isFinite,
              CGRect(origin: .zero, size: size).contains(location) else {
            hide()
            return
        }
        position = CGPoint(x: location.x / size.width, y: location.y / size.height)
    }

    func move(byX x: CGFloat, y: CGFloat) {
        let previous = position ?? CGPoint(x: 0.5, y: 0.5)
        position = CGPoint(
            x: min(max(previous.x + x, 0), 1),
            y: min(max(previous.y + y, 0), 1)
        )
    }

    func center() {
        position = CGPoint(x: 0.5, y: 0.5)
        focusRequest &+= 1
    }

    func hide() {
        position = nil
    }
}
