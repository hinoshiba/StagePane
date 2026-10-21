import AppKit
import StagePaneCore
import SwiftUI

/// The private editor always keeps layers and canvas together. Audience content
/// is rendered in the separate, chrome-free Stage window.
struct StageWorkspaceView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    private let snapshotFixture: StageWorkspaceSnapshotFixture?
    @State private var isClearInkConfirmationPresented = false
    @State private var showsSharingGuide = false
    @AppStorage("workspace.layerRailWidth") private var savedLayerRailWidth = 232.0
    @State private var railDragStart: Double?

    init(
        controller: AppController,
        capture: CaptureCoordinator,
        snapshotFixture: StageWorkspaceSnapshotFixture? = nil
    ) {
        self.controller = controller
        self.capture = capture
        self.snapshotFixture = snapshotFixture
    }

    var body: some View {
        VStack(spacing: 0) {
            workspaceToolbar
            Divider()
            HStack(spacing: 0) {
                sourceRail.frame(width: layerRailWidth)
                railDivider
                stageWorkspace
                    .frame(minWidth: 550, maxWidth: .infinity, maxHeight: .infinity)
            }
            if let notice = controller.captureAccessIssueNotice {
                Divider()
                WorkspaceCaptureAccessIssueBanner(
                    notice: notice,
                    canRetry: controller.canRetryCaptureAccessIssue,
                    retry: controller.retryCaptureAccessIssue,
                    dismiss: { controller.dismissCaptureAccessIssue(id: notice.id) }
                )
                .id(notice.id)
            }
            Divider()
            sharingFooter
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) {
            if let notice = controller.transientNoticeState.notice {
                WorkspaceNoticeToast(message: notice.message) {
                    controller.dismissTransientNotice(id: notice.id)
                }
                .id(notice.id)
                .padding(.horizontal, 12)
                .padding(.top, 64)
                .transition(accessibilityReduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                .zIndex(20)
            }
        }
        .animation(accessibilityReduceMotion ? nil : .easeOut(duration: 0.2), value: controller.transientNoticeState.notice?.id)
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
            Text(L10n.text("共有Stageと編集画面からすべての線を削除します。", "Remove every line from the audience Stage and editor."))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("StagePane 編集画面", "StagePane editor"))
    }

    private var workspaceToolbar: some View {
        HStack(spacing: 14) {
            Button(action: controller.chooseSource) {
                Label(
                    requiresProForSourceAddition ? L10n.text("Proで追加", "Add with Pro") : L10n.text("ソースを追加", "Add Source"),
                    systemImage: requiresProForSourceAddition ? "lock.open" : "plus"
                )
            }
            .disabled(!controller.canRequestSourceAddition)
            .help(requiresProForSourceAddition
                ? L10n.text("StagePane Proでソース数の上限を解除します（⇧⌘P）", "Open StagePane Pro to remove the source limit (⇧⌘P)")
                : L10n.text("共有するウインドウや画面を選びます（⇧⌘P）", "Choose a window or display to share (⇧⌘P)"))

            Spacer(minLength: 0)
            HStack(spacing: 2) {
                ForEach(globalInteractionModes, id: \.rawValue) { mode in
                    Button {
                        controller.setStageInteractionMode(mode)
                    } label: {
                        Label(L10n.stageInteractionModeName(mode), systemImage: modeSymbol(mode))
                            .padding(.horizontal, 9)
                            .frame(height: 28)
                            .background(controller.stageInteractionMode == mode ? Color.accentColor.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(controller.stageInteractionMode == mode ? Color.accentColor : Color.primary)
                    .accessibilityValue(controller.stageInteractionMode == mode ? L10n.text("選択中", "Selected") : "")
                    .help(L10n.stageInteractionModeDetail(mode))
                }
            }
            .padding(3)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.text("編集モード", "Editing mode"))
            Spacer(minLength: 0)

            Button(action: controller.toggleCurtain) {
                Label(curtainButtonTitle, systemImage: curtainButtonSymbol)
            }
            .tint(controller.privacyCurtain ? .orange : .accentColor)
            .accessibilityValue(controller.privacyCurtain ? L10n.text("カーテン中。カーテンは画面取得を停止しません", "Curtain on. Curtain does not stop capture") : L10n.text("カーテンは開いています", "Curtain is open"))
            .help(L10n.text("観客向けの映像を隠します。画面取得を停止する操作ではありません（⇧⌘H）", "Hide audience content. This does not stop capture (⇧⌘H)"))

            HStack(spacing: 3) {
                Button(action: controller.showStage) {
                    Label(L10n.text("Stageを表示", "Show Stage"), systemImage: "macwindow")
                }
                .help(L10n.text("会議で共有するStageウインドウを表示（⌘2）", "Open the audience Stage window (⌘2)"))
                stageWindowMenu
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .font(.system(size: 12, weight: .medium))
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("編集ツールバー", "Editor toolbar"))
    }

    private var stageWindowMenu: some View {
        Menu {
            Button(action: controller.enlargeStageForSharing) {
                Label(L10n.text("共有しやすい大きさに拡大", "Enlarge for Sharing"), systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(controller.stageIsFullScreen || controller.stageFullScreenTransitionInProgress)
            Button(action: controller.toggleStageFullScreen) {
                Label(controller.stageIsFullScreen ? L10n.text("フルスクリーンを終了", "Exit Full Screen") : L10n.text("フルスクリーンにする", "Enter Full Screen"), systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(!controller.stageIsVisible || controller.stageFullScreenTransitionInProgress)
            Divider()
            Button(action: controller.copyStageScreenshot) {
                Label(L10n.text("Audience画像をコピー", "Copy Audience Image"), systemImage: "doc.on.clipboard")
            }
            .disabled(controller.isStageScreenshotInProgress || controller.stageFullScreenTransitionInProgress)
            Button(action: controller.saveStageScreenshot) {
                Label(L10n.text("Audience画像を保存…", "Save Audience Image…"), systemImage: "square.and.arrow.down")
            }
            .disabled(controller.isStageScreenshotInProgress || controller.stageFullScreenTransitionInProgress)
        } label: {
            Image(systemName: "chevron.down")
                .frame(width: 16, height: 26)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel(L10n.text("Stageウインドウの操作", "Stage window actions"))
        .help(L10n.text("Stageの表示と画像の保存", "Stage display and audience images"))
    }

    private var layerRailWidth: Double {
        snapshotFixture != nil ? 232 : min(300, max(220, savedLayerRailWidth))
    }

    private var railDivider: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: 1)
            .overlay {
                Color.clear
                    .frame(width: 9)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        (hovering ? NSCursor.resizeLeftRight : NSCursor.arrow).set()
                    }
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if railDragStart == nil { railDragStart = layerRailWidth }
                            savedLayerRailWidth = min(300, max(220, (railDragStart ?? 232) + value.translation.width))
                        }
                        .onEnded { _ in railDragStart = nil })
            }
            .focusable()
            .onMoveCommand { direction in
                if direction == .left { savedLayerRailWidth = max(220, layerRailWidth - 10) }
                if direction == .right { savedLayerRailWidth = min(300, layerRailWidth + 10) }
            }
            .accessibilityRepresentation {
                Slider(
                    value: Binding(get: { layerRailWidth }, set: { savedLayerRailWidth = min(300, max(220, $0)) }),
                    in: 220...300
                ) {
                    Text(L10n.text("レイヤー欄の幅", "Layer list width"))
                }
                .accessibilityValue(L10n.text("\(Int(layerRailWidth))ポイント", "\(Int(layerRailWidth)) points"))
                .accessibilityHint(L10n.text("左右キーまたはドラッグで調整します。", "Adjust with Left and Right or drag."))
            }
    }

    private var sourceRail: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Text(L10n.text("レイヤー", "Layers"))
                    .font(.system(size: 13, weight: .semibold))
                Text(controller.activeSourceLimit.map { "\(displayedSourceCount) / \($0)" } ?? "\(displayedSourceCount)")
                    .foregroundStyle(.secondary)
                    .font(.caption.monospacedDigit())
                    .accessibilityLabel(controller.sourceCountAccessibilityDescription(displayedSourceCount))
                Spacer()
                layerActionsMenu
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            if snapshotFixture?.hasCanvasComposition == true {
                SnapshotSourceRailList(fixture: snapshotFixture ?? .arrange)
                    .padding(.horizontal, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                CaptureSourceList(controller: controller, capture: capture, showsHeading: false, expandsSourceList: true, usesSecondaryAddAction: true)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("レイヤー一覧", "Layer list"))
    }

    private var layerActionsMenu: some View {
        Menu {
            Button(role: .destructive, action: controller.stopPreview) {
                Label(capture.hasResettableFailure ? L10n.text("画面取得をリセット", "Reset Capture") : L10n.stopAllAndRemoveLayersTitle, systemImage: capture.hasResettableFailure ? "arrow.counterclockwise" : "stop.fill")
            }
            .disabled((!capture.hasLayers && !capture.isCaptureActive && !capture.hasResettableFailure) || capture.isPickerPresented)
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 28, height: 28)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel(L10n.text("全レイヤーの操作", "All layer actions"))
        .help(L10n.stopAllAndRemoveLayersTitle)
    }

    private var stageWorkspace: some View {
        VStack(spacing: 0) {
            canvasHeader
            fittedStageCanvas
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            if controller.stageInteractionMode != .arrange || controller.selectedSourceID != nil || snapshotFixture != nil {
                Divider()
                contextualDock
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var canvasHeader: some View {
        HStack(spacing: 12) {
            WorkspaceOutputStatus(controller: controller, capture: capture, snapshotSourceCount: snapshotFixture?.sourceCount)
            Spacer(minLength: 8)
            layoutMenu
        }
        .font(.caption)
        .buttonStyle(.borderless)
        .padding(.horizontal, 20)
        .frame(height: 40)
    }

    private var layoutMenu: some View {
        Menu {
            layoutPresetButton(.grid, title: L10n.text("グリッド", "Grid"), symbol: "square.grid.2x2")
            layoutPresetButton(.sideBySide, title: L10n.text("横に並べる", "Side by Side"), symbol: "rectangle.split.2x1")
            layoutPresetButton(.stacked, title: L10n.text("縦に並べる", "Stacked"), symbol: "rectangle.split.1x2")
            layoutPresetButton(.pictureInPicture, title: L10n.text("ピクチャーインピクチャ", "Picture in Picture"), symbol: "rectangle.inset.filled")
        } label: {
            Label(L10n.text("レイアウト", "Layout"), systemImage: "square.grid.2x2")
        }
        .disabled((capture.sources.isEmpty && snapshotFixture == nil) || capture.isPickerPresented || controller.stageInteractionMode == .crop)
        .fixedSize()
        .help(L10n.text("すべてのレイヤーを並べ直します", "Rearrange all layers"))
    }

    private var fittedStageCanvas: some View {
        GeometryReader { proxy in
            let canvasSize = fittedCanvasSize(in: CGSize(width: max(0, proxy.size.width - 2), height: max(0, proxy.size.height - 2)))
            Group {
                if snapshotFixture == .product {
                    SnapshotProductComposition(showsEditingChrome: true, theme: controller.theme, showsWatermark: controller.showsWatermark)
                } else if let snapshotFixture, snapshotFixture.hasCanvasComposition {
                    SnapshotStageComposition(showsDrawing: snapshotFixture == .draw, theme: controller.theme, showsWatermark: controller.showsWatermark)
                } else {
                    StageLayoutEditor(controller: controller, capture: capture, allowsEditingShortcuts: usesEditingShortcuts)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.14), radius: 12, y: 5)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("編集キャンバス", "Editing canvas"))
    }

    private var contextualDock: some View {
        HStack(spacing: 10) {
            if controller.stageInteractionMode == .arrange {
                if snapshotFixture?.hasCanvasComposition == true {
                    SnapshotSelectedLayerTools(fixture: snapshotFixture ?? .arrange)
                } else {
                    SelectedLayerTools(controller: controller, capture: capture)
                }
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        switch controller.stageInteractionMode {
                        case .arrange:
                            EmptyView()
                        case .crop:
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cropEditingLayerTitle).fontWeight(.medium).lineLimit(1)
                                Text(L10n.cropDraftStatusTitle).font(.caption2).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: 180, alignment: .leading)
                            Image(systemName: "info.circle")
                                .help("\(L10n.cropCaptureScopeCompact) \(L10n.cropCaptureScopeDetail)")
                                .accessibilityLabel(L10n.cropCaptureScopeCompact)
                                .accessibilityHint(L10n.cropCaptureScopeDetail)
                            Button(action: controller.resetCropDraft) {
                                Label(L10n.cropResetDraftTitle, systemImage: "arrow.counterclockwise")
                            }
                            .disabled(controller.cropDraft == nil || controller.cropDraft == .fullSource)
                        case .magnify:
                            StageMagnifierToolShelf(store: controller.magnifier, beginInteraction: controller.beginWorkspaceInteraction)
                                .disabled(!capture.isCaptureActive)
                            Button {
                                controller.setStageInteractionMode(.arrange)
                            } label: {
                                Label(L10n.text("虫眼鏡を終了", "Exit Magnify"), systemImage: "checkmark")
                            }
                            .keyboardShortcut(usesEditingShortcuts ? .cancelAction : nil)
                        case .annotate:
                            StageInkToolShelf(store: controller.annotations, beginInteraction: controller.beginWorkspaceInteraction)
                            Button {
                                controller.beginWorkspaceInteraction()
                                controller.annotations.undo()
                            } label: {
                                Label(L10n.text("取り消す", "Undo"), systemImage: "arrow.uturn.backward")
                            }
                            .disabled(!controller.hasAnnotations && snapshotFixture != .draw)
                            .keyboardShortcut(usesEditingShortcuts ? KeyboardShortcut("z", modifiers: [.command]) : nil)
                            Button(role: .destructive) {
                                controller.beginWorkspaceInteraction()
                                isClearInkConfirmationPresented = true
                            } label: {
                                Label(L10n.text("すべて消す", "Clear All"), systemImage: "trash")
                            }
                            .disabled(!controller.hasAnnotations && snapshotFixture != .draw)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minHeight: 54)
                }
                .scrollIndicators(.visible)
                if controller.stageInteractionMode == .crop {
                    cropCompletionActions
                }
            }
        }
        .font(.caption)
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .padding(.horizontal, 14)
        .frame(height: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.text("現在の編集ツール", "Current editing tools"))
    }

    private var sharingFooter: some View {
        HStack(spacing: 6) {
            Text(L10n.text("会議では「StagePane Stage」を共有", "Share “StagePane Stage” in your meeting"))
                .lineLimit(1)
            Spacer()
            Button(L10n.text("共有ガイド", "Sharing Guide")) { showsSharingGuide.toggle() }
                .popover(isPresented: $showsSharingGuide, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L10n.text("会議にはStageを共有", "Share the Stage in your meeting"))
                            .font(.headline)
                        Text(L10n.text("会議アプリで「StagePane Stage」ウインドウを選択してください。この編集画面も共有一覧に表示される場合があります。", "Choose the “StagePane Stage” window in your meeting app. This editor may also appear in its share picker."))
                        Text(L10n.text("カーテンは観客向けの映像を隠します。画面取得は継続します。", "Curtain hides audience content. Capture continues."))
                            .foregroundStyle(.secondary)
                        Button(action: controller.requestConferenceShare) {
                            Label(L10n.text("共有先をStageへ", "Switch Share to Stage"), systemImage: "arrow.up.forward.app")
                        }
                        Text(L10n.text("対応する会議アプリへ切り替えを要求します。共有中かどうかは会議アプリで確認してください。", "Requests a switch in compatible meeting apps. Check sharing status in your meeting app."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(width: 340)
                }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .frame(height: 32)
    }

    private var cropCompletionActions: some View {
        HStack(spacing: 8) {
            Button(role: .cancel) {
                controller.cancelCropEditing()
            } label: {
                Text(L10n.cropCancelTitle)
            }
            .keyboardShortcut(usesEditingShortcuts ? .cancelAction : nil)

            Button {
                controller.applyCropEditing()
            } label: {
                Label(L10n.cropApplyTitle, systemImage: "checkmark")
            }
            .keyboardShortcut(usesEditingShortcuts ? .defaultAction : nil)
            .tint(StagePanePalette.indigo)
            .disabled(!controller.canApplyCropEditing)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .font(.caption.weight(.semibold))
        .fixedSize()
    }

    private var usesEditingShortcuts: Bool {
        !showsSharingGuide
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

    private var curtainButtonTitle: String {
        controller.privacyCurtain
            ? L10n.text("カーテンを開く", "Open Curtain")
            : L10n.text("カーテンを閉じる", "Close Curtain")
    }

    private var curtainButtonSymbol: String {
        controller.privacyCurtain ? "eye.fill" : "shield.lefthalf.filled"
    }

    private func modeSymbol(_ mode: StageInteractionMode) -> String {
        switch mode {
        case .arrange: "rectangle.3.group"
        case .crop: "crop"
        case .annotate: "pencil.tip"
        case .magnify: "plus.magnifyingglass"
        }
    }

    private func layoutPresetButton(
        _ preset: StageLayoutPreset,
        title: String,
        symbol: String
    ) -> some View {
        Button {
            controller.beginWorkspaceInteraction()
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

    private var displayedSourceCount: Int {
        snapshotFixture?.sourceCount ?? capture.sources.count
    }

    private var requiresProForSourceAddition: Bool {
        StagePaneAccess.requiresProForNextSource(
            currentCount: capture.occupiedSourceSlots,
            hasProAccess: controller.hasProAccess
        )
    }
}

private struct StageMagnifierToolShelf: View {
    @ObservedObject var store: StageMagnifierStore
    let beginInteraction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Picker(L10n.text("拡大倍率", "Magnification"), selection: Binding(get: { store.magnification }, set: { beginInteraction(); store.magnification = $0 })) {
                Text("2×").tag(2.0)
                Text("3×").tag(3.0)
                Text("4×").tag(4.0)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 160)
            .accessibilityLabel(L10n.text("拡大倍率", "Magnification"))
            .help(L10n.text("虫眼鏡の拡大倍率", "Magnifier zoom level"))

            Button {
                beginInteraction()
                store.center()
            } label: {
                Label(L10n.text("中央に表示", "Show at Center"), systemImage: "scope")
            }
            .help(L10n.text(
                "キャンバスにカーソルを置くと追従します。矢印キーでも移動できます。",
                "The lens follows the pointer over the canvas. Arrow keys also move it."
            ))
        }
    }
}

private struct StageInkToolShelf: View {
    @ObservedObject var store: StageAnnotationStore
    let beginInteraction: () -> Void

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
            .accessibilityHint(store.preferences.tool == .eraser
                ? L10n.text("なぞった部分を消去します。", "Erases where you drag.")
                : "")

            if store.preferences.tool == .eraser {
                Divider()
                    .frame(height: 24)

                HStack(spacing: 5) {
                    Circle()
                        .stroke(Color.secondary, lineWidth: 1)
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
                        .stroke(Color.primary, lineWidth: 1.5)
                        .frame(width: 15, height: 15)
                        .accessibilityHidden(true)
                }
                .help(L10n.text(
                    "なぞった部分を消去します。消しゴムの大きさを変更できます。",
                    "Erases where you drag. Adjust the eraser size."
                ))
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
                        .fill(Color.secondary)
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
                        .fill(Color.primary)
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
            set: { beginInteraction(); store.selectTool($0) }
        )
    }

    private var widthBinding: Binding<Double> {
        Binding(
            get: { store.preferences.normalizedWidth },
            set: { beginInteraction(); store.setNormalizedWidth($0) }
        )
    }

    private var eraserWidthBinding: Binding<Double> {
        Binding(
            get: { store.preferences.eraserNormalizedWidth },
            set: { beginInteraction(); store.setEraserNormalizedWidth($0) }
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
            beginInteraction()
            store.selectColor(preset)
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                Circle()
                    .stroke(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.30),
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
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    let snapshotSourceCount: Int?

    var body: some View {
        HStack(spacing: 10) {
            Label(statusTitle, systemImage: statusSymbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(controller.privacyCurtain && controller.stageIsVisible ? Color.orange : Color.primary)
            if needsAttention {
                Label(L10n.text("要確認", "Needs attention"), systemImage: "exclamationmark.circle")
                    .foregroundStyle(.orange)
            }
        }
        .lineLimit(1)
        .help("\(captureTitle)\n\(statusDetail)")
        .accessibilityElement(children: .combine)
        .accessibilityValue(captureTitle)
        .accessibilityHint(statusDetail)
    }

    private var statusSymbol: String {
        if !controller.stageIsVisible && snapshotSourceCount == nil { return "macwindow" }
        if controller.privacyCurtain { return "shield.lefthalf.filled" }
        return "rectangle.on.rectangle"
    }

    private var statusTitle: String {
        if snapshotSourceCount != nil {
            return controller.privacyCurtain ? L10n.text("Stage · カーテン中", "Stage · Curtain On") : L10n.text("Stage · コンテンツ", "Stage · Content")
        }
        if controller.stageIsMiniaturized { return L10n.text("Stage · 最小化中", "Stage · Minimized") }
        guard controller.stageIsVisible else { return L10n.text("Stage · 閉じています", "Stage · Closed") }
        if controller.privacyCurtain { return L10n.text("Stage · カーテン中", "Stage · Curtain On") }
        if !capture.isCaptureActive { return L10n.text("Stage · 待機画面", "Stage · Holding Screen") }
        if capture.sources.contains(where: \.isPresentationVisible) { return L10n.text("Stage · コンテンツ", "Stage · Content") }
        if capture.sources.contains(where: { $0.phase == .preparing || $0.phase == .resuming }) {
            return L10n.text("Stage · 映像を準備中", "Stage · Preparing Video")
        }
        return L10n.text("Stage · 映像なし", "Stage · No Video")
    }

    private var needsAttention: Bool {
        if snapshotSourceCount != nil { return false }
        if case .failed = capture.phase { return true }
        return capture.sources.contains { capture.attentionSummary(for: $0.id) != nil }
    }

    private var captureTitle: String {
        if snapshotSourceCount != nil {
            return L10n.text("合成プレビュー · 画面取得なし", "Synthetic preview · no capture")
        }
        let count = capture.runningSourceCount
        let activity = count > 0
            ? L10n.text("\(count)件を画面取得中", "Capturing \(count) source\(count == 1 ? "" : "s")")
            : L10n.text("画面取得なし", "No capture running")
        if needsAttention { return activity + L10n.text(" · 要確認", " · Needs attention") }
        if capture.isPickerPresented { return activity + L10n.text(" · 選択中", " · Choosing") }
        return activity
    }

    private var statusDetail: String {
        let hint = L10n.text("会議アプリで共有中かどうかを示すものではありません。", "This does not indicate whether a meeting app is sharing.")
        if snapshotSourceCount != nil { return L10n.text("合成プレビューです。画面取得は行っていません。", "Synthetic preview. No screen capture is running.") }
        return "\(capture.statusDetail) \(hint)"
    }
}

private struct WorkspaceCaptureAccessIssueBanner: View {
    let notice: CaptureAccessIssueNotice
    let canRetry: Bool
    let retry: () -> Void
    let dismiss: () -> Void
    @State private var showsDetails = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Label(notice.issue.title, systemImage: "exclamationmark.circle")
                    .font(.callout.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h2)
                Spacer(minLength: 8)
                Button(L10n.text("もう一度試す", "Try Again"), action: retry)
                    .disabled(!canRetry)
                    .help(L10n.text(
                        "切り抜きやソース選択を終えてから再試行できます。",
                        "Finish cropping or source selection before trying again."
                    ))
                Button(L10n.text("閉じる", "Dismiss"), action: dismiss)
            }
            DisclosureGroup(L10n.text("詳細", "Details"), isExpanded: $showsDetails) {
                ScrollView {
                    Text(notice.issue.detail)
                        .font(.callout)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 76)
                .accessibilityLabel(L10n.text("画面取得エラーの詳細", "Capture error details"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.captureAccessIssue")
    }
}

private struct WorkspaceNoticeToast: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.accentColor)
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
        .foregroundStyle(.primary)
        .padding(.leading, 13)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: 560, minHeight: 44)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.accentColor.opacity(0.28))
        }
        .shadow(color: .black.opacity(0.35), radius: 15, y: 7)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workspace.transientNotice")
    }
}
