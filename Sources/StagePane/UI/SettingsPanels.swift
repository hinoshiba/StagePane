import AppKit
import StagePaneCore
import SwiftUI

/// Stage-specific controls stay beside the composition. Unlike Crop, these
/// preferences apply immediately and are not reverted by closing the popover.
struct StageInspectorPanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.text("Stage設定", "Stage Settings"))
                    .font(.headline)
                    .accessibilityHeading(.h1)
                Spacer()
                Button {
                    controller.isStageSettingsPresented = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(L10n.text("Stage設定を閉じる", "Close Stage Settings"))
                .help(L10n.text("閉じる", "Close"))
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Text(L10n.text(
                "変更はStageへすぐ反映されます。",
                "Changes apply to the Stage immediately."
            ))
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.bottom, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    appearanceSection
                    Divider()
                    curtainSection
                    Divider()
                    pointerSection
                    Divider()
                    outputSection
                    Divider()
                    StageOutputDetails(controller: controller)
                }
                .padding(18)
            }
        }
        .frame(width: 360, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .controlSize(.regular)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.text("形と背景", "Shape and Background"))
            Picker(L10n.text("画面の形", "Stage shape"), selection: presetBinding) {
                ForEach(StagePreset.allCases) { preset in
                    Text(L10n.presetName(preset)).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .disabled(controller.stageFullScreenTransitionInProgress)

            Picker(L10n.text("背景", "Background"), selection: themeBinding) {
                ForEach(StageTheme.allCases) { theme in
                    Text(L10n.themeName(theme)).tag(theme)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var curtainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle(L10n.text("カーテンのメッセージ", "Curtain Message"))
                Spacer()
                Text("\(controller.privacyMessage.count)/\(StageMessage.characterLimit)")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.text("メッセージの文字数", "Message character count"))
            }
            TextField(
                L10n.text("少々お待ちください", "Back in a moment"),
                text: $controller.privacyMessage,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(L10n.text("カーテンのメッセージ", "Curtain message"))
            .help(L10n.text(
                "カーテンを閉じている間だけ表示します。",
                "Shown only while the curtain is closed."
            ))
            .accessibilityHint(L10n.text(
                "カーテンを閉じている間だけ表示します。",
                "Shown only while the curtain is closed."
            ))

            Stepper(
                value: $controller.privacyMessageSize,
                in: StageMessage.textSizeRange,
                step: StageMessage.textSizeStep
            ) {
                HStack {
                    Text(L10n.text("文字の大きさ", "Text size"))
                    Spacer()
                    Text("\(controller.privacyMessageSize)%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel(L10n.text("カーテンの文字の大きさ", "Curtain text size"))
            .accessibilityValue("\(controller.privacyMessageSize)%")
        }
    }

    private var pointerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.text("ポインタ", "Pointer"))
            Picker(L10n.text("表示方法", "Appearance"), selection: $controller.pointerStyle) {
                ForEach(StagePaneCore.PointerStyle.allCases) { style in
                    Text(L10n.pointerStyleName(style)).tag(style)
                }
            }
            .pickerStyle(.menu)
            .accessibilityHint(L10n.pointerStyleDetail(controller.pointerStyle))

            if controller.isAudiencePointerSuppressedByInteractionMode {
                Label {
                    detail(L10n.text(
                        "手書き・虫眼鏡モードではポインタを隠します。配置へ戻ると、この設定を復元します。",
                        "Draw and Magnify hide the pointer. Returning to Arrange restores this setting."
                    ))
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if controller.pointerStyle == .redDot {
                PointerAppearanceEditor(appearance: $controller.pointerAppearance, compact: true)
            }
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(L10n.text("表示", "Display"))
            Toggle(L10n.text("セーフエリア（外周5%）", "Safe area (outer 5%)"), isOn: $controller.showsSafeArea)
                .help(L10n.text(
                    "投影や配信で切れやすい外周5%を確認します。",
                    "Check the outer 5% that projectors and streams may crop."
                ))
                .accessibilityHint(L10n.text(
                    "投影や配信で切れやすい外周5%を確認します。",
                    "Check the outer 5% that projectors and streams may crop."
                ))

            Toggle(L10n.text("StagePaneロゴを表示", "Show StagePane mark"), isOn: watermarkBinding)
                .accessibilityHint(controller.hasProAccess
                    ? L10n.text("Stageのロゴ表示を切り替えます。", "Toggles the StagePane mark on the Stage.")
                    : L10n.text("オフにするとStagePane Proの画面を開きます。", "Turning this off opens StagePane Pro."))
            if !controller.hasProAccess {
                detail(L10n.text(
                    "非表示にはStagePane Proが必要です。",
                    "Hiding the mark requires StagePane Pro."
                ))
            }
        }
        .toggleStyle(.switch)
    }

    private var presetBinding: Binding<StagePreset> {
        Binding(get: { controller.preset }, set: { controller.setPreset($0) })
    }

    private var themeBinding: Binding<StageTheme> {
        Binding(get: { controller.theme }, set: { controller.setTheme($0) })
    }

    private var watermarkBinding: Binding<Bool> {
        Binding(get: { controller.showsWatermark }, set: { controller.requestWatermarkVisibility($0) })
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.headline).accessibilityHeading(.h2)
    }

    private func detail(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// App-level information lives in a separate window, so it never replaces the
/// editing canvas or interrupts its current selection and Crop draft.
struct AppSettingsView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        VStack(spacing: 0) {
            Picker(L10n.text("設定のカテゴリ", "Settings category"), selection: selection) {
                Text(L10n.text("一般", "General")).tag(WorkspaceSection.appearance)
                Text(L10n.text("このアプリについて", "About")).tag(WorkspaceSection.about)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(20)

            Divider()

            Group {
                switch selection.wrappedValue {
                case .about:
                    AboutPanel(controller: controller)
                default:
                    generalPane
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 640, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var generalPane: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text(
                        "形・背景・カーテン・ポインタ",
                        "Shape, background, curtain, and pointer"
                    ))
                    .foregroundStyle(.secondary)
                    Button(L10n.text("Stage設定を開く", "Open Stage Settings"), action: controller.showStageSettings)
                }
            } header: {
                Text(L10n.text("Stageの表示", "Stage Appearance"))
            }

            Section {
                if controller.hasProAccess {
                    LabeledContent("StagePane Pro") {
                        HStack(spacing: 10) {
                            Text(L10n.text("有効", "Active"))
                                .foregroundStyle(.secondary)
                            Button(L10n.text("詳細…", "Details…"), action: controller.showProUpgrade)
                                .accessibilityLabel(L10n.text("StagePane Proの詳細", "StagePane Pro details"))
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.text(
                            "無料版では4つのソースを利用できます。Proではソース数の上限がなくなり、ロゴを非表示にできます。",
                            "Free supports four sources. Pro removes the source limit and lets you hide the StagePane mark."
                        ))
                        .foregroundStyle(.secondary)
                        Button("StagePane Pro…", action: controller.showProUpgrade)
                    }
                }
            } header: {
                if !controller.hasProAccess {
                    Text("StagePane Pro")
                }
            }

            Section {
                Button(L10n.text("使い方とサポート", "Help and Support"), action: controller.openSupport)
            }
        }
        .formStyle(.grouped)
    }

    private var selection: Binding<WorkspaceSection> {
        Binding(
            get: {
                switch controller.workspaceSection {
                case .privacy, .about: .about
                default: .appearance
                }
            },
            set: { controller.selectWorkspaceSection($0) }
        )
    }
}

struct AppearancePanel: View {
    @ObservedObject var controller: AppController
    private let focusesAudienceForSnapshot: Bool

    init(controller: AppController, focusesAudienceForSnapshot: Bool = false) {
        self.controller = controller
        self.focusesAudienceForSnapshot = focusesAudienceForSnapshot
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(
                    eyebrow: L10n.text("APPEARANCE", "APPEARANCE"),
                    title: L10n.text("ステージを整える", "Shape your stage"),
                    detail: L10n.text(
                        "見やすさを保ちながら、会議や配信に合う雰囲気を選べます。",
                        "Choose a focused look that fits your meeting or presentation."
                    )
                )

                if focusesAudienceForSnapshot {
                    audienceViewCard
                } else {
                    VStack(alignment: .leading, spacing: 15) {
                        Text(L10n.text("背景テーマ", "Background theme"))
                            .font(.headline)
                        HStack(spacing: 12) {
                            ForEach(StageTheme.allCases) { theme in
                                ThemeChoice(theme: theme, selected: controller.theme == theme) {
                                    controller.setTheme(theme)
                                }
                            }
                        }
                    }
                    .cardSurface()

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.text("カーテンのメッセージ", "Curtain message"))
                                    .font(.headline)
                                Text(L10n.text(
                                    "共有内容を隠している間だけ表示されます。",
                                    "Shown only while the stage content is covered."
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(controller.privacyMessage.count)/\(StageMessage.characterLimit)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        TextField(
                            L10n.text("少々お待ちください", "Back in a moment"),
                            text: $controller.privacyMessage
                        )
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(L10n.text("カーテンのメッセージ", "Curtain message"))
                        curtainTextSizeControl
                    }
                    .cardSurface()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("ウインドウ動作", "Window behavior"))
                            .font(.headline)
                            .padding(.bottom, 8)
                        PreferenceToggle(
                            title: L10n.text("常に手前に表示", "Keep Stage in front"),
                            detail: L10n.text(
                                "会議アプリがStageを見つけにくい場合の互換モードです。",
                                "Compatibility option for meeting apps that lose track of the Stage."
                            ),
                            symbol: "pin.fill",
                            value: $controller.isAlwaysOnTop
                        )
                        Divider().padding(.leading, 42)
                        PreferenceToggle(
                            title: L10n.text("すべての操作スペースに表示", "Show on every Space"),
                            detail: L10n.text(
                                "フルスクリーンアプリを含む各SpaceへStageを表示します。",
                                "Let the Stage follow you across Spaces and full-screen apps."
                            ),
                            symbol: "square.grid.2x2.fill",
                            value: $controller.followsAllSpaces
                        )
                        Divider().padding(.leading, 42)
                        PreferenceToggle(
                            title: L10n.text("プレゼンテーションロック", "Presentation Lock"),
                            detail: L10n.text(
                                "共有中の誤った終了・最小化を防ぎます。",
                                "Prevent accidental closing or minimizing while presenting."
                            ),
                            symbol: "lock.fill",
                            value: $controller.presentationLock
                        )
                    }
                    .cardSurface()

                    audienceViewCard
                }
            }
            .padding(.top, 38)
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
    }

    private var curtainTextSizeControl: some View {
        HStack(spacing: 10) {
            Text(L10n.text("文字の大きさ", "Text size"))
            Spacer()
            Button {
                controller.privacyMessageSize -= StageMessage.textSizeStep
            } label: {
                Image(systemName: "minus")
                    .frame(width: 24, height: 24)
            }
            .disabled(controller.privacyMessageSize <= StageMessage.textSizeRange.lowerBound)
            .accessibilityLabel(L10n.text("カーテンの文字を小さく", "Decrease curtain text size"))
            .accessibilityValue("\(controller.privacyMessageSize)%")
            .help(L10n.text("文字を小さく", "Make text smaller"))

            Text("\(controller.privacyMessageSize)%")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 48)
                .accessibilityLabel(L10n.text("カーテンの文字の大きさ", "Curtain text size"))
                .accessibilityValue("\(controller.privacyMessageSize)%")

            Button {
                controller.privacyMessageSize += StageMessage.textSizeStep
            } label: {
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
            }
            .disabled(controller.privacyMessageSize >= StageMessage.textSizeRange.upperBound)
            .accessibilityLabel(L10n.text("カーテンの文字を大きく", "Increase curtain text size"))
            .accessibilityValue("\(controller.privacyMessageSize)%")
            .help(L10n.text("文字を大きく", "Make text larger"))
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    private var audienceViewCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text("相手に見える画面", "Audience view"))
                .font(.headline)
                .padding(.bottom, 8)
            PointerStylePicker(
                selection: $controller.pointerStyle,
                appearance: $controller.pointerAppearance,
                isSuppressedByInteractionMode: controller.isAudiencePointerSuppressedByInteractionMode
            )
            Divider().padding(.leading, 42)
            PreferenceToggle(
                title: L10n.text("セーフエリアを表示", "Show safe area"),
                detail: L10n.text(
                    "投影や配信で切れやすい外周5%を確認します。",
                    "Preview the outer 5% that projectors and streams may crop."
                ),
                symbol: "viewfinder",
                value: $controller.showsSafeArea
            )
            Divider().padding(.leading, 42)
            WatermarkPreference(controller: controller)
        }
        .cardSurface()
    }
}

struct ScreenSharingAccessView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        VStack(spacing: 0) {
            PermissionsPanel(controller: controller, capture: capture)
            Divider()
            HStack {
                Spacer()
                Button(L10n.text("閉じる", "Close"), action: controller.closePermissionCheck)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(minWidth: 560, minHeight: 440)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct CaptureAccessIssueView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(controller.captureAccessIssue?.title ?? L10n.text("画面取得を開始できませんでした", "Couldn’t start capture"))
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h1)
                Spacer(minLength: 0)
            }
            .padding(24)

            ScrollView {
                Text(controller.captureAccessIssue?.detail ?? "")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }

            Divider()
            HStack {
                Button(L10n.text("画面共有について…", "About Screen Sharing…"), action: controller.showAccessHelpForIssue)
                Spacer()
                Button(L10n.text("閉じる", "Close"), action: controller.dismissCaptureAccessIssue)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(minWidth: 480, minHeight: 260)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct PermissionsPanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("画面共有について", "About Screen Sharing"))
                        .font(.title2.weight(.semibold))
                        .accessibilityHeading(.h1)
                    Text(L10n.text(
                        "ソースを追加・選び直すときに、macOSの共有ピッカーで対象を選択します。",
                        "When you add or replace a source, choose what to share in the macOS picker."
                    ))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label(screenSharingStatusTitle, systemImage: screenSharingStatusSymbol)
                        .font(.body.weight(.medium))
                        .foregroundStyle(screenSharingStatusColor)
                        .accessibilityLabel(L10n.text("ソースの選択状況", "Source selection status"))
                        .accessibilityValue(screenSharingStatusTitle)
                    Text(L10n.text(
                        "選んだウインドウ、アプリ、または画面だけを、その共有セッション中に表示します。音声は取得しません。",
                        "Only the window, app, or display you choose is shown for that sharing session. Audio is not captured."
                    ))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    addSourceButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(padding: 16)

                DisclosureGroup(L10n.text("共有アクセスの詳細", "Sharing Access Details")) {
                    Text(permissionFooterText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
            }
            .padding(24)
        }
    }

    private var permissionFooterText: String {
        L10n.text(
            "この画面を開くだけでは、macOSの確認ダイアログは表示されません。ソースを解除するか、すべて停止すると、そのソース用の共有アクセスも終了します。配置・切り抜き・手書きはStagePane内だけで動作し、アクセシビリティや入力監視の許可は要求しません。",
            "Opening this page never shows a macOS consent dialog by itself. Removing a source or stopping all sources ends the sharing access for that source. Arrange, Crop, and Draw stay inside StagePane; Accessibility and Input Monitoring permission are never requested."
        )
    }

    private var screenSharingStatusTitle: String {
        if capture.isPickerPresented {
            return L10n.text("macOSで選択中", "Choosing in macOS")
        }
        if capture.isCaptureActive {
            return L10n.text("このセッションで選択済み", "Selected for this session")
        }
        return L10n.text("追加時に確認", "Confirmed when added")
    }

    private var screenSharingStatusSymbol: String {
        if capture.isPickerPresented { return "ellipsis.circle.fill" }
        if capture.isCaptureActive { return "checkmark.circle.fill" }
        return "shield"
    }

    private var screenSharingStatusColor: Color {
        if capture.isPickerPresented { return StagePanePalette.aquaReadable }
        if capture.isCaptureActive { return StagePanePalette.mintReadable }
        return .secondary
    }

    private var addSourceButton: some View {
        Button(action: controller.chooseSourceFromAccessGuide) {
            Label(
                requiresProForSourceAddition
                    ? L10n.text("Proでさらに追加", "Add More with Pro")
                    : L10n.text("ソースを追加", "Add Source"),
                systemImage: requiresProForSourceAddition ? "lock.open.fill" : "plus"
            )
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(!controller.canRequestSourceAddition)
        .accessibilityHint(requiresProForSourceAddition
            ? L10n.text(
                "StagePane Proの購入画面を開きます。",
                "Opens the StagePane Pro purchase screen."
            )
            : L10n.text(
                "Appleの共有内容選択画面を開きます。",
                "Opens Apple’s content-sharing picker."
            ))
    }

    private var requiresProForSourceAddition: Bool {
        StagePaneAccess.requiresProForNextSource(
            currentCount: capture.occupiedSourceSlots,
            hasProAccess: controller.hasProAccess
        )
    }

}

private struct WatermarkPreference: View {
    @ObservedObject var controller: AppController

    var body: some View {
        Toggle(isOn: watermarkBinding) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(StagePanePalette.aquaReadable)
                    .frame(width: 30, height: 30)
                    .background(
                        StagePanePalette.aquaReadable.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(L10n.text("StagePaneロゴを表示", "Show StagePane mark"))
                            .font(.subheadline.weight(.semibold))
                        if !controller.hasProAccess {
                            Text("PRO")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(0.5)
                                .foregroundStyle(StagePanePalette.aquaReadable)
                                .padding(.horizontal, 6)
                                .frame(minHeight: 18)
                                .background(StagePanePalette.aquaReadable.opacity(0.10), in: Capsule())
                        }
                    }
                    Text(controller.hasProAccess
                        ? L10n.text(
                            "相手に見える画面の右下に、小さなブランド表示を追加します。",
                            "Add a small brand mark to the lower-right of the Stage."
                        )
                        : L10n.text(
                            "無料版では表示されます。オフにするとStagePane Proをご案内します。",
                            "The mark is shown in Free. Turning this off opens StagePane Pro."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 8)
        .accessibilityLabel(L10n.text("StagePaneロゴを表示", "Show StagePane mark"))
        .accessibilityHint(controller.hasProAccess
            ? L10n.text("Stageのロゴ表示を切り替えます。", "Toggles the StagePane mark on the Stage.")
            : L10n.text("ロゴを非表示にするStagePane Proの画面を開きます。", "Opens StagePane Pro to hide the mark."))
    }

    private var watermarkBinding: Binding<Bool> {
        Binding(
            get: { controller.showsWatermark },
            set: { controller.requestWatermarkVisibility($0) }
        )
    }
}

struct PrivacyPanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(
                    eyebrow: L10n.text("PRIVACY", "PRIVACY"),
                    title: L10n.text("画面の扱いと保存。", "Screen content and storage."),
                    detail: L10n.text(
                        "選択した画面をMac上でStageに表示します。画面共有は会議アプリから操作してください。",
                        "Selected screen content is displayed on the Stage on your Mac. Control screen sharing from your meeting app."
                    )
                )
                PrivacyDetailsContent(controller: controller, capture: capture)
                Button(L10n.text("プライバシーポリシー", "Privacy Policy"), action: controller.openPrivacyPolicy)
            }
            .padding(24)
        }
    }
}

/// Embeddable details share the same live capture status without a nested scroll view.
private struct PrivacyDetailsContent: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 0) {
                DataFlowNode(
                    symbol: "macwindow",
                    title: L10n.text("選んだ内容", "Chosen content"),
                    detail: L10n.text("macOSが許可", "Approved by macOS")
                )
                FlowArrow()
                DataFlowNode(
                    symbol: "memorychip.fill",
                    title: L10n.text("メモリ内プレビュー", "In-memory preview"),
                    detail: L10n.text("最大30 fps", "Up to 30 fps")
                )
                FlowArrow()
                DataFlowNode(
                    symbol: "rectangle.inset.filled",
                    title: "StagePane Stage",
                    detail: L10n.text(
                        "通常は表示後に破棄。明示したAudience PNGだけ作成",
                        "Normally discarded after display; only an explicit Audience PNG is created"
                    )
                )
            }
            .padding(18)
            .background(StagePanePalette.mintReadable.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(StagePanePalette.mintReadable.opacity(0.24)))
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: captureStatusSymbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(captureStatusColor)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(captureStatusTitle)
                            .font(.headline)
                        Text(captureStatusDetail)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if capture.hasLayers || capture.isCaptureActive || captureNeedsAttention {
                    Button(action: controller.stopPreview) {
                        Label(
                            L10n.stopAllAndRemoveLayersTitle,
                            systemImage: capture.hasDisconnectedLayers && !capture.isCaptureActive
                                ? "trash.fill"
                                : "stop.circle.fill"
                        )
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
            }
            .cardSurface()

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("保存した画像について", "Saved images"))
                    .font(.headline)
                Text(L10n.text(
                    "「画像をコピー」はクリップボードへ、「PNGを保存」は選択した場所へ画像を作成します。不要な保存画像はご自身で削除してください。",
                    "Copy Image places an image on the clipboard. Save PNG creates a file at your chosen location. Delete saved images when you no longer need them."
                ))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .cardSurface()

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(StagePanePalette.aquaReadable)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("StagePane Proの購入", "StagePane Pro purchases"))
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.text(
                        "Proの商品情報・購入・復元はAppleのStoreKitが処理します。購入や請求についてはAppleのサポートをご確認ください。",
                        "Apple StoreKit handles Pro product information, purchases, and restores. For purchase and billing questions, see Apple Support."
                    ))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .cardSurface()

        }
    }

    private var captureNeedsAttention: Bool {
        if case .failed = capture.phase { return true }
        return false
    }

    private var captureStatusSymbol: String {
        if capture.hasDisconnectedLayers { return "rectangle.badge.exclamationmark" }
        if captureNeedsAttention { return "exclamationmark.triangle.fill" }
        if allSourcesPaused { return "pause.circle.fill" }
        if capture.isCaptureActive { return "rectangle.inset.filled" }
        switch capture.phase {
        case .choosing, .preparing: return "ellipsis.circle.fill"
        default: return "checkmark.shield.fill"
        }
    }

    private var captureStatusColor: Color {
        if captureNeedsAttention { return .orange }
        if allSourcesPaused { return .secondary }
        if capture.isCaptureActive { return StagePanePalette.mintReadable }
        return StagePanePalette.aquaReadable
    }

    private var captureStatusTitle: String {
        if capture.hasDisconnectedLayers {
            return L10n.text(
                "選び直しが必要なレイヤーがあります",
                "A layer needs content selected again"
            )
        }
        if captureNeedsAttention {
            return L10n.text("プレビューの確認が必要", "Preview needs attention")
        }
        if allSourcesPaused {
            return L10n.text("すべてのソースを一時停止中", "All sources are paused")
        }
        if capture.isCaptureActive {
            return L10n.text("ローカル画面取得が動作中", "Local capture is active")
        }
        switch capture.phase {
        case .choosing: return L10n.text("ソースを選択中", "Choosing a source")
        case .preparing: return L10n.text("プレビューを準備中", "Preparing the preview")
        default: return L10n.text("現在は画面を取得していません", "No screen content is being captured")
        }
    }

    private var captureStatusDetail: String {
        if capture.hasDisconnectedLayers {
            return L10n.text(
                "配置と切り抜きは保持されています。ソース一覧の「選び直す」で同じレイヤーへ新しい対象を設定できます。下の削除操作は保持中のレイヤーをすべて削除します。",
                "Placement and crop are preserved. Use Select Again in the source list to choose content for the same layer. The remove action below deletes every retained layer."
            )
        }
        if captureNeedsAttention {
            return capture.isCaptureActive
                ? L10n.text(
                    "問題の後も画面取得は動作中です。カーテンは出力だけを隠します。完全に止めるには下のボタンを使ってください。",
                    "Capture remains active after the issue. Curtain hides only the output; use the button below to stop capture completely."
                )
                : L10n.text(
                    "画面取得の状態をリセットするには、下の停止ボタンを使ってからソースを選び直してください。",
                    "Use Stop below to reset capture state, then choose the source again."
                )
        }
        if allSourcesPaused {
            return L10n.text(
                "取得は停止中です。レイヤーは透明ですが、配置と切り抜きを保持したままソース一覧から再開できます。",
                "Capture is paused. Layers are transparent, while their placement and crop remain ready to resume from the source list."
            )
        }
        if capture.isCaptureActive {
            return L10n.text(
                "カーテンは出力を隠しますが、画面取得自体は継続します。完全に止めるには下のボタンを使ってください。",
                "Curtain hides the output but capture continues. Use Stop Capture below to end it completely."
            )
        }
        return L10n.text(
            "ソース選択時だけ、macOS標準の共有ピッカーが開きます。",
            "The macOS system picker opens only when you choose a source."
        )
    }

    private var allSourcesPaused: Bool {
        !capture.sources.isEmpty && capture.sources.allSatisfy(\.isPaused)
    }
}

struct AboutPanel: View {
    @ObservedObject var controller: AppController

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 18) {
                    BrandMark(size: 64)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("StagePane")
                            .font(.title2.weight(.semibold))
                            .accessibilityHeading(.h1)
                        Text(L10n.text("バージョン \(version)", "Version \(version)"))
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(L10n.text(
                            "画面共有専用のステージ",
                            "Screen Share Stage"
                        ))
                        .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.text(
                        "選択した画面はMac上で処理します。画像の保存はコピーやPNG保存を実行したときだけ行います。会議への共有は会議アプリで操作してください。",
                        "Selected screen content is processed on your Mac. Images are saved only when you copy an image or save a PNG. Control sharing to your meeting from your meeting app."
                    ))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    Button(L10n.text("プライバシーポリシー", "Privacy Policy"), action: controller.openPrivacyPolicy)
                        .buttonStyle(.link)

                    Button(L10n.text("画面共有について…", "About Screen Sharing…"), action: controller.showPermissions)

                    DisclosureGroup(L10n.text("プライバシーとデータ", "Privacy and Data")) {
                        PrivacyDetailsContent(controller: controller, capture: controller.capture)
                            .padding(.top, 12)
                    }
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: 10)],
                    spacing: 10
                ) {
                    Button {
                        controller.openSupport()
                    } label: {
                        Label(L10n.text("サポート", "Support"), systemImage: "lifepreserver.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button {
                        controller.openBundledDocument(resource: "LICENSE", extension: "txt")
                    } label: {
                        Label(L10n.text("Apache-2.0ライセンス", "Apache-2.0 License"), systemImage: "doc.text.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button {
                        controller.openBundledDocument(resource: "THIRD_PARTY_NOTICES", extension: "md")
                    } label: {
                        Label(L10n.text("第三者通知", "Third-party Notices"), systemImage: "shippingbox.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }

                VStack(alignment: .leading, spacing: 13) {
                    AboutFact(
                        symbol: "chevron.left.forwardslash.chevron.right",
                        title: L10n.text("オープンソース", "Open source"),
                        detail: L10n.text(
                            "ソースコードはApache License 2.0。商用利用・改変・再配布が可能です。",
                            "Source code is under Apache License 2.0, permitting commercial use, modification, and redistribution."
                        )
                    )
                    Divider().padding(.leading, 42)
                    AboutFact(
                        symbol: "shippingbox.fill",
                        title: L10n.text("対応環境", "Compatibility"),
                        detail: L10n.text(
                            "macOS 14以降のApple SiliconとIntel Macに対応しています。",
                            "Supports Apple Silicon and Intel Macs running macOS 14 or later."
                        )
                    )
                }
                .cardSurface()

                Text(L10n.text(
                        "ロゴとアイコンの著作物としての利用はApache-2.0で許諾されます。ただし、公式性や提携を示す商標としてStagePaneの名称・ロゴを使う権利は付与されません。詳しくは同梱の商標ポリシーを確認してください。",
                        "Apache-2.0 licenses copyright use of the logo and icon artwork, but it does not grant trademark rights to use the StagePane name or marks to imply official status or affiliation. See the bundled trademark policy for details."
                ))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

private struct ThemeChoice: View {
    let theme: StageTheme
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                StageBackground(theme: theme)
                    .frame(height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selected ? StagePanePalette.aquaReadable : Color.primary.opacity(0.16), lineWidth: selected ? 2 : 1)
                    )
                HStack {
                    Text(L10n.themeName(theme))
                        .font(.caption.weight(selected ? .bold : .medium))
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(StagePanePalette.aquaReadable)
                    }
                }
            }
            .padding(8)
            .background(selected ? StagePanePalette.indigo.opacity(0.10) : Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.themeName(theme))
        .accessibilityValue(selected ? L10n.text("選択中", "Selected") : "")
    }
}

private struct PreferenceToggle: View {
    let title: String
    let detail: String
    let symbol: String
    @Binding var value: Bool

    var body: some View {
        Toggle(isOn: $value) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(StagePanePalette.aquaReadable)
                    .frame(width: 30, height: 30)
                    .background(StagePanePalette.aquaReadable.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 8)
        .accessibilityLabel(title)
        .accessibilityHint(detail)
    }
}

private struct PointerStylePicker: View {
    @Binding var selection: StagePaneCore.PointerStyle
    @Binding var appearance: PointerAppearance
    let isSuppressedByInteractionMode: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cursorarrow")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(StagePanePalette.aquaReadable)
                .frame(width: 30, height: 30)
                .background(
                    StagePanePalette.aquaReadable.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("カーソルの表示方法", "Pointer appearance"))
                    .font(.subheadline.weight(.semibold))

                Picker(
                    L10n.text("カーソルの表示方法", "Pointer appearance"),
                    selection: $selection
                ) {
                    ForEach(StagePaneCore.PointerStyle.allCases) { style in
                        Text(L10n.pointerStyleName(style))
                            .tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .accessibilityLabel(L10n.text("カーソルの表示方法", "Pointer appearance"))
                .accessibilityValue(L10n.pointerStyleName(selection))
                .accessibilityHint(pointerAccessibilityHint)

                Text(L10n.pointerStyleDetail(selection))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)

                if isSuppressedByInteractionMode {
                    Label {
                        Text(L10n.text(
                            "手書き・虫眼鏡モードでは共有Stageのポインターを自動的に隠します。配置へ戻すと、この設定を復元します。",
                            "Draw and Magnify automatically hide the pointer on the shared Stage. Returning to Arrange restores this setting."
                        ))
                    } icon: {
                        Image(systemName: "pencil.tip")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(StagePanePalette.aquaReadable)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if selection == .redDot {
                    PointerAppearanceEditor(appearance: $appearance)
                        .padding(.top, 3)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var pointerAccessibilityHint: String {
        let detail = L10n.pointerStyleDetail(selection)
        guard isSuppressedByInteractionMode else { return detail }
        return detail + " " + L10n.text(
            "手書き・虫眼鏡モードでは自動的に非表示になり、配置へ戻すと復元されます。",
            "It is hidden automatically in Draw and Magnify and restored when you return to Arrange."
        )
    }
}

private struct PointerAppearanceEditor: View {
    @Binding var appearance: PointerAppearance
    var compact = false

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        pointerPreview
                        colorControls
                    }
                    sizeAndGlowControls
                }
            } else {
                HStack(alignment: .center, spacing: 18) {
                    pointerPreview
                    VStack(alignment: .leading, spacing: 10) {
                        sizeAndGlowControls
                        colorControls
                    }
                }
            }
        }
        .font(.system(size: 12))
        .padding(compact ? 0 : 12)
        .background {
            if !compact {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
    }

    private var pointerPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .underPageBackgroundColor))
            Circle()
                .fill(pointerColor)
                .overlay(Circle().stroke(Color.white.opacity(0.74), lineWidth: 1.5))
                .shadow(
                    color: pointerColor.opacity(appearance.glow * 0.88),
                    radius: CGFloat(3 + (appearance.glow * 12))
                )
                .frame(
                    width: CGFloat(appearance.diameter),
                    height: CGFloat(appearance.diameter)
                )
        }
        .frame(width: 76, height: 76)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text("ポインターのプレビュー", "Pointer preview"))
    }

    private var sizeAndGlowControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(L10n.text("サイズ", "Size"))
                    .frame(width: 42, alignment: .leading)
                Slider(
                    value: diameterBinding,
                    in: PointerAppearance.minimumDiameter...PointerAppearance.maximumDiameter,
                    step: 1
                )
                .accessibilityLabel(L10n.text("ポインターのサイズ", "Pointer size"))
                .accessibilityValue("\(Int(appearance.diameter.rounded())) pt")
                Text("\(Int(appearance.diameter.rounded())) pt")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 43, alignment: .trailing)
            }

            HStack(spacing: 10) {
                Text(L10n.text("発光", "Glow"))
                    .frame(width: 42, alignment: .leading)
                Slider(
                    value: glowBinding,
                    in: PointerAppearance.minimumGlow...PointerAppearance.maximumGlow,
                    step: 0.05
                )
                .accessibilityLabel(L10n.text("ポインターの発光", "Pointer glow"))
                .accessibilityValue("\(Int((appearance.glow * 100).rounded()))%")
                Text("\(Int((appearance.glow * 100).rounded()))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 43, alignment: .trailing)
            }
        }
    }

    private var colorControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                pointerColorPicker
                Spacer(minLength: 8)
                resetButton
            }
            VStack(alignment: .leading, spacing: 12) {
                pointerColorPicker
                resetButton
            }
        }
    }

    private var pointerColorPicker: some View {
        ColorPicker(
            L10n.text("色", "Color"),
            selection: colorBinding,
            supportsOpacity: false
        )
        .accessibilityLabel(L10n.text("ポインターの色", "Pointer color"))
    }

    private var resetButton: some View {
        Button(L10n.text("標準に戻す", "Reset")) {
            appearance = .presentationDefault
        }
        .buttonStyle(.borderless)
        .accessibilityHint(L10n.text(
            "赤色、22ポイント、中程度の発光に戻します。",
            "Restore red, 22 points, and medium glow."
        ))
    }

    private var pointerColor: Color {
        Color(
            red: appearance.color.red,
            green: appearance.color.green,
            blue: appearance.color.blue
        )
    }

    private var diameterBinding: Binding<Double> {
        Binding(
            get: { appearance.diameter },
            set: { value in
                appearance = PointerAppearance(
                    diameter: value,
                    color: appearance.color,
                    glow: appearance.glow
                )
            }
        )
    }

    private var glowBinding: Binding<Double> {
        Binding(
            get: { appearance.glow },
            set: { value in
                appearance = PointerAppearance(
                    diameter: appearance.diameter,
                    color: appearance.color,
                    glow: value
                )
            }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { pointerColor },
            set: { value in
                guard let converted = NSColor(value).usingColorSpace(.sRGB) else { return }
                appearance = PointerAppearance(
                    diameter: appearance.diameter,
                    color: PointerRGBColor(
                        red: Double(converted.redComponent),
                        green: Double(converted.greenComponent),
                        blue: Double(converted.blueComponent)
                    ),
                    glow: appearance.glow
                )
            }
        )
    }
}

private struct DataFlowNode: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(StagePanePalette.mintReadable)
            Text(title)
                .font(.system(size: 12).weight(.bold))
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FlowArrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12).weight(.bold))
            .foregroundStyle(StagePanePalette.mintReadable.opacity(0.82))
            .accessibilityHidden(true)
    }
}

private struct PrivacyPromise: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(StagePanePalette.mintReadable)
                .frame(width: 30, height: 30)
                .background(StagePanePalette.mintReadable.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12).weight(.black))
                .foregroundStyle(StagePanePalette.mintReadable)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }
}

private struct AboutFact: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(StagePanePalette.aquaReadable)
                .frame(width: 30, height: 30)
                .background(StagePanePalette.aquaReadable.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
