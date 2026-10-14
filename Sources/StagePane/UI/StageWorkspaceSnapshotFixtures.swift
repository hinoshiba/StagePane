import StagePaneCore
import SwiftUI

/// Deterministic, privacy-safe content used only by the explicit `--snapshot`
/// export path. Production Workspace instances never receive a fixture.
enum StageWorkspaceSnapshotFixture: Sendable {
    case arrange
    case draw
    case sources
    case product

    var sourceCount: Int { self == .product ? 2 : 3 }

    var selectedSourceTitle: String {
        self == .product
            ? L10n.text("予約体験の資料", "Booking Slides")
            : L10n.text("プレゼン資料", "Presentation")
    }

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

    static var productFixtures: [SnapshotSourcePresentation] {
        [
            SnapshotSourcePresentation(
                id: 1,
                title: StageWorkspaceSnapshotFixture.product.selectedSourceTitle,
                symbol: "macwindow",
                isHidden: false,
                isSelected: true
            ),
            SnapshotSourcePresentation(
                id: 2,
                title: L10n.text("予約フォーム", "Booking Form"),
                symbol: "macwindow",
                isHidden: false,
                isSelected: false
            )
        ]
    }
}

struct SnapshotSourceRailList: View {
    var fixture: StageWorkspaceSnapshotFixture = .arrange

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(fixture == .product ? SnapshotSourcePresentation.productFixtures : SnapshotSourcePresentation.fixtures) { source in
                SnapshotLayerRow(source: source)
            }
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }
}

private struct SnapshotLayerRow: View {
    let source: SnapshotSourcePresentation

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 44)
            HStack(spacing: 7) {
                Image(systemName: source.symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.title)
                        .font(.system(size: 13, weight: source.isSelected ? .semibold : .regular))
                        .lineLimit(1)
                    Text(source.isHidden
                        ? L10n.text("非表示・取得停止", "Hidden · Capture paused")
                        : L10n.text("画面取得中", "Capturing"))
                        .font(.system(size: 12))
                        .lineLimit(2, reservesSpace: true)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 44)
            Image(systemName: source.isHidden ? "eye.slash" : "eye")
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
            Image(systemName: "ellipsis")
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
        .background(source.isSelected ? Color.accentColor.opacity(0.13) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6))
    }
}

struct SnapshotSelectedLayerTools: View {
    var fixture: StageWorkspaceSnapshotFixture = .arrange

    var body: some View {
        HStack(spacing: 8) {
            Text(fixture.selectedSourceTitle)
                .font(.callout)
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Button(action: {}) {
                Label(L10n.cropEditActionTitle(isCropped: false), systemImage: "crop")
            }
            Menu {} label: { Image(systemName: "ellipsis").frame(minWidth: 20) }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
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

/// One shared composition supplies both public Stage and private Workspace
/// product images. All names and content are fictional; these views neither
/// capture a source nor model an interactive booking service.
struct SnapshotProductComposition: View {
    let showsEditingChrome: Bool
    let theme: StageTheme
    let showsWatermark: Bool

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 960, proxy.size.height / 540)
            ZStack {
                StageBackground(theme: theme)
                HStack(spacing: 24) {
                    SnapshotBookingSlides()
                        .frame(width: 528, height: 414)
                        .overlay {
                            if showsEditingChrome {
                                SnapshotProductSelectionChrome()
                            }
                        }
                    SnapshotBookingForm()
                        .frame(width: 336, height: 414)
                }
                .padding(.horizontal, 36)
                .padding(.top, 54)
                .padding(.bottom, 72)
                if showsWatermark {
                    StageWatermark(prefersDarkForeground: theme.prefersDarkForeground)
                }
            }
            .frame(width: 960, height: 540)
            .scaleEffect(scale)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

private enum SnapshotBookingPalette {
    static let ink = Color(red: 0.15, green: 0.16, blue: 0.22)
    static let secondary = Color(red: 0.42, green: 0.43, blue: 0.49)
    static let accent = Color(red: 0.34, green: 0.32, blue: 0.75)
    static let pale = Color(red: 0.94, green: 0.93, blue: 0.99)
    static let line = Color(red: 0.88, green: 0.89, blue: 0.92)
}

private struct SnapshotBookingSlides: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.text("体験予約の改善", "A BETTER BOOKING FLOW"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SnapshotBookingPalette.accent)
                Spacer()
                Text("01 / 06")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(SnapshotBookingPalette.secondary)
            }
            .padding(.top, 8)

            Text(L10n.text("体験予約を、\n3ステップで。", "Book a workshop.\nIn three steps."))
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.8)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            HStack(spacing: 12) {
                step(number: "01", title: L10n.text("日程を選ぶ", "Pick a date"), symbol: "calendar")
                step(number: "02", title: L10n.text("人数を選ぶ", "Add guests"), symbol: "person.2")
                step(number: "03", title: L10n.text("予約を確認", "Review"), symbol: "checkmark.circle")
            }
            .padding(.top, 20)

            Spacer(minLength: 8)
            Text(L10n.text(
                "フォームを見ながら、予約の流れを確認。",
                "Walk through the flow with the form beside you."
            ))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SnapshotBookingPalette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(SnapshotBookingPalette.ink)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.995, green: 0.992, blue: 1), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
    }

    private func step(number: String, title: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .medium))
                Spacer(minLength: 4)
                Text(number)
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(SnapshotBookingPalette.secondary)
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(SnapshotBookingPalette.accent)
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SnapshotBookingPalette.pale, in: RoundedRectangle(cornerRadius: 9))
    }
}

private struct SnapshotBookingForm: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                ForEach([Color(red: 0.94, green: 0.40, blue: 0.38),
                         Color(red: 0.96, green: 0.75, blue: 0.31),
                         Color(red: 0.36, green: 0.74, blue: 0.43)].indices, id: \.self) { index in
                    Circle()
                        .fill([Color(red: 0.94, green: 0.40, blue: 0.38),
                               Color(red: 0.96, green: 0.75, blue: 0.31),
                               Color(red: 0.36, green: 0.74, blue: 0.43)][index])
                        .frame(width: 8, height: 8)
                }
                Spacer()
                Text("HARU STUDIO")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
            }
            .foregroundStyle(SnapshotBookingPalette.secondary)
            .padding(.horizontal, 15)
            .frame(height: 36)
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SnapshotBookingPalette.accent)
                        .frame(width: 52, height: 52)
                        .background(SnapshotBookingPalette.pale, in: RoundedRectangle(cornerRadius: 11))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("陶芸ワークショップ", "Pottery workshop"))
                            .font(.system(size: 18, weight: .bold))
                        Text(L10n.text("90分 · はじめての方も歓迎", "90 min · Beginners welcome"))
                            .font(.system(size: 11))
                            .foregroundStyle(SnapshotBookingPalette.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel(L10n.text("日程", "Date"))
                    HStack {
                        Text(L10n.text("10月24日（土）", "Sat, Oct 24"))
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundStyle(SnapshotBookingPalette.secondary)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(SnapshotBookingPalette.line, lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel(L10n.text("時間", "Time"))
                    HStack(spacing: 7) {
                        ForEach(["10:00", "13:00", "15:00"], id: \.self) { time in
                            Text(time)
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .foregroundStyle(time == "10:00" ? Color.white : SnapshotBookingPalette.ink)
                                .background(time == "10:00" ? SnapshotBookingPalette.accent : SnapshotBookingPalette.pale,
                                            in: RoundedRectangle(cornerRadius: 7))
                        }
                    }
                }
                HStack {
                    fieldLabel(L10n.text("人数", "Guests"))
                    Spacer()
                    Image(systemName: "minus.circle")
                    Text(L10n.text("2名", "2 guests"))
                        .padding(.horizontal, 8)
                    Image(systemName: "plus.circle")
                }
                .font(.system(size: 14, weight: .medium))
                .frame(height: 26)

                Text(L10n.text("予約内容を確認", "Review booking"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(SnapshotBookingPalette.accent, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .foregroundStyle(SnapshotBookingPalette.ink)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
    }

    private func fieldLabel(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(SnapshotBookingPalette.secondary)
    }
}

private struct SnapshotProductSelectionChrome: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(StagePanePalette.aquaReadable, lineWidth: 2)
            Label(StageWorkspaceSnapshotFixture.product.selectedSourceTitle, systemImage: "macwindow")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(Color.black.opacity(0.76), in: Capsule())
                .padding(6)
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(StagePanePalette.aquaReadable, in: Circle())
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
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
