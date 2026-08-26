import StagePaneCore
import SwiftUI

/// Deterministic, privacy-safe content used only by the explicit `--snapshot`
/// export path. Production Workspace instances never receive a fixture.
enum StageWorkspaceSnapshotFixture: Sendable {
    case arrange
    case draw

    var sourceCount: Int { 3 }

    var hasCanvasComposition: Bool { true }
}
private struct SnapshotSourcePresentation: Identifiable {
    let id: Int
    let title: String
    let symbol: String
    let isPaused: Bool
    let isFrontmost: Bool

    var statusTitle: String {
        if isPaused {
            return L10n.text("一時停止・最後のフレームを保持", "Paused · Last frame held")
        }
        return L10n.text("画面取得中", "Capture active")
    }

    var actionTitle: String {
        isPaused ? L10n.text("再開", "Resume") : L10n.text("一時停止", "Pause")
    }

    var statusColor: Color {
        isPaused ? Color.secondary : StagePanePalette.mintReadable
    }

    static var fixtures: [SnapshotSourcePresentation] {
        [
            SnapshotSourcePresentation(
                id: 1,
                title: L10n.text("プレゼン資料", "Presentation"),
                symbol: "macwindow",
                isPaused: false,
                isFrontmost: true
            ),
            SnapshotSourcePresentation(
                id: 2,
                title: L10n.text("デモアプリ", "Demo App"),
                symbol: "app.fill",
                isPaused: true,
                isFrontmost: false
            ),
            SnapshotSourcePresentation(
                id: 3,
                title: L10n.text("参考画面", "Reference Screen"),
                symbol: "display",
                isPaused: false,
                isFrontmost: false
            )
        ]
    }
}

struct SnapshotSourceRailList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(SnapshotSourcePresentation.fixtures) { source in
                HStack(spacing: 8) {
                    Image(systemName: source.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(source.isPaused ? Color.secondary : StagePanePalette.indigo)
                        .frame(width: 27, height: 27)
                        .background(
                            (source.isPaused ? Color.secondary : StagePanePalette.indigo)
                                .opacity(0.11),
                            in: RoundedRectangle(cornerRadius: 7)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(source.title)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                            if source.isFrontmost {
                                Image(systemName: "square.3.layers.3d.top.filled")
                                    .font(.system(size: 8))
                                    .foregroundStyle(StagePanePalette.aquaReadable)
                            }
                        }
                        Text(source.isPaused
                            ? L10n.text("一時停止", "Paused")
                            : L10n.text("取得中", "Active"))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(source.statusColor)
                    }

                    Spacer(minLength: 2)

                    VStack(alignment: .trailing, spacing: 3) {
                        Button(source.actionTitle, action: {})
                        Button(L10n.text("選び直す", "Replace"), action: {})
                        Button(role: .destructive, action: {}) {
                            Text(L10n.text("解除", "Remove"))
                        }
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            }

            Spacer(minLength: 8)

            Button(action: {}) {
                Label(L10n.text("ソースを追加", "Add Source"), systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())

            Button(action: {}) {
                Label(L10n.text("すべて停止", "Stop All"), systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .accessibilityHidden(true)
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
                    title: L10n.text("プレゼン資料", "Presentation"),
                    symbol: "macwindow",
                    style: .presentation,
                    showsEditingChrome: !showsDrawing,
                    isFrontmost: true
                )
                .frame(
                    width: proxy.size.width * 0.55,
                    height: proxy.size.height * 0.78
                )
                .position(
                    x: proxy.size.width * 0.335,
                    y: proxy.size.height * 0.48
                )

                SnapshotStageTile(
                    title: L10n.text("デモアプリ", "Demo App"),
                    symbol: "app.fill",
                    style: .demo,
                    showsEditingChrome: !showsDrawing,
                    isFrontmost: false
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
                    title: L10n.text("参考画面", "Reference Screen"),
                    symbol: "display",
                    style: .reference,
                    showsEditingChrome: !showsDrawing,
                    isFrontmost: false
                )
                .frame(
                    width: proxy.size.width * 0.32,
                    height: proxy.size.height * 0.34
                )
                .position(
                    x: proxy.size.width * 0.79,
                    y: proxy.size.height * 0.70
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
    let isFrontmost: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tileBackground)
                tileContent(size: proxy.size)

                if showsEditingChrome {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(
                            isFrontmost ? StagePanePalette.aquaReadable : Color.white.opacity(0.42),
                            style: StrokeStyle(lineWidth: isFrontmost ? 2 : 1, dash: isFrontmost ? [] : [5, 4])
                        )

                    Label(title, systemImage: symbol)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .frame(minHeight: 20)
                        .background(Color.black.opacity(0.72), in: Capsule())
                        .padding(7)

                    if isFrontmost {
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
            .shadow(color: .black.opacity(0.28), radius: 8, y: 5)
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
                    x: size.width * 0.67,
                    y: size.height * 0.12,
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
