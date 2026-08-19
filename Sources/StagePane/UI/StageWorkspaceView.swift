import StagePaneCore
import SwiftUI

/// A private, large-format workspace for composing and operating the audience Stage.
///
/// This view deliberately uses the preview renderers through `StageLayoutEditor`.
/// The shareable `StageView` remains a separate, chrome-free window, so workspace
/// controls can never become part of the intended audience output.
struct StageWorkspaceView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    @State private var isSourceRailVisible = true
    @State private var isClearInkConfirmationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            workspaceToolbar
            privateWorkspaceWarning

            if let notice = controller.transientNotice {
                WorkspaceNoticeBanner(message: notice) {
                    controller.dismissTransientNotice()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            ViewThatFits(in: .horizontal) {
                wideWorkspace
                compactWorkspace
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

            Button(action: controller.showControlRoom) {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(WorkspaceToolbarButtonStyle())
            .accessibilityLabel(L10n.text(
                "設定・コントロールルームを開く",
                "Open Settings and Control Room"
            ))
            .help(L10n.text(
                "設定とアクセス権限をコントロールルームで確認します",
                "Review settings and access permissions in the Control Room"
            ))

            WorkspaceOutputStatus(
                isStageVisible: controller.stageIsVisible,
                capture: capture,
                compact: compact
            )

            Spacer(minLength: 8)

            Picker(
                L10n.text("ワークスペースのモード", "Workspace mode"),
                selection: interactionModeBinding
            ) {
                ForEach(controller.availableStageInteractionModes, id: \.rawValue) { mode in
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
                minWidth: compact ? 210 : 246,
                idealWidth: compact ? 230 : 310,
                maxWidth: compact ? 246 : 340
            )
            .accessibilityLabel(L10n.text(
                "ワークスペースのモード",
                "Workspace mode"
            ))
            .accessibilityValue(L10n.stageInteractionModeName(
                controller.stageInteractionMode
            ))
            .accessibilityHint(L10n.stageInteractionModeDetail(
                controller.stageInteractionMode
            ))

            Spacer(minLength: 8)

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
                Text("\(capture.sources.count) / \(CaptureCoordinator.maximumSources)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 15)
            .frame(minHeight: 42)

            Divider().overlay(Color.white.opacity(0.09))

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
                Text(L10n.text("ステージキャンバス", "STAGE CANVAS"))
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(StagePanePalette.aqua)
                Text(L10n.stageInteractionModeDetail(controller.stageInteractionMode))
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

            StageLayoutEditor(controller: controller, capture: capture)
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
                .disabled(capture.sources.isEmpty || capture.isPickerPresented)
                .help(L10n.text(
                    "ソースをグリッド、横並び、縦並び、ピクチャーインピクチャに配置します",
                    "Arrange sources as a grid, side by side, stacked, or picture in picture"
                ))

            case .control:
                if controller.previewInputAccessGranted {
                    Label(
                        L10n.text("操作許可済み", "Control Allowed"),
                        systemImage: "checkmark.shield.fill"
                    )
                    .foregroundStyle(StagePanePalette.mintReadable)
                    .accessibilityHint(L10n.text(
                        "単一ウインドウ内の対応するPress操作だけを実行します。",
                        "Only supported Press actions in a single window are performed."
                    ))
                } else {
                    Button {
                        controller.presentPermissionCheck(focus: .accessibility)
                    } label: {
                        Label(
                            L10n.text("操作権限を確認", "Review Control Access"),
                            systemImage: "exclamationmark.shield.fill"
                        )
                    }
                    .foregroundStyle(StagePanePalette.coralReadable)
                    .help(L10n.text(
                        "操作モードに必要なアクセシビリティ設定を確認します",
                        "Review the Accessibility setting required by Control mode"
                    ))
                }

                Text(L10n.text(
                    "ボタン等のPress操作のみ",
                    "Supported Press actions only"
                ))
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.56))

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
                .disabled(!controller.hasAnnotations)
                .keyboardShortcut("z", modifiers: [.command])

                Button(role: .destructive) {
                    isClearInkConfirmationPresented = true
                } label: {
                    Label(
                        L10n.text("すべて消す", "Clear All"),
                        systemImage: "trash"
                    )
                }
                .disabled(!controller.hasAnnotations)
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
        Label(
            L10n.stageInteractionModeName(controller.stageInteractionMode),
            systemImage: modeSymbol(controller.stageInteractionMode)
        )
        .font(.caption.weight(.bold))
        .foregroundStyle(StagePanePalette.aqua)
        .accessibilityLabel(L10n.text(
            "現在のモード、\(L10n.stageInteractionModeName(controller.stageInteractionMode))",
            "Current mode, \(L10n.stageInteractionModeName(controller.stageInteractionMode))"
        ))
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
        case .control: "hand.tap.fill"
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
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 86)
            .accessibilityLabel(L10n.text("描画ツール", "Drawing tool"))
            .accessibilityValue(toolName(store.preferences.tool))
            .help(L10n.text(
                "ペン、または半透明の蛍光ペンを選びます",
                "Choose a pen or translucent highlighter"
            ))

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

    private var widthAccessibilityValue: String {
        let referencePixels = Int((store.preferences.normalizedWidth * 1_080).rounded())
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
        .accessibilityValue(capture.statusDetail)
        .accessibilityHint(L10n.text(
            "会議アプリが実際に共有中かどうかを示すものではありません。",
            "This does not indicate whether a meeting app is actively sharing."
        ))
        .help(capture.statusDetail)
    }

    private var statusColor: Color {
        guard isStageVisible else { return .secondary }
        if captureNeedsAttention { return .orange }
        if allSourcesPaused { return .secondary }
        return capture.isCaptureActive
            ? StagePanePalette.mintReadable
            : StagePanePalette.aquaReadable
    }

    private var statusTitle: String {
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

private struct WorkspaceNoticeBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(StagePanePalette.aqua)
            Text(message)
                .font(.caption.weight(.medium))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("通知を閉じる", "Dismiss notice"))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .frame(maxWidth: 720, minHeight: 40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(StagePanePalette.aqua.opacity(0.28))
        }
        .shadow(color: .black.opacity(0.35), radius: 15, y: 7)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(message)
    }
}
