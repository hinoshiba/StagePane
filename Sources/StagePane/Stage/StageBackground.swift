import StagePaneCore
import SwiftUI

struct StageBackground: View {
    let theme: StageTheme

    var body: some View {
        Group {
            switch theme {
            case .aurora:
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.035, green: 0.047, blue: 0.086),
                            Color(red: 0.075, green: 0.071, blue: 0.176),
                            Color(red: 0.020, green: 0.094, blue: 0.122)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [StagePanePalette.indigo.opacity(0.45), .clear],
                        center: UnitPoint(x: 0.18, y: 0.12),
                        startRadius: 10,
                        endRadius: 460
                    )
                    RadialGradient(
                        colors: [StagePanePalette.aqua.opacity(0.28), .clear],
                        center: UnitPoint(x: 0.85, y: 0.82),
                        startRadius: 10,
                        endRadius: 520
                    )
                }
            case .midnight:
                LinearGradient(
                    colors: [Color.black, StagePanePalette.ink, Color(red: 0.02, green: 0.03, blue: 0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .paper:
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.97, blue: 0.94), Color(red: 0.90, green: 0.93, blue: 0.97)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .studio:
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.17, blue: 0.19), Color(red: 0.055, green: 0.06, blue: 0.075)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

extension StageTheme {
    var prefersDarkForeground: Bool {
        self == .paper
    }
}
