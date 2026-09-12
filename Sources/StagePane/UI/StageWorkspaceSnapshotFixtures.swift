import StagePaneCore
import SwiftUI

/// Deterministic, privacy-safe content used only by the explicit `--snapshot`
/// export path. Production Workspace instances never receive a fixture.
enum StageWorkspaceSnapshotFixture: Sendable {
    case arrange
    case draw
    case sources

    var sourceCount: Int { 3 }

    // The legacy sources export now shows the same combined workspace.
    var hasCanvasComposition: Bool { true }
}

private struct SnapshotSourcePresentation: Identifiable {
    let id: Int
    let title: String
    let symbol: String
    let isHidden: Bool
    let isSelected: Bool

    static var fixtures: [SnapshotSourcePresentation] {
        [
            SnapshotSourcePresentation(
                id: 1,
                title: L10n.text("プレゼン資料", "Presentation"),
                symbol: "macwindow",
                isHidden: false,
                isSelected: true
            ),
            SnapshotSourcePresentation(
                id: 2,
                title: L10n.text("デモアプリ", "Demo App"),
                symbol: "app.fill",
                isHidden: true,
                isSelected: false
            ),
            SnapshotSourcePresentation(
                id: 3,
                title: L10n.text("参考画面", "Reference Screen"),
                symbol: "display",
                isHidden: false,
                isSelected: false
            )
        ]
    }
}

struct SnapshotSourceRailList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(SnapshotSourcePresentation.fixtures) { source in
                SnapshotLayerRow(source: source)
            }

            Spacer(minLength: 8)

            Button(action: {}) {
                Label(L10n.text("ソースを追加", "Add Source"), systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button(action: {}) {
                Label(L10n.text("自動配置", "Auto Arrange"), systemImage: "square.grid.2x2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .accessibilityHidden(true)
    }
}

private struct SnapshotLayerRow: View {
    let source: SnapshotSourcePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: source.symbol)
                    .foregroundStyle(StagePanePalette.aquaReadable)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(source.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(source.isHidden
                        ? L10n.text("非表示・取得停止中", "Hidden · Capture paused")
                        : L10n.text("表示中", "Visible on Stage"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: source.isHidden ? "eye.slash" : "eye")
                    .foregroundStyle(source.isHidden ? Color.secondary : StagePanePalette.aquaReadable)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))

                Image(systemName: "ellipsis")
                    .frame(width: 22, height: 28)
            }

            if source.isSelected {
                HStack(spacing: 6) {
                    Button(action: {}) {
                        Image(systemName: "arrow.up").frame(width: 28, height: 25)
                    }
                    .disabled(true)
                    Button(action: {}) {
                        Image(systemName: "arrow.down").frame(width: 28, height: 25)
                    }
                    Spacer(minLength: 0)
                    Button(action: {}) {
                        Label(L10n.cropEditActionTitle(isCropped: false), systemImage: "crop")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(9)
        .background(
            source.isSelected ? StagePanePalette.aqua.opacity(0.10) : Color.white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(source.isSelected ? StagePanePalette.aquaReadable.opacity(0.65) : Color.white.opacity(0.07))
        }
    }
}

struct SnapshotStageComposition: View {
    let showsDrawing: Bool
    let theme: StageTheme
    let showsWatermark: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                StageBackground(theme: theme)

                SnapshotStageTile(
                    title: L10n.text("参考画面", "Reference Screen"),
                    symbol: "display",
                    style: .reference,
                    showsEditingChrome: !showsDrawing,
                    isPaused: false,
                    isSelected: false
                )
                .frame(
                    width: proxy.size.width * 0.36,
                    height: proxy.size.height * 0.34
                )
                .position(
                    x: proxy.size.width * 0.76,
                    y: proxy.size.height * 0.70
                )

                SnapshotStageTile(
                    title: L10n.text("デモアプリ", "Demo App"),
                    symbol: "app.fill",
                    style: .demo,
                    showsEditingChrome: !showsDrawing,
                    isPaused: true,
                    isSelected: false
                )
                .frame(
                    width: proxy.size.width * 0.32,
                    height: proxy.size.height * 0.38
                )
                .position(
                    x: proxy.size.width * 0.79,
                    y: proxy.size.height * 0.275
                )

                SnapshotStageTile(
                    title: L10n.text("プレゼン資料", "Presentation"),
                    symbol: "macwindow",
                    style: .presentation,
                    showsEditingChrome: !showsDrawing,
                    isPaused: false,
                    isSelected: true
                )
                .frame(
                    width: proxy.size.width * 0.60,
                    height: proxy.size.height * 0.78
                )
                .position(
                    x: proxy.size.width * 0.36,
                    y: proxy.size.height * 0.48
                )

                if showsDrawing {
                    SnapshotInkTraces()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .allowsHitTesting(false)
                } else {
                    SnapshotLaserPointer()
                        .position(
                            x: proxy.size.width * 0.49,
                            y: proxy.size.height * 0.36
                        )
                }

                if showsWatermark {
                    StageWatermark(
                        prefersDarkForeground: theme.prefersDarkForeground,
                        compact: true
                    )
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }
}

private enum SnapshotStageTileStyle {
    case presentation
    case demo
    case reference
}

private struct SnapshotStageTile: View {
    let title: String
    let symbol: String
    let style: SnapshotStageTileStyle
    let showsEditingChrome: Bool
    let isPaused: Bool
    let isSelected: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if !isPaused {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(tileBackground)
                    tileContent(size: proxy.size)
                }

                if showsEditingChrome && isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(
                            isPaused
                                ? Color.white.opacity(0.30)
                                : (isSelected ? StagePanePalette.aquaReadable : Color.white.opacity(0.42)),
                            style: StrokeStyle(
                                lineWidth: isSelected ? 2 : 1,
                                dash: isSelected ? [] : [5, 4]
                            )
                        )

                    Label(
                        isPaused
                            ? L10n.text("\(title)・一時停止", "\(title) · Paused")
                            : title,
                        systemImage: isPaused ? "pause.fill" : symbol
                    )
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .frame(minHeight: 20)
                        .background(Color.black.opacity(0.72), in: Capsule())
                        .padding(7)

                    if !isPaused {
                        Image(systemName: "crop")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 25, height: 25)
                            .background(StagePanePalette.indigo, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.90), lineWidth: 1))
                            .padding(5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }

                    if isSelected {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(StagePanePalette.aquaReadable, in: Circle())
                            .padding(5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
            }
            .shadow(color: .black.opacity(isPaused ? 0 : 0.28), radius: 8, y: 5)
        }
    }

    @ViewBuilder
    private func tileContent(size: CGSize) -> some View {
        switch style {
        case .presentation:
            VStack(alignment: .leading, spacing: size.height * 0.055) {
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(StagePanePalette.indigo)
                        .frame(width: size.width * 0.10, height: size.height * 0.07)
                    Spacer()
                    Text("STAGEPANE DEMO")
                        .font(.system(size: max(7, size.height * 0.032), weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.42))
                }
                Text(L10n.text("落ち着いて伝わる共有画面", "A calmer way to share"))
                    .font(.system(size: max(13, size.height * 0.095), weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.82))
                    .lineLimit(2)
                Text(L10n.text(
                    "見せたい内容を整えて、ひとつのStageへ。",
                    "Compose only what you need on one clean Stage."
                ))
                .font(.system(size: max(8, size.height * 0.043), weight: .medium))
                .foregroundStyle(Color.black.opacity(0.52))
                HStack(alignment: .bottom, spacing: size.width * 0.025) {
                    ForEach(Array([0.48, 0.72, 0.58, 0.88, 0.66].enumerated()), id: \.offset) { _, value in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [StagePanePalette.indigo, StagePanePalette.aquaReadable],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: size.height * value * 0.28)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .padding(size.height * 0.08)

        case .demo:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(StagePanePalette.coral).frame(width: 7, height: 7)
                    Circle().fill(Color.yellow.opacity(0.85)).frame(width: 7, height: 7)
                    Circle().fill(StagePanePalette.mintReadable).frame(width: 7, height: 7)
                    Spacer()
                }
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: size.height * 0.16)
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(StagePanePalette.indigo.opacity(0.58))
                    RoundedRectangle(cornerRadius: 5)
                        .fill(StagePanePalette.aqua.opacity(0.32))
                }
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.10))
                    .frame(height: size.height * 0.10)
            }
            .padding(size.height * 0.10)

        case .reference:
            VStack(alignment: .leading, spacing: size.height * 0.07) {
                Text(L10n.text("参考メモ", "REFERENCE"))
                    .font(.system(size: max(8, size.height * 0.08), weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.64))
                ForEach(0..<4, id: \.self) { index in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(index == 1 ? StagePanePalette.indigo : StagePanePalette.aquaReadable)
                            .frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black.opacity(index == 1 ? 0.28 : 0.15))
                            .frame(width: size.width * (index == 3 ? 0.52 : 0.72), height: 5)
                    }
                }
                Spacer()
            }
            .padding(size.height * 0.12)
        }
    }

    private var tileBackground: Color {
        switch style {
        case .presentation: Color(red: 0.94, green: 0.96, blue: 1.0)
        case .demo: Color(red: 0.08, green: 0.10, blue: 0.16)
        case .reference: Color(red: 0.91, green: 0.96, blue: 0.96)
        }
    }
}

private struct SnapshotLaserPointer: View {
    var body: some View {
        Circle()
            .fill(StagePanePalette.coral)
            .frame(width: 18, height: 18)
            .overlay(Circle().stroke(Color.white.opacity(0.86), lineWidth: 1.5))
            .shadow(color: StagePanePalette.coral.opacity(0.86), radius: 10)
            .accessibilityHidden(true)
    }
}

private struct SnapshotInkTraces: View {
    var body: some View {
        Canvas { context, size in
            var highlighter = Path()
            highlighter.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.62))
            highlighter.addCurve(
                to: CGPoint(x: size.width * 0.36, y: size.height * 0.59),
                control1: CGPoint(x: size.width * 0.20, y: size.height * 0.56),
                control2: CGPoint(x: size.width * 0.28, y: size.height * 0.64)
            )
            context.stroke(
                highlighter,
                with: .color(Color.yellow.opacity(0.34)),
                style: StrokeStyle(lineWidth: max(12, size.height * 0.045), lineCap: .round)
            )

            // A deliberate gap in the highlight is the partial-eraser result.
            var highlighterTail = Path()
            highlighterTail.move(to: CGPoint(x: size.width * 0.43, y: size.height * 0.59))
            highlighterTail.addCurve(
                to: CGPoint(x: size.width * 0.54, y: size.height * 0.55),
                control1: CGPoint(x: size.width * 0.46, y: size.height * 0.58),
                control2: CGPoint(x: size.width * 0.50, y: size.height * 0.56)
            )
            context.stroke(
                highlighterTail,
                with: .color(Color.yellow.opacity(0.34)),
                style: StrokeStyle(lineWidth: max(12, size.height * 0.045), lineCap: .round)
            )

            var pen = Path()
            pen.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.26))
            pen.addCurve(
                to: CGPoint(x: size.width * 0.48, y: size.height * 0.30),
                control1: CGPoint(x: size.width * 0.28, y: size.height * 0.17),
                control2: CGPoint(x: size.width * 0.38, y: size.height * 0.39)
            )
            context.stroke(
                pen,
                with: .color(StagePanePalette.coral),
                style: StrokeStyle(lineWidth: max(4, size.height * 0.010), lineCap: .round)
            )

            let circle = Path(
                ellipseIn: CGRect(
                    x: size.width * 0.69,
                    y: size.height * 0.55,
                    width: size.width * 0.22,
                    height: size.height * 0.24
                )
            )
            context.stroke(
                circle,
                with: .color(StagePanePalette.coral),
                style: StrokeStyle(lineWidth: max(3, size.height * 0.008), lineCap: .round)
            )
        }
        .accessibilityHidden(true)
    }
}
