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

            ViewThatFits(in: .horizontal) {
                wideWorkspace
                compactWorkspace
            }
        }
        .frame(minWidth: 820, minHeight: 560)
        .background(workspaceBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            if let notice = controller.transientNotice {
                WorkspaceNoticeBanner(message: notice) {
                    controller.dismissTransientNotice()
                }
                .padding(.top, 102)
                .padding(.horizontal, 18)
                .transition(.opacity)
            }
        }
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
        HStack(spacing: 11) {
            Button {
                isSourceRailVisible.toggle()
            } label: {
                ViewThatFits(in: .horizontal) {
                    Label(
                        isSourceRailVisible
                            ? L10n.text("ソースを隠す", "Hide Sources")
                            : L10n.text("ソースを表示", "Show Sources"),
                        systemImage: "sidebar.left"
                    )
                    Image(systemName: "sidebar.left")
                }
            }
            .buttonStyle(WorkspaceToolbarButtonStyle())
            .accessibilityLabel(isSourceRailVisible
                ? L10n.text("ソース一覧を隠す", "Hide source list")
                : L10n.text("ソース一覧を表示", "Show source list"))
            .help(isSourceRailVisible
                ? L10n.text("ソース一覧を隠します", "Hide the source list")
                : L10n.text("ソース一覧を表示します", "Show the source list"))

            WorkspaceOutputStatus(
                isStageVisible: controller.stageIsVisible,
                isCaptureActive: capture.isCaptureActive
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
            .frame(minWidth: 246, idealWidth: 310, maxWidth: 340)
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

            screenshotMenu

            Button(action: controller.toggleCurtain) {
                ViewThatFits(in: .horizontal) {
                    Label(curtainButtonTitle, systemImage: curtainButtonSymbol)
                    Image(systemName: curtainButtonSymbol)
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
                ViewThatFits(in: .horizontal) {
                    Label(
                        L10n.text("共有Stageを表示", "Show Share Stage"),
                        systemImage: "macwindow.on.rectangle"
                    )
                    Image(systemName: "macwindow.on.rectangle")
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

    private var privateWorkspaceWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .foregroundStyle(StagePanePalette.aqua)

            Text(L10n.text(
                "これは操作用ウインドウです。会議アプリでは「StagePane Stage」を共有してください。共有一覧から完全に隠れるとは限りません。",
                "This is a control window. Share “StagePane Stage” in your meeting app. This workspace may still appear in some share pickers."
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
                showsWorkspaceHint: false
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
                Button(action: capture.arrangeSourcesAutomatically) {
                    Label(
                        L10n.text("自動配置", "Auto Arrange"),
                        systemImage: "square.grid.2x2"
                    )
                }
                .disabled(capture.sources.count < 2 || capture.isPickerPresented)
                .help(L10n.text(
                    "すべてのソースを見やすいグリッドへ配置します",
                    "Arrange all sources in an even grid"
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

            if capture.sources.isEmpty {
                Button(action: controller.chooseSource) {
                    Label(
                        L10n.text("ソースを追加", "Add Source"),
                        systemImage: "plus"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(StagePanePalette.indigo)
                .disabled(!capture.canAddSource)
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

    private var screenshotMenu: some View {
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
            ViewThatFits(in: .horizontal) {
                Label(screenshotTitle, systemImage: screenshotSymbol)
                Image(systemName: screenshotSymbol)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.86))
            .padding(.horizontal, 10)
            .frame(minWidth: 31, minHeight: 31)
            .background(
                Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.12))
            }
        } primaryAction: {
            controller.copyStageScreenshot()
        }
        .menuStyle(.borderlessButton)
        .disabled(controller.isStageScreenshotInProgress)
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .accessibilityLabel(screenshotTitle)
        .accessibilityHint(L10n.text(
            "操作UIを含めず、観客向けStageと同じ内容をコピーまたはPNGで保存します。",
            "Copy or save the audience Stage as a PNG without workspace controls."
        ))
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

private struct WorkspaceOutputStatus: View {
    let isStageVisible: Bool
    let isCaptureActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            ViewThatFits(in: .horizontal) {
                Text(statusTitle)
                    .lineLimit(1)
                Text(shortStatusTitle)
                    .lineLimit(1)
            }
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(Color.white.opacity(0.72))
        .padding(.horizontal, 9)
        .frame(minHeight: 27)
        .background(Color.white.opacity(0.055), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.09)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statusTitle)
        .accessibilityHint(L10n.text(
            "会議アプリが実際に共有中かどうかを示すものではありません。",
            "This does not indicate whether a meeting app is actively sharing."
        ))
    }

    private var statusColor: Color {
        guard isStageVisible else { return .secondary }
        return isCaptureActive ? StagePanePalette.mintReadable : StagePanePalette.aquaReadable
    }

    private var statusTitle: String {
        if !isStageVisible {
            return L10n.text("共有Stageは閉じています", "Share Stage Closed")
        }
        if isCaptureActive {
            return L10n.text("共有Stageを表示・画面取得中", "Share Stage Open · Capture Active")
        }
        return L10n.text("共有Stageを表示中", "Share Stage Open")
    }

    private var shortStatusTitle: String {
        isStageVisible
            ? L10n.text("Stage表示中", "Stage Open")
            : L10n.text("Stage非表示", "Stage Closed")
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
