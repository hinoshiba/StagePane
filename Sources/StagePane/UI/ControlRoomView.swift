import StagePaneCore
import SwiftUI

private enum ControlSection: String, CaseIterable, Identifiable {
    case stage
    case permissions
    case appearance
    case privacy
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stage: L10n.text("ステージ", "Stage")
        case .permissions: L10n.text("アクセス権限", "Permissions")
        case .appearance: L10n.text("見た目と動作", "Appearance")
        case .privacy: L10n.text("プライバシー", "Privacy")
        case .about: L10n.text("このアプリについて", "About")
        }
    }

    var symbol: String {
        switch self {
        case .stage: "rectangle.inset.filled"
        case .permissions: "checkmark.shield.fill"
        case .appearance: "paintpalette.fill"
        case .privacy: "hand.raised.fill"
        case .about: "info.circle.fill"
        }
    }
}

struct ControlRoomView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    @State private var selection: ControlSection = .stage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 224, height: geometry.size.height)

                Divider().opacity(0.45)

                detail
                    .frame(
                        width: max(0, geometry.size.width - 225),
                        height: geometry.size.height
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(
            ZStack {
                (colorScheme == .dark ? StagePanePalette.ink : StagePanePalette.cloud)
                RadialGradient(
                    colors: [StagePanePalette.indigo.opacity(colorScheme == .dark ? 0.13 : 0.09), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 680
                )
            }
            .ignoresSafeArea()
        )
        .preferredColorScheme(nil)
        .onChange(of: controller.permissionPanelRequestRevision) { _, _ in
            selection = .permissions
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .stage:
            StageDashboard(controller: controller, capture: capture)
        case .permissions:
            PermissionsPanel(controller: controller, capture: capture)
        case .appearance:
            AppearancePanel(controller: controller)
        case .privacy:
            PrivacyPanel(controller: controller, capture: capture)
        case .about:
            AboutPanel(controller: controller)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandLockup()
                .padding(.horizontal, 20)
                .padding(.top, 31)
                .padding(.bottom, 28)

            VStack(spacing: 6) {
                ForEach(ControlSection.allCases) { section in
                    Button {
                        selection = section
                        if section == .permissions {
                            controller.clearPermissionPanelFocus()
                            controller.refreshPermissionStatus()
                        }
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: sectionSymbol(section))
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 20)
                            Text(section.title)
                                .font(.system(size: 13, weight: selection == section ? .semibold : .medium))
                            Spacer()
                        }
                        .foregroundStyle(selection == section ? Color.primary : Color.secondary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 39)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selection == section ? StagePanePalette.indigo.opacity(0.16) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(section.title)
                    .accessibilityValue(sectionAccessibilityValue(section))
                }
            }
            .padding(.horizontal, 10)

            Spacer()
        }
        .background(Color.primary.opacity(colorScheme == .dark ? 0.018 : 0.025))
    }

    private var permissionsNeedAttention: Bool {
        return controller.stageInteractionMode == .control &&
            !controller.previewInputAccessGranted
    }

    private func sectionSymbol(_ section: ControlSection) -> String {
        if section == .permissions, permissionsNeedAttention {
            return "exclamationmark.shield.fill"
        }
        return section.symbol
    }

    private func sectionAccessibilityValue(_ section: ControlSection) -> String {
        var values: [String] = []
        if selection == section {
            values.append(L10n.text("選択中", "Selected"))
        }
        if section == .permissions, permissionsNeedAttention {
            values.append(L10n.text("確認が必要", "Needs attention"))
        }
        return values.joined(separator: ", ")
    }
}

struct StageDashboard: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        ScrollView {
            dashboardContent
        }
    }

    var dashboardContent: some View {
        VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    SectionHeading(
                        eyebrow: L10n.text("CONTROL ROOM / 共有しない画面", "CONTROL ROOM / KEEP PRIVATE"),
                        title: L10n.text("見せたいものだけ、ひとつのステージへ。", "A clean stage for everything you share."),
                        detail: L10n.text(
                            "この操作画面は手元に置き、会議アプリでは「StagePane Stage」を共有してください。",
                            "Keep this controller private, then share “StagePane Stage” in your meeting app."
                        )
                    )
                    Spacer(minLength: 18)
                    CaptureStatusBadge(capture: capture, curtain: controller.privacyCurtain)
                }

                if let notice = controller.transientNotice {
                    NoticeBanner(message: notice) {
                        controller.dismissTransientNotice()
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        StageWorkspaceLaunchCard(controller: controller, capture: capture)
                            .frame(minWidth: 340, maxWidth: .infinity)
                            .layoutPriority(1)

                        sourceColumn
                            .frame(width: 292)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        StageWorkspaceLaunchCard(controller: controller, capture: capture)
                        sourceColumn
                    }
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 190), spacing: 12)],
                    spacing: 12
                ) {
                    QuickAction(
                        title: controller.privacyCurtain
                            ? L10n.text("カーテンを開く", "Reveal Stage")
                            : L10n.text("カーテン", "Curtain"),
                        detail: controller.privacyCurtain
                            ? L10n.text("準備後に表示（⇧⌘H）", "Show when ready (⇧⌘H)")
                            : L10n.text("すぐ隠す（⇧⌘H）", "Hide instantly (⇧⌘H)"),
                        symbol: controller.privacyCurtain ? "eye.fill" : "shield.lefthalf.filled",
                        tint: controller.privacyCurtain ? StagePanePalette.mintReadable : StagePanePalette.coralReadable,
                        action: controller.toggleCurtain
                    )
                    QuickAction(
                        title: L10n.text("ステージを表示", "Show Stage"),
                        detail: L10n.text("共有用ウインドウを前面へ", "Bring Stage forward"),
                        symbol: "macwindow.on.rectangle",
                        tint: StagePanePalette.indigo,
                        action: controller.showStage
                    )
                    QuickAction(
                        title: capture.hasResettableFailure
                            ? L10n.text("画面取得をリセット", "Reset Capture")
                            : L10n.text("すべて停止", "Stop All"),
                        detail: capture.hasResettableFailure
                            ? L10n.text("エラー状態を消して選び直す", "Clear the error and choose again")
                            : L10n.text("全ソースの画面取得を終了", "End capture for every source"),
                        symbol: capture.hasResettableFailure ? "arrow.counterclockwise" : "stop.fill",
                        tint: capture.hasResettableFailure ? .orange : .secondary,
                        action: controller.stopPreview
                    )
                    .disabled(
                        (!capture.isCaptureActive && !capture.hasResettableFailure) ||
                            capture.isPickerPresented
                    )
                }

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Text(L10n.text("ステージの形", "Stage shape"))
                            .font(.headline)
                        Spacer()
                        Text("\(controller.preset.pixelWidth) × \(controller.preset.pixelHeight)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    PresetPicker(controller: controller)
                }
                .cardSurface()

        }
        .padding(.top, 38)
        .padding(.horizontal, 32)
        .padding(.bottom, 34)
    }

    private var conferenceShareButtonTitle: String {
        if #available(macOS 15.0, *) {
            return L10n.text("共有先をステージへ切替", "Switch Active Share")
        }
        return L10n.text("共有方法を見る", "How to Share")
    }

    private var sourceColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            CaptureSourceList(controller: controller, capture: capture)
                .cardSurface()

            Button(action: controller.requestConferenceShare) {
                Label(conferenceShareButtonTitle, systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .help(conferenceShareButtonHelp)
        }
    }

    private var conferenceShareButtonHelp: String {
        if #available(macOS 15.0, *) {
            return L10n.text(
                "対応会議アプリで、現在の共有対象をステージへ切り替えます。",
                "Ask a compatible meeting app to switch its current share to the Stage."
            )
        }
        return L10n.text(
            "会議アプリの共有画面で「StagePane Stage」を選ぶ手順を表示します。",
            "Show how to choose “StagePane Stage” in your meeting app."
        )
    }
}

private struct StageWorkspaceLaunchCard: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                Label(
                    L10n.text("STAGE WORKSPACE / 共有しない", "STAGE WORKSPACE / KEEP PRIVATE"),
                    systemImage: "rectangle.inset.filled.and.person.filled"
                )
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

                Spacer()

                Label(
                    controller.workspaceIsVisible
                        ? L10n.text("開いています", "OPEN")
                        : L10n.text("閉じています", "CLOSED"),
                    systemImage: controller.workspaceIsVisible ? "circle.fill" : "circle"
                )
                .font(.caption2.weight(.bold))
                .foregroundStyle(controller.workspaceIsVisible
                    ? StagePanePalette.mintReadable
                    : Color.secondary)
            }

            workspaceIllustration

            VStack(alignment: .leading, spacing: 7) {
                Text(AppController.supportsControlMode
                    ? L10n.text(
                        "配置・操作・手書きは、大きな専用画面で。",
                        "Arrange, control, and draw on a dedicated big canvas."
                    )
                    : L10n.text(
                        "配置・手書きは、大きな専用画面で。",
                        "Arrange and draw on a dedicated big canvas."
                    ))
                .font(.title3.weight(.bold))

                Text(L10n.text(
                    "観客側のStageを汚さず、手元だけで正確に仕上げます。画像のコピーやPNG保存もWorkspaceから行えます。",
                    "Shape the audience Stage precisely without putting editing chrome on it. Copy or save a clean PNG from the Workspace too."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: controller.showStageWorkspace) {
                Label(
                    L10n.text("ステージワークスペースを開く", "Open Stage Workspace"),
                    systemImage: "arrow.up.right.square"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .keyboardShortcut("1", modifiers: [.command])
            .accessibilityHint(L10n.text(
                "共有しない大きな編集ウインドウを開きます。",
                "Opens the large private editing window."
            ))
        }
        .cardSurface()
    }

    private var workspaceIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.82))

            StageBackground(theme: controller.theme)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(18)

            VStack {
                HStack(spacing: 7) {
                    workspaceChip("配置", "Arrange", symbol: "rectangle.3.group")
                    if AppController.supportsControlMode {
                        workspaceChip("操作", "Control", symbol: "hand.tap")
                    }
                    workspaceChip("手書き", "Draw", symbol: "pencil.tip")
                }
                Spacer()
                HStack {
                    Label(
                        L10n.text("\(capture.sources.count)ソース", "\(capture.sources.count) source\(capture.sources.count == 1 ? "" : "s")"),
                        systemImage: "square.stack.3d.up"
                    )
                    Spacer()
                    Label(L10n.text("画像に保存", "Audience PNG"), systemImage: "camera")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.76))
            }
            .padding(28)
        }
        .frame(height: 168)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.20), radius: 18, y: 9)
        .accessibilityHidden(true)
    }

    private func workspaceChip(_ japanese: String, _ english: String, symbol: String) -> some View {
        Label(L10n.text(japanese, english), systemImage: symbol)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .frame(minHeight: 28)
            .background(Color.black.opacity(0.54), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct CaptureStatusBadge: View {
    @ObservedObject var capture: CaptureCoordinator
    let curtain: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if allSourcesPaused {
                StatusCapsule(
                    title: L10n.text("一時停止中", "PAUSED"),
                    symbol: "pause.fill",
                    color: .secondary
                )
            } else if capture.isCaptureActive {
                StatusCapsule(
                    title: L10n.text("画面取得中", "CAPTURE ACTIVE"),
                    symbol: "rectangle.inset.filled",
                    color: StagePanePalette.mintReadable
                )
            } else if !phaseNeedsAttention {
                StatusCapsule(title: phaseTitle, symbol: phaseSymbol, color: phaseColor)
            }

            if phaseNeedsAttention {
                StatusCapsule(
                    title: L10n.text("確認が必要", "NEEDS ATTENTION"),
                    symbol: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }

            if curtain {
                StatusCapsule(
                    title: L10n.text("カーテン中", "CURTAIN ON"),
                    symbol: "shield.fill",
                    color: StagePanePalette.coralReadable
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var phaseTitle: String {
        switch capture.phase {
        case .idle: return L10n.text("画面取得なし", "NO CAPTURE")
        case .choosing: return L10n.text("選択中", "CHOOSING")
        case .preparing: return L10n.text("準備中", "PREPARING")
        case .previewing: return L10n.text("画面取得中", "CAPTURE ACTIVE")
        case .failed: return L10n.text("確認が必要", "NEEDS ATTENTION")
        }
    }

    private var phaseSymbol: String {
        switch capture.phase {
        case .idle: return "rectangle.badge.xmark"
        case .choosing, .preparing: return "ellipsis.circle.fill"
        case .previewing: return "rectangle.inset.filled"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var phaseColor: Color {
        switch capture.phase {
        case .idle: return .secondary
        case .choosing, .preparing: return StagePanePalette.aquaReadable
        case .previewing: return StagePanePalette.mintReadable
        case .failed: return Color.orange
        }
    }

    private var phaseNeedsAttention: Bool {
        if case .failed = capture.phase { return true }
        return false
    }

    private var accessibilitySummary: String {
        var parts: [String] = []
        if allSourcesPaused {
            parts.append(L10n.text("すべてのソースを一時停止中", "All sources paused"))
        } else if capture.isCaptureActive {
            parts.append(L10n.text("画面取得中", "Capture active"))
        } else if !phaseNeedsAttention {
            parts.append(phaseTitle)
        }
        if phaseNeedsAttention {
            parts.append(L10n.text("確認が必要", "Needs attention"))
        }
        if curtain {
            parts.append(L10n.text("カーテン中", "Curtain on"))
        }
        return parts.joined(separator: L10n.text("。", ". "))
    }

    private var allSourcesPaused: Bool {
        !capture.sources.isEmpty && capture.sources.allSatisfy(\.isPaused)
    }

}

private struct StatusCapsule: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 11)
        .frame(minHeight: 30)
        .background(color.opacity(0.10), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.24), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

private struct ChecklistRow: View {
    let number: Int
    let title: String
    let done: Bool?

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(done == true ? StagePanePalette.mintReadable.opacity(0.18) : Color.primary.opacity(0.07))
                    .frame(width: 24, height: 24)
                if done == true {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(StagePanePalette.mintReadable)
                } else {
                    Text("\(number)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(done == true ? Color.secondary : Color.primary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityStatus)
    }

    private var accessibilityStatus: String {
        guard let done else {
            return L10n.text("会議アプリで確認", "Complete in your meeting app")
        }
        return done ? L10n.text("完了", "Complete") : L10n.text("未完了", "Not complete")
    }
}

private struct QuickAction: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryActionButtonStyle())
    }
}

private struct PresetPicker: View {
    @ObservedObject var controller: AppController

    var body: some View {
        HStack(spacing: 10) {
            ForEach(StagePreset.allCases) { preset in
                Button {
                    controller.setPreset(preset)
                } label: {
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(
                                controller.preset == preset ? StagePanePalette.aquaReadable : Color.secondary.opacity(0.60),
                                lineWidth: controller.preset == preset ? 2 : 1
                            )
                            .aspectRatio(preset.aspectRatio, contentMode: .fit)
                            .frame(height: 34)
                        Text(L10n.presetName(preset))
                            .font(.caption2.weight(controller.preset == preset ? .bold : .medium))
                            .foregroundStyle(controller.preset == preset ? Color.primary : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(controller.preset == preset ? StagePanePalette.indigo.opacity(0.12) : Color.primary.opacity(0.035))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text(
                    "\(L10n.presetName(preset))、\(preset.pixelWidth)×\(preset.pixelHeight)",
                    "\(L10n.presetName(preset)), \(preset.pixelWidth) by \(preset.pixelHeight)"
                ))
                .accessibilityValue(
                    controller.preset == preset ? L10n.text("選択中", "Selected") : ""
                )
            }
        }
    }
}

private struct NoticeBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(StagePanePalette.aquaReadable)
            Text(message)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("通知を閉じる", "Dismiss notice"))
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 40)
        .background(StagePanePalette.aquaReadable.opacity(0.09), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(StagePanePalette.aquaReadable.opacity(0.24)))
    }
}
