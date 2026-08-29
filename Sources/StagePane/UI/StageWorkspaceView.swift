import StagePaneCore
import SwiftUI

private extension WorkspaceSection {
    var title: String {
        switch self {
        case .canvas: L10n.text("キャンバス", "Canvas")
        case .sources: L10n.text("ソース", "Sources")
        case .stage: L10n.text("Stage設定", "Stage Settings")
        case .appearance: L10n.text("見た目と動作", "Appearance")
        case .pro: "StagePane Pro"
        case .permissions: L10n.text("アクセス権限", "Permissions")
        case .privacy: L10n.text("プライバシー", "Privacy")
        case .about: L10n.text("このアプリについて", "About")
        }
    }

    var symbol: String {
        switch self {
        case .canvas: "rectangle.inset.filled"
        case .sources: "square.stack.3d.up.fill"
        case .stage: "slider.horizontal.3"
        case .appearance: "paintpalette.fill"
        case .pro: "sparkles"
        case .permissions: "checkmark.shield.fill"
        case .privacy: "hand.raised.fill"
        case .about: "info.circle.fill"
        }
    }
}

/// A private, large-format workspace for composing and operating the audience Stage.
///
/// This view deliberately uses the preview renderers through `StageLayoutEditor`.
/// The shareable `StageView` remains a separate, chrome-free window, so workspace
/// controls can never become part of the intended audience output.
struct StageWorkspaceView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    private let focusesAppearanceForSnapshot: Bool
    private let snapshotFixture: StageWorkspaceSnapshotFixture?

    @State private var isSourceRailVisible = true
    @State private var isClearInkConfirmationPresented = false

    init(
        controller: AppController,
        capture: CaptureCoordinator,
        focusesAppearanceForSnapshot: Bool = false,
        snapshotFixture: StageWorkspaceSnapshotFixture? = nil
    ) {
        self.controller = controller
        self.capture = capture
        self.focusesAppearanceForSnapshot = focusesAppearanceForSnapshot
        self.snapshotFixture = snapshotFixture
    }

    var body: some View {
        GeometryReader { geometry in
            let usesCompactNavigation = geometry.size.width < 1_100

            HStack(spacing: 0) {
                workspaceNavigation(compact: usesCompactNavigation)
                    .frame(width: usesCompactNavigation ? 66 : 218)

                Divider().overlay(Color.white.opacity(0.10))

                workspaceContent
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                if usesCompactNavigation {
                    isSourceRailVisible = false
                }
            }
            .onChange(of: usesCompactNavigation) { _, isCompact in
                if isCompact {
                    isSourceRailVisible = false
                }
            }
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(workspaceBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .confirmationDialog(
            L10n.text("手書きをすべて消しますか？", "Clear all drawings?"),
            isPresented: $isClearInkConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(L10n.text("すべて消す", "Clear All"), role: .destructive) {
                controller.annotations.removeAll()
            }
            Button(L10n.text("キャンセル", "Cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text(
                "共有Stageとこのワークスペースから、すべての線を削除します。",
                "Remove every line from the shared Stage and this workspace."
            ))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(
            "StagePane ステージワークスペース",
            "StagePane Stage Workspace"
        ))
    }

    private var workspaceContent: some View {
        VStack(spacing: 0) {
            workspaceToolbar
            privateWorkspaceWarning
            workspaceDetail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    Group {
                        if let notice = controller.transientNoticeState.notice {
                            WorkspaceNoticeToast(message: notice.message) {
                                controller.dismissTransientNotice(id: notice.id)
                            }
                            .id(notice.id)
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                            .transition(transientNoticeTransition)
                            .zIndex(20)
                        }
                    }
                    .animation(
                        accessibilityReduceMotion
                            ? .linear(duration: 0.10)
                            : .easeOut(duration: 0.20),
                        value: controller.transientNoticeState.notice?.id
                    )
                }
        }
    }

    private var transientNoticeTransition: AnyTransition {
        if accessibilityReduceMotion { return .opacity }
        return .opacity.combined(with: .move(edge: .top))
    }

    @ViewBuilder
    private var workspaceDetail: some View {
        switch controller.workspaceSection {
        case .canvas:
            ViewThatFits(in: .horizontal) {
                wideWorkspace
                compactWorkspace
            }
        case .sources:
            if snapshotFixture == .sources {
                WorkspaceSourcesSnapshotPanel()
            } else {
                WorkspaceSourcesPanel(controller: controller, capture: capture)
            }
        case .stage:
            StageSettingsPanel(controller: controller, capture: capture)
        case .appearance:
            AppearancePanel(
                controller: controller,
                focusesAudienceForSnapshot: focusesAppearanceForSnapshot
            )
        case .pro:
            ProUpgradePanel(controller: controller, purchases: controller.purchases)
        case .permissions:
            PermissionsPanel(controller: controller, capture: capture)
        case .privacy:
            PrivacyPanel(controller: controller, capture: capture)
        case .about:
            AboutPanel(controller: controller)
        }
    }

    private func workspaceNavigation(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if compact {
                    BrandMark(size: 30)
                        .frame(maxWidth: .infinity)
                } else {
                    BrandLockup()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, compact ? 10 : 18)
            .padding(.top, 20)
            .padding(.bottom, compact ? 21 : 24)

            navigationGroup(
                title: L10n.text("ワークスペース", "WORKSPACE"),
                sections: [.canvas, .sources],
                compact: compact
            )

            navigationDivider(compact: compact)

            navigationGroup(
                title: L10n.text("ステージ", "STAGE"),
                sections: [.stage, .appearance, .pro],
                compact: compact
            )

            navigationDivider(compact: compact)

            navigationGroup(
                title: L10n.text("アプリ", "APP"),
                sections: [.permissions, .privacy, .about],
                compact: compact
            )

            Spacer(minLength: 12)

            if !compact {
                HStack(spacing: 7) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(StagePanePalette.aqua)
                    Text(L10n.text("この画面は共有しない", "KEEP THIS PRIVATE"))
                        .font(.caption2.weight(.bold))
                        .tracking(0.35)
                }
                .foregroundStyle(Color.white.opacity(0.58))
                .padding(.horizontal, 17)
                .padding(.bottom, 17)
                .accessibilityElement(children: .combine)
            }
        }
        .background(Color.black.opacity(0.20))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(
            "StagePane ワークスペースのナビゲーション",
            "StagePane Workspace navigation"
        ))
    }

    private func navigationGroup(
        title: String,
        sections: [WorkspaceSection],
        compact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if !compact {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Color.white.opacity(0.38))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 3)
            }

            ForEach(sections) { section in
                navigationButton(section, compact: compact)
            }
        }
        .padding(.horizontal, compact ? 7 : 9)
    }

    private func navigationButton(
        _ section: WorkspaceSection,
        compact: Bool
    ) -> some View {
        let isSelected = controller.workspaceSection == section

        return Button {
            controller.selectWorkspaceSection(section)
        } label: {
            HStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: navigationSymbol(for: section))
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 23, height: 23)

                    if compact, section == .sources, displayedSourceCount > 0 {
                        Text("\(displayedSourceCount)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 14, height: 14)
                            .background(StagePanePalette.indigo, in: Circle())
                            .offset(x: 5, y: -4)
                    }
                }

                if !compact {
                    Text(section.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if section == .sources {
                        Text("\(displayedSourceCount) / \(controller.activeSourceLimit)")
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.48))
                    } else if section == .pro {
                        Text(controller.hasProAccess ? L10n.text("有効", "ACTIVE") : "PRO")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.4)
                            .foregroundStyle(controller.hasProAccess
                                ? StagePanePalette.mint
                                : StagePanePalette.aqua)
                    }
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.65))
            .padding(.horizontal, compact ? 9 : 11)
            .frame(maxWidth: .infinity, minHeight: 39, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? StagePanePalette.indigo.opacity(0.34) : Color.clear)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        isSelected ? StagePanePalette.aqua.opacity(0.15) : .clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .help(section.title)
        .accessibilityLabel(section.title)
        .accessibilityValue(navigationAccessibilityValue(for: section))
    }

    private func navigationDivider(compact: Bool) -> some View {
        Divider()
            .overlay(Color.white.opacity(0.08))
            .padding(.horizontal, compact ? 13 : 15)
            .padding(.vertical, compact ? 10 : 13)
    }

    private func navigationSymbol(for section: WorkspaceSection) -> String {
        section.symbol
    }

    private func navigationAccessibilityValue(for section: WorkspaceSection) -> String {
        var values: [String] = []
        if controller.workspaceSection == section {
            values.append(L10n.text("選択中", "Selected"))
        }
        if section == .sources {
            values.append(L10n.text(
                "\(displayedSourceCount)件",
                "\(displayedSourceCount) of \(controller.activeSourceLimit)"
            ))
        }
        if section == .pro, controller.hasProAccess {
            values.append(L10n.text("有効", "Active"))
        }
        return values.joined(separator: ", ")
    }

    private var workspaceToolbar: some View {
        GeometryReader { proxy in
            workspaceToolbarContent(compact: proxy.size.width < 1_040)
                .frame(width: proxy.size.width, height: 58)
        }
        .frame(height: 58)
        .background(Color.white.opacity(0.055))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.white.opacity(0.10))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(
            "ステージワークスペースのツールバー",
            "Stage Workspace toolbar"
        ))
    }

    private func workspaceToolbarContent(compact: Bool) -> some View {
        HStack(spacing: 11) {
            if controller.workspaceSection == .canvas {
                Button {
                    isSourceRailVisible.toggle()
                } label: {
                    if compact {
                        Image(systemName: "sidebar.left")
                    } else {
                        Label(
                            isSourceRailVisible
                                ? L10n.text("ソースを隠す", "Hide Sources")
                                : L10n.text("ソースを表示", "Show Sources"),
                            systemImage: "sidebar.left"
                        )
                    }
                }
                .buttonStyle(WorkspaceToolbarButtonStyle())
                .accessibilityLabel(isSourceRailVisible
                    ? L10n.text("ソース一覧を隠す", "Hide source list")
                    : L10n.text("ソース一覧を表示", "Show source list"))
                .help(isSourceRailVisible
                    ? L10n.text("ソース一覧を隠します", "Hide the source list")
                    : L10n.text("ソース一覧を表示します", "Show the source list"))
            } else {
                if compact {
                    Image(systemName: controller.workspaceSection.symbol)
                        .frame(width: 29, height: 29)
                } else {
                    Label(
                        controller.workspaceSection.title,
                        systemImage: controller.workspaceSection.symbol
                    )
                    .font(.caption.weight(.semibold))
                }

            }

            WorkspaceOutputStatus(
                isStageVisible: controller.stageIsVisible,
                capture: capture,
                compact: compact,
                snapshotSourceCount: snapshotFixture?.sourceCount
            )

            Spacer(minLength: 8)

            if controller.workspaceSection == .canvas {
                if controller.stageInteractionMode == .crop {
                    cropToolbarIdentity(compact: compact)
                } else {
                    Picker(
                        L10n.text("ワークスペースのモード", "Workspace mode"),
                        selection: interactionModeBinding
                    ) {
                        ForEach(globalInteractionModes, id: \.rawValue) { mode in
                            Label(
                                L10n.stageInteractionModeName(mode),
                                systemImage: modeSymbol(mode)
                            )
                            .tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(
                        minWidth: compact ? 190 : 220,
                        idealWidth: compact ? 210 : 250,
                        maxWidth: compact ? 230 : 280
                    )
                    .accessibilityLabel(L10n.text(
                        "ワークスペースのモード",
                        "Workspace mode"
                    ))
                    .accessibilityValue(L10n.stageInteractionModeName(
                        controller.stageInteractionMode
                    ))
                    .accessibilityHint(L10n.text(
                        "配置または手書きを選びます。\(L10n.perLayerCropEntryHint)",
                        "Choose Arrange or Draw. \(L10n.perLayerCropEntryHint)"
                    ))
                }

                Spacer(minLength: 8)
            }

            screenshotMenu(compact: compact)

            Button(action: controller.toggleCurtain) {
                if compact {
                    Image(systemName: curtainButtonSymbol)
                } else {
                    Label(curtainButtonTitle, systemImage: curtainButtonSymbol)
                }
            }
            .buttonStyle(WorkspaceToolbarButtonStyle(
                tint: controller.privacyCurtain
                    ? StagePanePalette.coralReadable
                    : nil
            ))
            .accessibilityLabel(curtainButtonTitle)
            .accessibilityValue(controller.privacyCurtain
                ? L10n.text("観客側はカーテン中", "Audience curtain is on")
                : L10n.text("観客側に表示中", "Visible to the audience"))
            .help(L10n.text(
                "観客向けStageのカーテンを切り替えます（⇧⌘H）",
                "Toggle the audience Stage curtain (⇧⌘H)"
            ))

            Button(action: controller.showStage) {
                if compact {
                    Image(systemName: "macwindow.on.rectangle")
                } else {
                    Label(
                        L10n.text("共有Stageを表示", "Show Share Stage"),
                        systemImage: "macwindow.on.rectangle"
                    )
                }
            }
            .buttonStyle(WorkspaceToolbarButtonStyle(tint: StagePanePalette.indigo))
            .accessibilityLabel(L10n.text(
                "共有Stageを表示",
                "Show Share Stage"
            ))
            .help(L10n.text(
                "会議アプリに共有する、操作UIのないStageウインドウを表示します",
                "Show the chrome-free Stage window to share in a meeting app"
            ))
        }
        .controlSize(.regular)
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
    }

    private var privateWorkspaceWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .foregroundStyle(StagePanePalette.aqua)
                .accessibilityHidden(true)

            Text(L10n.text(
                "これは手元用の編集ワークスペースです。会議アプリでは「StagePane Stage」を共有してください。共有一覧から完全に隠れるとは限りません。",
                "This is your private editing workspace. Share “StagePane Stage” in your meeting app. This workspace may still appear in some share pickers."
            ))
            .lineLimit(2)

            Spacer(minLength: 8)

            Button(action: controller.requestConferenceShare) {
                Label(
                    L10n.text("共有先をStageへ", "Switch Share to Stage"),
                    systemImage: "arrow.up.forward.app"
                )
            }
            .buttonStyle(.borderless)
            .foregroundStyle(StagePanePalette.aqua)
            .help(L10n.text(
                "対応する会議アプリの現在の共有対象をStageへ切り替えます",
                "Ask a compatible meeting app to switch its current share to the Stage"
            ))
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Color.white.opacity(0.76))
        .padding(.horizontal, 16)
        .frame(minHeight: 38)
        .background(StagePanePalette.aqua.opacity(0.07))
        .overlay(alignment: .bottom) {
            Divider().overlay(StagePanePalette.aqua.opacity(0.15))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(
            "非共有ワークスペース。このウインドウではなくStagePane Stageを共有してください。",
            "Private workspace. Share StagePane Stage instead of this window."
        ))
        .accessibilityHint(L10n.text(
            "一部の会議アプリの共有一覧には、この操作用ウインドウも表示される場合があります。",
            "Some meeting-app share pickers may still list this control window."
        ))
    }

    private var wideWorkspace: some View {
        HStack(spacing: 0) {
            if isSourceRailVisible {
                sourceRail
                    .frame(width: 240)
            }

            Divider().overlay(Color.white.opacity(0.10))
            stageWorkspace
                .frame(minWidth: 650)
        }
        .frame(minWidth: isSourceRailVisible ? 910 : 680)
    }

    private var compactWorkspace: some View {
        stageWorkspace
            .overlay(alignment: .leading) {
                if isSourceRailVisible {
                    sourceRail
                        .frame(width: 240)
                        .background(.ultraThinMaterial)
                        .overlay(alignment: .trailing) {
                            Divider().overlay(Color.white.opacity(0.14))
                        }
                        .shadow(color: .black.opacity(0.42), radius: 24, x: 10)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
    }

    private var sourceRail: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(StagePanePalette.aqua)
                    .accessibilityHidden(true)
                Text(L10n.text("ステージのソース", "Stage Sources"))
                    .font(.caption.weight(.bold))
                Spacer()
                if controller.hasProAccess {
                    Text("PRO")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(StagePanePalette.aqua)
                        .padding(.horizontal, 6)
                        .frame(minHeight: 17)
                        .background(StagePanePalette.aqua.opacity(0.10), in: Capsule())
                }
                Text("\(displayedSourceCount) / \(controller.activeSourceLimit)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 15)
            .frame(minHeight: 42)

            Divider().overlay(Color.white.opacity(0.09))

            if snapshotFixture?.hasCanvasComposition == true {
                SnapshotSourceRailList()
                    .padding(14)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                CaptureSourceList(
                    controller: controller,
                    capture: capture,
                    showsHeading: false,
                    showsWorkspaceHint: false,
                    expandsSourceList: true,
                    usesSecondaryAddAction: true
                )
                    .padding(14)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color.black.opacity(0.16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(
            "ステージのソース一覧",
            "Stage source list"
        ))
    }

    private var stageWorkspace: some View {
        VStack(spacing: 12) {
            canvasHeader
            fittedStageCanvas
            contextualDock
        }
        .padding(.horizontal, 18)
        .padding(.top, 13)
        .padding(.bottom, 14)
    }

    private var canvasHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(canvasTitle)
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(StagePanePalette.aqua)
                Text(canvasDetail)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer()

            if controller.privacyCurtain {
                Label(
                    L10n.text("観客側はカーテン中", "Audience Curtain On"),
                    systemImage: "shield.fill"
                )
                .font(.caption2.weight(.bold))
                .foregroundStyle(StagePanePalette.coralReadable)
                .padding(.horizontal, 9)
                .frame(minHeight: 25)
                .background(StagePanePalette.coral.opacity(0.10), in: Capsule())
                .overlay(Capsule().stroke(StagePanePalette.coral.opacity(0.22)))
            }

            Text("\(controller.preset.pixelWidth) × \(controller.preset.pixelHeight)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.white.opacity(0.55))
                .accessibilityLabel(L10n.text(
                    "出力サイズ、\(controller.preset.pixelWidth)かける\(controller.preset.pixelHeight)",
                    "Output size, \(controller.preset.pixelWidth) by \(controller.preset.pixelHeight)"
                ))
        }
        .frame(minHeight: 32)
    }

    private var fittedStageCanvas: some View {
        GeometryReader { proxy in
            let canvasSize = fittedCanvasSize(in: proxy.size)

            Group {
                if let snapshotFixture, snapshotFixture.hasCanvasComposition {
                    SnapshotStageComposition(
                        showsDrawing: snapshotFixture == .draw,
                        theme: controller.theme,
                        showsWatermark: controller.showsWatermark
                    )
                } else {
                    StageLayoutEditor(controller: controller, capture: capture)
                }
            }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            controller.privacyCurtain
                                ? StagePanePalette.coralReadable.opacity(0.78)
                                : Color.white.opacity(0.18),
                            lineWidth: controller.privacyCurtain ? 2 : 1
                        )
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.58), radius: 28, y: 16)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.055))
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(
            "大きなステージキャンバス",
            "Large Stage canvas"
        ))
    }

    @ViewBuilder
    private var contextualDock: some View {
        HStack(spacing: 10) {
            modeIdentity
            Divider().frame(height: 25)

            switch controller.stageInteractionMode {
            case .arrange:
                Menu {
                    layoutPresetButton(
                        .grid,
                        title: L10n.text("グリッド", "Grid"),
                        symbol: "square.grid.2x2"
                    )
                    layoutPresetButton(
                        .sideBySide,
                        title: L10n.text("横に並べる", "Side by Side"),
                        symbol: "rectangle.split.2x1"
                    )
                    layoutPresetButton(
                        .stacked,
                        title: L10n.text("縦に並べる", "Stacked"),
                        symbol: "rectangle.split.1x2"
                    )
                    layoutPresetButton(
                        .pictureInPicture,
                        title: L10n.text("ピクチャーインピクチャ", "Picture in Picture"),
                        symbol: "rectangle.inset.filled"
                    )
                } label: {
                    Label(
                        L10n.text("クイック配置", "Quick Layout"),
                        systemImage: "square.grid.2x2"
                    )
                }
                .disabled(
                    (capture.sources.isEmpty && snapshotFixture?.hasCanvasComposition != true) ||
                        capture.isPickerPresented
                )
                .help(L10n.text(
                    "ソースをグリッド、横並び、縦並び、ピクチャーインピクチャに配置します",
                    "Arrange sources as a grid, side by side, stacked, or picture in picture"
                ))

            case .crop:
                HStack(spacing: 7) {
                    Image(systemName: "viewfinder")
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(cropEditingLayerTitle)
                            .lineLimit(1)
                        Text(L10n.cropDraftStatusTitle)
                            .font(.caption2.weight(.regular))
                            .foregroundStyle(Color.white.opacity(0.60))
                    }
                }
                .foregroundStyle(Color.white.opacity(0.82))
                .accessibilityElement(children: .combine)

                Image(systemName: "info.circle")
                    .foregroundStyle(Color.white.opacity(0.55))
                    .help("\(L10n.cropCaptureScopeCompact) \(L10n.cropCaptureScopeDetail)")
                    .accessibilityLabel(L10n.cropCaptureScopeCompact)
                    .accessibilityHint(L10n.cropCaptureScopeDetail)

                Button {
                    controller.resetCropDraft()
                } label: {
                    Label(
                        L10n.cropResetDraftTitle,
                        systemImage: "arrow.counterclockwise"
                    )
                }
                .disabled(
                    controller.cropDraft == nil ||
                        controller.cropDraft == .fullSource
                )
                .help(L10n.cropResetDraftHint)

                Button(role: .cancel) {
                    controller.cancelCropEditing()
                } label: {
                    Text(L10n.cropCancelTitle)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    controller.applyCropEditing()
                } label: {
                    Label(L10n.cropApplyTitle, systemImage: "checkmark")
                }
                .keyboardShortcut(.defaultAction)
                .tint(StagePanePalette.indigo)
                .disabled(!controller.canApplyCropEditing)

            case .annotate:
                StageInkToolShelf(store: controller.annotations)

                Button {
                    controller.annotations.undo()
                } label: {
                    Label(
                        L10n.text("取り消す", "Undo"),
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .disabled(!controller.hasAnnotations && snapshotFixture != .draw)
                .keyboardShortcut("z", modifiers: [.command])

                Button(role: .destructive) {
                    isClearInkConfirmationPresented = true
                } label: {
                    Label(
                        L10n.text("すべて消す", "Clear All"),
                        systemImage: "trash"
                    )
                }
                .disabled(!controller.hasAnnotations && snapshotFixture != .draw)
            }

            Spacer(minLength: 0)

            if capture.hasResettableFailure {
                Button(action: controller.stopPreview) {
                    Label(
                        L10n.text("画面取得をリセット", "Reset Capture"),
                        systemImage: "arrow.counterclockwise"
                    )
                }
                .tint(.orange)
                .help(L10n.text(
                    "エラー状態を消して、ソースを選び直せる状態へ戻します",
                    "Clear the error so you can choose the source again"
                ))
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .frame(minHeight: 50)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.11))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text(
            "現在のモードのツール",
            "Current mode tools"
        ))
    }

    private var modeIdentity: some View {
        let modeTitle = controller.stageInteractionMode == .crop
            ? L10n.cropLayerModeTitle
            : L10n.stageInteractionModeName(controller.stageInteractionMode)

        return Label(
            modeTitle,
            systemImage: modeSymbol(controller.stageInteractionMode)
        )
        .font(.caption.weight(.bold))
        .foregroundStyle(StagePanePalette.aqua)
        .accessibilityLabel(L10n.text(
            "現在のモード、\(modeTitle)",
            "Current mode, \(modeTitle)"
        ))
    }

    private func cropToolbarIdentity(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "crop")
                .foregroundStyle(StagePanePalette.aqua)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.cropLayerModeTitle)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.58))
                Text(cropEditingSourceTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, compact ? 9 : 11)
        .frame(
            minWidth: compact ? 170 : 210,
            maxWidth: compact ? 210 : 260,
            minHeight: 32,
            alignment: .leading
        )
        .background(StagePanePalette.aqua.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(StagePanePalette.aqua.opacity(0.18))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cropEditingLayerTitle)
        .accessibilityHint(L10n.stageInteractionModeDetail(.crop))
    }

    private func screenshotMenu(compact: Bool) -> some View {
        HStack(spacing: 0) {
            Button(action: controller.copyStageScreenshot) {
                Group {
                    if compact {
                        Image(systemName: screenshotSymbol)
                    } else {
                        Label(screenshotTitle, systemImage: screenshotSymbol)
                    }
                }
                .padding(.leading, compact ? 8 : 10)
                .padding(.trailing, 8)
                .frame(minHeight: 31)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .accessibilityLabel(L10n.text(
                "Audience画像をコピー",
                "Copy Audience Image"
            ))
            .accessibilityHint(L10n.text(
                "操作UIを含めず、観客向けStageと同じ内容をクリップボードへコピーします。",
                "Copy the audience Stage to the clipboard without workspace controls."
            ))

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 18)
                .accessibilityHidden(true)

            Menu {
                Button(action: controller.copyStageScreenshot) {
                    Label(
                        L10n.text("Audience画像をコピー", "Copy Audience Image"),
                        systemImage: "doc.on.clipboard"
                    )
                }
                Button(action: controller.saveStageScreenshot) {
                    Label(
                        L10n.text("Audience画像を保存…", "Save Audience Image…"),
                        systemImage: "square.and.arrow.down"
                    )
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 25, height: 31)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(L10n.text(
                "スクリーンショットのオプション",
                "Screenshot options"
            ))
            .accessibilityHint(L10n.text(
                "Audience画像をコピーするか、PNGとして保存するかを選びます。",
                "Choose whether to copy the audience image or save it as a PNG."
            ))
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.white.opacity(0.86))
        .frame(minWidth: 56, minHeight: 31)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.12))
        }
        .disabled(controller.isStageScreenshotInProgress)
        .help(L10n.text(
            "観客向けStageのスクリーンショット",
            "Audience Stage screenshot"
        ))
    }

    private var screenshotTitle: String {
        controller.isStageScreenshotInProgress
            ? L10n.text("作成中…", "Capturing…")
            : L10n.text("スクリーンショット", "Screenshot")
    }

    private var screenshotSymbol: String {
        controller.isStageScreenshotInProgress ? "hourglass" : "camera.fill"
    }

    private var interactionModeBinding: Binding<StageInteractionMode> {
        Binding(
            get: { controller.stageInteractionMode },
            set: { controller.setStageInteractionMode($0) }
        )
    }

    private var globalInteractionModes: [StageInteractionMode] {
        controller.availableStageInteractionModes.filter { $0 != .crop }
    }

    private var cropEditingSourceTitle: String {
        guard let sourceID = controller.cropEditingSourceID,
              let source = capture.source(for: sourceID) else {
            return L10n.text("対象レイヤー", "Target Layer")
        }
        return source.title
    }

    private var cropEditingLayerTitle: String {
        L10n.cropEditingLayerTitle(cropEditingSourceTitle)
    }

    private var canvasTitle: String {
        if controller.stageInteractionMode == .crop {
            return L10n.cropLayerModeTitle.uppercased()
        }
        return L10n.text("ステージキャンバス", "STAGE CANVAS")
    }

    private var canvasDetail: String {
        if controller.stageInteractionMode == .crop {
            return cropEditingLayerTitle
        }
        let detail = L10n.stageInteractionModeDetail(
            controller.stageInteractionMode,
            annotationTool: controller.annotationTool
        )
        guard controller.stageInteractionMode == .arrange else { return detail }
        return "\(detail) \(L10n.perLayerCropEntryHint)"
    }

    private var curtainButtonTitle: String {
        controller.privacyCurtain
            ? L10n.text("カーテンを開く", "Reveal Stage")
            : L10n.text("カーテン", "Curtain")
    }

    private var curtainButtonSymbol: String {
        controller.privacyCurtain ? "eye.fill" : "shield.lefthalf.filled"
    }

    private func modeSymbol(_ mode: StageInteractionMode) -> String {
        switch mode {
        case .arrange: "rectangle.3.group"
        case .crop: "crop"
        case .annotate: "pencil.tip"
        }
    }

    private func layoutPresetButton(
        _ preset: StageLayoutPreset,
        title: String,
        symbol: String
    ) -> some View {
        Button {
            capture.applyLayoutPreset(preset)
        } label: {
            Label(title, systemImage: symbol)
        }
    }

    private func fittedCanvasSize(in availableSize: CGSize) -> CGSize {
        guard availableSize.width > 0, availableSize.height > 0 else { return .zero }
        let ratio = CGFloat(controller.preset.aspectRatio)
        guard ratio.isFinite, ratio > 0 else { return .zero }

        if availableSize.width / availableSize.height > ratio {
            return CGSize(
                width: availableSize.height * ratio,
                height: availableSize.height
            )
        }
        return CGSize(
            width: availableSize.width,
            height: availableSize.width / ratio
        )
    }

    private var workspaceBackground: some View {
        ZStack {
            StagePanePalette.ink
            RadialGradient(
                colors: [StagePanePalette.indigo.opacity(0.20), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 820
            )
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var displayedSourceCount: Int {
        snapshotFixture?.sourceCount ?? capture.sources.count
    }
}

private struct StageInkToolShelf: View {
    @ObservedObject var store: StageAnnotationStore

    var body: some View {
        HStack(spacing: 9) {
            Picker(
                L10n.text("描画ツール", "Drawing tool"),
                selection: toolBinding
            ) {
                Image(systemName: "pencil.tip")
                    .tag(StageInkTool.pen)
                    .accessibilityLabel(L10n.text("ペン", "Pen"))
                Image(systemName: "highlighter")
                    .tag(StageInkTool.highlighter)
                    .accessibilityLabel(L10n.text("蛍光ペン", "Highlighter"))
                Image(systemName: "eraser.fill")
                    .tag(StageInkTool.eraser)
                    .accessibilityLabel(L10n.text("消しゴム", "Eraser"))
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 129)
            .accessibilityLabel(L10n.text("描画ツール", "Drawing tool"))
            .accessibilityValue(toolName(store.preferences.tool))
            .help(L10n.text(
                "ペン、半透明の蛍光ペン、部分消去の消しゴムを選びます",
                "Choose a pen, translucent highlighter, or partial eraser"
            ))

            if store.preferences.tool == .eraser {
                Divider()
                    .frame(height: 24)

                HStack(spacing: 5) {
                    Circle()
                        .stroke(Color.white.opacity(0.62), lineWidth: 1)
                        .frame(width: 7, height: 7)
                        .accessibilityHidden(true)

                    Slider(
                        value: eraserWidthBinding,
                        in: StageInkPreferences.minimumEraserNormalizedWidth ...
                            StageInkPreferences.maximumEraserNormalizedWidth,
                        step: 0.002
                    )
                    .frame(width: 86)
                    .accessibilityLabel(L10n.text(
                        "消しゴムの大きさ",
                        "Eraser size"
                    ))
                    .accessibilityValue(eraserWidthAccessibilityValue)

                    Circle()
                        .stroke(Color.white.opacity(0.82), lineWidth: 1.5)
                        .frame(width: 15, height: 15)
                        .accessibilityHidden(true)
                }
                .help(L10n.text(
                    "消す範囲の大きさを変更します",
                    "Adjust the eraser size"
                ))

                Text(L10n.text("なぞった部分を消去", "Erase where you drag"))
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize()
            } else {
                Divider()
                    .frame(height: 24)

                HStack(spacing: 4) {
                    ForEach(StageInkColorPreset.allCases, id: \.rawValue) { preset in
                        colorButton(preset)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(L10n.text("インクの色", "Ink color"))

                Divider()
                    .frame(height: 24)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.white.opacity(0.62))
                        .frame(width: 4, height: 4)
                        .accessibilityHidden(true)

                    Slider(
                        value: widthBinding,
                        in: StageInkPreferences.minimumNormalizedWidth ...
                            StageInkPreferences.maximumNormalizedWidth,
                        step: 0.001
                    )
                    .frame(width: 72)
                    .accessibilityLabel(L10n.text("線の太さ", "Stroke width"))
                    .accessibilityValue(widthAccessibilityValue)

                    Circle()
                        .fill(Color.white.opacity(0.82))
                        .frame(width: 11, height: 11)
                        .accessibilityHidden(true)
                }
                .help(L10n.text(
                    "描く線の太さを変更します",
                    "Adjust the width of new strokes"
                ))
            }
        }
    }

    private var toolBinding: Binding<StageInkTool> {
        Binding(
            get: { store.preferences.tool },
            set: { store.selectTool($0) }
        )
    }

    private var widthBinding: Binding<Double> {
        Binding(
            get: { store.preferences.normalizedWidth },
            set: { store.setNormalizedWidth($0) }
        )
    }

    private var eraserWidthBinding: Binding<Double> {
        Binding(
            get: { store.preferences.eraserNormalizedWidth },
            set: { store.setEraserNormalizedWidth($0) }
        )
    }

    private var widthAccessibilityValue: String {
        let referencePixels = Int((store.preferences.normalizedWidth * 1_080).rounded())
        return L10n.text(
            "1080ピクセル高のStageで約\(referencePixels)ピクセル",
            "About \(referencePixels) pixels on a 1080-pixel-high Stage"
        )
    }

    private var eraserWidthAccessibilityValue: String {
        let referencePixels = Int(
            (store.preferences.eraserNormalizedWidth * 1_080).rounded()
        )
        return L10n.text(
            "1080ピクセル高のStageで約\(referencePixels)ピクセル",
            "About \(referencePixels) pixels on a 1080-pixel-high Stage"
        )
    }

    private func colorButton(_ preset: StageInkColorPreset) -> some View {
        let isSelected = store.preferences.colorPreset == preset
        let baseColor = preset.color
        let color = Color(
            red: baseColor.red,
            green: baseColor.green,
            blue: baseColor.blue
        )

        return Button {
            store.selectColor(preset)
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                Circle()
                    .stroke(
                        isSelected ? Color.white : Color.white.opacity(0.30),
                        lineWidth: isSelected ? 2 : 1
                    )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(checkmarkColor(for: preset))
                }
            }
            .frame(width: 22, height: 22)
            .frame(width: 27, height: 28)
            .contentShape(Circle())
            .shadow(color: isSelected ? color.opacity(0.45) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(colorName(preset))
        .accessibilityValue(isSelected
            ? L10n.text("選択中", "Selected")
            : L10n.text("未選択", "Not selected"))
        .help(colorName(preset))
    }

    private func checkmarkColor(for preset: StageInkColorPreset) -> Color {
        switch preset {
        case .yellow, .white:
            Color.black.opacity(0.82)
        case .red, .green, .blue:
            .white
        }
    }

    private func toolName(_ tool: StageInkTool) -> String {
        switch tool {
        case .pen:
            L10n.text("ペン", "Pen")
        case .highlighter:
            L10n.text("蛍光ペン", "Highlighter")
        case .eraser:
            L10n.text("消しゴム", "Eraser")
        }
    }

    private func colorName(_ preset: StageInkColorPreset) -> String {
        switch preset {
        case .red:
            L10n.text("赤", "Red")
        case .yellow:
            L10n.text("黄", "Yellow")
        case .green:
            L10n.text("緑", "Green")
        case .blue:
            L10n.text("青", "Blue")
        case .white:
            L10n.text("白", "White")
        }
    }
}

private struct WorkspaceOutputStatus: View {
    let isStageVisible: Bool
    @ObservedObject var capture: CaptureCoordinator
    let compact: Bool
    let snapshotSourceCount: Int?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            if !compact {
                ViewThatFits(in: .horizontal) {
                    Text(statusTitle)
                        .lineLimit(1)
                    Text(shortStatusTitle)
                        .lineLimit(1)
                }
            }
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(Color.white.opacity(0.72))
        .padding(.horizontal, compact ? 8 : 9)
        .frame(minHeight: 27)
        .background(Color.white.opacity(0.055), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.09)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statusTitle)
        .accessibilityValue(statusDetail)
        .accessibilityHint(L10n.text(
            "会議アプリが実際に共有中かどうかを示すものではありません。",
            "This does not indicate whether a meeting app is actively sharing."
        ))
        .help(statusDetail)
    }

    private var statusColor: Color {
        if snapshotSourceCount != nil { return StagePanePalette.mintReadable }
        guard isStageVisible else { return .secondary }
        if captureNeedsAttention { return .orange }
        if allSourcesPaused { return .secondary }
        return capture.isCaptureActive
            ? StagePanePalette.mintReadable
            : StagePanePalette.aquaReadable
    }

    private var statusTitle: String {
        if let snapshotSourceCount {
            return L10n.text(
                "\(snapshotSourceCount)件の合成ソースをプレビュー",
                "Previewing \(snapshotSourceCount) Synthetic Sources"
            )
        }
        if !isStageVisible {
            return L10n.text("共有Stageは閉じています", "Share Stage Closed")
        }
        if captureNeedsAttention {
            return L10n.text("画面取得の確認が必要", "Capture Needs Attention")
        }
        if allSourcesPaused {
            return L10n.text("すべて一時停止中", "All Sources Paused")
        }
        switch capture.phase {
        case .choosing:
            return L10n.text("ソースを選択中", "Choosing a Source")
        case .preparing:
            return L10n.text("新しい映像を準備中", "Preparing Fresh Video")
        default:
            break
        }
        if capture.isCaptureActive {
            return L10n.text(
                "共有Stageを表示・\(capture.sources.count)件を取得中",
                "Share Stage Open · \(capture.sources.count) Source\(capture.sources.count == 1 ? "" : "s") Active"
            )
        }
        return L10n.text("共有Stageは待機中", "Share Stage Ready")
    }

    private var shortStatusTitle: String {
        if snapshotSourceCount != nil {
            return L10n.text("合成プレビュー", "Synthetic Preview")
        }
        if !isStageVisible { return L10n.text("Stage非表示", "Stage Closed") }
        if captureNeedsAttention { return L10n.text("確認が必要", "Needs Attention") }
        if allSourcesPaused { return L10n.text("一時停止中", "Paused") }
        if capture.isCaptureActive { return L10n.text("取得中", "Active") }
        return L10n.text("待機中", "Ready")
    }

    private var allSourcesPaused: Bool {
        !capture.sources.isEmpty && capture.sources.allSatisfy(\.isPaused)
    }

    private var captureNeedsAttention: Bool {
        if case .failed = capture.phase { return true }
        return false
    }

    private var statusDetail: String {
        if snapshotSourceCount != nil {
            return L10n.text(
                "公開用スクリーンショットの合成データです。画面取得は行っていません。",
                "Privacy-safe synthetic screenshot data; no screen capture is running."
            )
        }
        return capture.statusDetail
    }
}

private struct WorkspaceToolbarButtonStyle: ButtonStyle {
    var tint: Color?

    init(tint: Color? = nil) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint ?? Color.white.opacity(0.86))
            .padding(.horizontal, 10)
            .frame(minHeight: 31)
            .background(
                (tint ?? Color.white).opacity(configuration.isPressed ? 0.16 : 0.08),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke((tint ?? Color.white).opacity(0.12))
            }
    }
}

private struct WorkspaceNoticeToast: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(StagePanePalette.aqua)
                .padding(.top, 3)
                .accessibilityHidden(true)
            Text(message)
                .font(.caption.weight(.medium))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("通知を閉じる", "Dismiss notice"))
        }
        .foregroundStyle(.white)
        .padding(.leading, 13)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: 560, minHeight: 44)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(StagePanePalette.aqua.opacity(0.28))
        }
        .shadow(color: .black.opacity(0.35), radius: 15, y: 7)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.transientNotice")
    }
}
