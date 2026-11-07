import StagePaneCore
import SwiftUI

/// Private navigation selects an editor; audience routing is an explicit action.
struct StageScreenGroupRail: View {
    @ObservedObject var controller: AppController
    @Binding var isCollapsed: Bool
    var usesSnapshotFixture = false
    @State private var renamingGroup: StageScreenGroup?
    @State private var deletingGroup: StageScreenGroup?
    @State private var draftName = ""
    @FocusState private var focusedGroupID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                if !isCollapsed {
                    Text(L10n.text("画面", "Screens"))
                        .font(.system(size: 12, weight: .semibold))
                    Spacer(minLength: 0)
                }
                WorkspaceRailToggle(isCollapsed: $isCollapsed, title: L10n.text("画面", "Screens"))
            }
            .padding(.horizontal, isCollapsed ? 4 : 12)
            .frame(height: 54)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(controller.screenGroups) { group in
                            groupTab(group).id(group.id)
                        }
                    }
                    .padding(isCollapsed ? 6 : 8)
                }
                .onChange(of: controller.activeScreenGroupID) { _, id in
                    if !usesSnapshotFixture { proxy.scrollTo(id, anchor: .center) }
                }
                .onAppear {
                    if !usesSnapshotFixture { proxy.scrollTo(controller.activeScreenGroupID, anchor: .center) }
                }
            }
            Divider()
            HStack(spacing: 4) {
                if !isCollapsed {
                    groupCountLabel
                    Spacer(minLength: 0)
                }
                addScreenButton
            }
            .padding(.horizontal, isCollapsed ? 4 : 12)
            .padding(.top, 6)
            if isCollapsed { groupCountLabel.padding(.bottom, 7) }
            else { Spacer().frame(height: 6) }
        }
        .frame(width: isCollapsed ? 64 : 136)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("画面のタブ", "Screen tabs"))
        .alert(L10n.text("画面名を変更", "Rename Screen"), isPresented: Binding(
            get: { renamingGroup != nil }, set: { if !$0 { renamingGroup = nil } }
        )) {
            TextField(L10n.text("画面名", "Screen name"), text: $draftName)
            Button(L10n.text("保存", "Save")) {
                if let group = renamingGroup { controller.renameScreenGroup(group.id, to: draftName) }
                renamingGroup = nil
            }
            Button(L10n.text("キャンセル", "Cancel"), role: .cancel) { renamingGroup = nil }
        }
        .confirmationDialog(
            L10n.text("この画面を削除しますか？", "Delete this screen?"),
            isPresented: Binding(get: { deletingGroup != nil }, set: { if !$0 { deletingGroup = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.text("画面を削除", "Delete Screen"), role: .destructive) {
                if let group = deletingGroup { controller.removeScreenGroup(group.id) }
                deletingGroup = nil
            }
            Button(L10n.text("キャンセル", "Cancel"), role: .cancel) { deletingGroup = nil }
        } message: {
            Text(deletionDetail)
        }
    }

    private var deletionDetail: String {
        let detail = L10n.text(
            "「\(deletingGroup?.title ?? "")」の取得を停止し、レイヤーと手書きを削除します。",
            "Stop capture in “\(deletingGroup?.title ?? "")” and remove its layers and drawings."
        )
        guard deletingGroup?.id == controller.outputScreenGroupID else { return detail }
        return detail + "\n\n" + L10n.text(
            "Stage出力中のため、カーテンを閉じて別の画面に切り替えます。",
            "This is the Stage output. The Curtain will close before switching to another screen."
        )
    }

    private var requiresPro: Bool {
        controller.activeScreenGroupLimit == StagePaneAccess.freeScreenGroupLimit &&
            controller.screenGroups.count >= controller.activeScreenGroupLimit
    }

    private var groupCountLabel: some View {
        Text("\(controller.screenGroups.count) / \(controller.activeScreenGroupLimit)")
            .font(.system(size: 10).monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel(L10n.text(
                "画面 \(controller.screenGroups.count)個、上限\(controller.activeScreenGroupLimit)個",
                "\(controller.screenGroups.count) screens, limit \(controller.activeScreenGroupLimit)"
            ))
    }

    private var addScreenButton: some View {
        Button {
            let previousCount = controller.screenGroups.count
            controller.requestScreenGroupAddition()
            if controller.screenGroups.count > previousCount {
                focusedGroupID = controller.activeScreenGroupID
            }
        } label: {
            Image(systemName: "plus").font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .disabled(!controller.canChangeScreenGroup || controller.screenGroups.count >= StagePaneAccess.proScreenGroupLimit)
        .accessibilityLabel(requiresPro
            ? L10n.text("Proで画面を追加", "Add a screen with Pro")
            : L10n.text("画面を追加", "Add screen"))
        .help(L10n.text("画面を追加。無料版は2個、Proは10個まで作成できます。", "Add a screen. Create up to 2 with Free or 10 with Pro."))
    }

    private func groupTab(_ group: StageScreenGroup) -> some View {
        let selected = controller.activeScreenGroupID == group.id
        let output = controller.outputScreenGroupID == group.id
        let available = controller.isScreenGroupAvailable(group.id)
        return VStack(spacing: 5) {
            Button {
                if available {
                    if controller.selectScreenGroup(group.id) { focusedGroupID = group.id }
                } else {
                    controller.showProUpgrade()
                }
            } label: {
                ScreenGroupTabLabel(
                    group: group, output: output, available: available,
                    usesSnapshotFixture: usesSnapshotFixture, isCompact: isCollapsed,
                    ordinal: (controller.screenGroups.firstIndex(where: { $0.id == group.id }) ?? 0) + 1,
                    isCurtainOn: controller.privacyCurtain
                )
            }
            .buttonStyle(.plain)
            .focusable()
            .focused($focusedGroupID, equals: group.id)
            .disabled(!controller.canChangeScreenGroup)
            .accessibilityLabel(group.title)
            .accessibilityValue([
                selected ? L10n.text("編集中", "Editing") : "",
                output ? L10n.text("Stage出力", "Stage output") : L10n.text("プレビュー", "Preview"),
                available ? "" : L10n.text("Proが必要", "Requires Pro"),
                group.capture.isCaptureActive ? L10n.text("取得中", "Capturing") : ""
            ].filter { !$0.isEmpty }.joined(separator: ", "))
            .accessibilityHint(L10n.text("プレビューを選びます。上下キーでも選べます。Stage出力の切り替えは「Stageに出す」を使います。", "Select a preview, also using Up and Down. Use Send to Stage to switch the output."))
            .help(tabHelp(group, output: output))
            .contextMenu { groupActions(group) }
            .accessibilityAction(named: L10n.text("名前を変更", "Rename")) {
                guard controller.canChangeScreenGroup else { return }
                draftName = group.title
                renamingGroup = group
            }
            .onMoveCommand { direction in
                guard direction == .up || direction == .down,
                      let index = controller.screenGroups.firstIndex(where: { $0.id == group.id }) else { return }
                let next = index + (direction == .up ? -1 : 1)
                guard controller.screenGroups.indices.contains(next) else { return }
                let id = controller.screenGroups[next].id
                if controller.selectScreenGroup(id) { focusedGroupID = id }
            }

            if !isCollapsed {
                HStack(spacing: 3) {
                    if output {
                        Label(L10n.text("Stage出力", "On Stage"), systemImage: controller.privacyCurtain ? "shield.lefthalf.filled" : "circle.fill")
                            .foregroundStyle(StagePanePalette.coralReadable)
                            .help(controller.privacyCurtain
                                ? L10n.text("Stageの出力先です。カーテンで内容を隠しています。", "Routed to Stage. The Curtain is hiding its content.")
                                : L10n.text("Stageの出力先です。会議アプリで共有中かどうかは検知しません。", "Routed to Stage. Meeting-app sharing is not detected."))
                    } else if selected {
                        Text(L10n.text("プレビュー", "Preview")).foregroundStyle(Color.accentColor)
                    } else if group.capture.isCaptureActive {
                        Text(L10n.text("取得中", "Capturing")).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Menu { groupActions(group) } label: {
                        Image(systemName: "ellipsis").frame(width: 18, height: 16)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .accessibilityLabel(L10n.text("\(group.title)の操作", "Actions for \(group.title)"))
                    .disabled(!controller.canChangeScreenGroup)
                }
                .font(.system(size: 10, weight: .medium))
                .frame(height: 16)
            }
        }
        .padding(isCollapsed ? 4 : 6)
        .background(selected ? Color.accentColor.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .leading) {
            if selected {
                RoundedRectangle(cornerRadius: 1).fill(Color.accentColor)
                    .frame(width: 2).padding(.vertical, 6).offset(x: -4)
            }
        }
    }

    private func tabHelp(_ group: StageScreenGroup, output: Bool) -> String {
        let status: String
        if output {
            status = controller.privacyCurtain
                ? L10n.text("Stage出力 · カーテン中", "Stage output · Curtain on")
                : L10n.text("Stage出力", "Stage output")
        } else {
            status = L10n.text("プレビュー", "Preview")
        }
        return [group.title, status, L10n.text(
            "クリックで編集。右クリックで名前変更・削除。",
            "Click to edit. Right-click to rename or delete."
        )].joined(separator: "\n")
    }

    @ViewBuilder
    private func groupActions(_ group: StageScreenGroup) -> some View {
        Button(L10n.text("名前を変更…", "Rename…")) {
            draftName = group.title
            renamingGroup = group
        }
        Button(L10n.text("画面を削除…", "Delete Screen…"), role: .destructive) {
            deletingGroup = group
        }
        .disabled(controller.screenGroups.count <= 1)
    }
}

private struct ScreenGroupTabLabel: View {
    @ObservedObject var group: StageScreenGroup
    @ObservedObject private var capture: CaptureCoordinator
    let output: Bool
    let available: Bool
    let usesSnapshotFixture: Bool
    let isCompact: Bool
    let ordinal: Int
    let isCurtainOn: Bool

    init(group: StageScreenGroup, output: Bool, available: Bool, usesSnapshotFixture: Bool,
         isCompact: Bool, ordinal: Int, isCurtainOn: Bool) {
        self.group = group
        self.capture = group.capture
        self.output = output
        self.available = available
        self.usesSnapshotFixture = usesSnapshotFixture
        self.isCompact = isCompact
        self.ordinal = ordinal
        self.isCurtainOn = isCurtainOn
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 7) {
            GeometryReader { proxy in
                let width = min(proxy.size.width, proxy.size.height * group.preset.aspectRatio)
                let height = width / group.preset.aspectRatio
                ZStack {
                    Color.black.opacity(0.10)
                    layoutThumbnail
                        .frame(width: width, height: height)
                }
            }
            .frame(height: isCompact ? 28 : 62)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(output ? StagePanePalette.coralReadable : Color.primary.opacity(0.18), lineWidth: output ? 2 : 1)
            }
            .accessibilityHidden(true)
            HStack(spacing: 4) {
                Text(isCompact ? "\(ordinal)" : group.title)
                    .font(.system(size: isCompact ? 10 : 11, weight: .medium).monospacedDigit())
                    .lineLimit(1)
                Spacer(minLength: 0)
                if !available {
                    Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(.secondary)
                } else if needsAttention {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundStyle(.orange)
                } else if isCompact && output {
                    Image(systemName: isCurtainOn ? "shield.lefthalf.filled" : "circle.fill")
                        .font(.system(size: 9)).foregroundStyle(StagePanePalette.coralReadable)
                }
            }
        }
        .contentShape(Rectangle())
    }

    // Schematic only: never attach a source's display layer to another view,
    // take screenshots of sources, or start additional capture streams for tabs.
    private var layoutThumbnail: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                StageBackground(theme: group.theme)
                ForEach(Array(thumbnailFrames.enumerated()), id: \.offset) { index, frame in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(group.theme.prefersDarkForeground ? Color.black.opacity(0.12 + Double(index) * 0.05) : Color.white.opacity(0.20 + Double(index) * 0.08))
                        .overlay(alignment: .top) {
                            Rectangle().fill(.white.opacity(0.18)).frame(height: 3)
                        }
                        .frame(width: proxy.size.width * frame.width, height: proxy.size.height * frame.height)
                        .position(x: proxy.size.width * (frame.x + frame.width / 2), y: proxy.size.height * (frame.y + frame.height / 2))
                }
                if thumbnailFrames.isEmpty {
                    Image(systemName: "macwindow")
                        .font(.system(size: isCompact ? 13 : 20, weight: .light))
                        .foregroundStyle(group.theme.prefersDarkForeground ? .black.opacity(0.28) : .white.opacity(0.38))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipped()
        }
    }

    private var thumbnailFrames: [NormalizedStageRect] {
        if usesSnapshotFixture {
            return [
                NormalizedStageRect(x: 0.58, y: 0.53, width: 0.36, height: 0.34),
                NormalizedStageRect(x: 0.06, y: 0.09, width: 0.60, height: 0.78)
            ]
        }
        return capture.layout.sources.filter { capture.source(for: $0.id)?.isPresentationVisible == true }.map(\.frame)
    }

    private var needsAttention: Bool {
        if case .failed = capture.phase { return true }
        return capture.hasDisconnectedLayers
    }
}
