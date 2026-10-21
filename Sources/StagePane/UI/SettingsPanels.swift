import AppKit
import StagePaneCore
import SwiftUI

/// The native toolbar supplies the category name; the body contains its controls.
struct SettingsPaneView: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator
    let pane: SettingsPane

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                switch pane {
                case .pointer:
                    pointerSettings
                case .stage:
                    StageSettingsPane(controller: controller)
                case .window:
                    windowSettings
                case .access:
                    accessSettings
                case .pro:
                    SettingsProPane(controller: controller, purchases: controller.purchases)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .controlSize(.regular)
    }

    private var pointerSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker(L10n.text("共有Stageのポインタ", "Shared Stage pointer"), selection: $controller.pointerStyle) {
                ForEach(StagePaneCore.PointerStyle.allCases) { style in
                    Text(L10n.pointerStyleName(style)).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityValue(L10n.pointerStyleName(controller.pointerStyle))
            .accessibilityHint(L10n.pointerStyleDetail(controller.pointerStyle))

            Text(L10n.text(
                "手元のmacOSカーソルには影響しません。",
                "Your local macOS cursor is unchanged."
            ))
            .font(.system(size: 12))
            .foregroundStyle(.secondary)

            if let suppressionReason {
                Label(suppressionReason, systemImage: "eye.slash")
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if controller.pointerStyle == .redDot {
                Divider()
                PointerAppearanceEditor(appearance: $controller.pointerAppearance)
            }
        }
    }

    private var suppressionReason: String? {
        switch controller.stageInteractionMode {
        case .annotate:
            L10n.text(
                "手書き中は一時的に非表示です。配置・切り抜きに戻ると、選択した種類を使います。",
                "Temporarily hidden while drawing. Arrange and Crop use your saved selection."
            )
        case .magnify:
            L10n.text(
                "虫眼鏡中は一時的に非表示です。配置・切り抜きに戻ると、選択した種類を使います。",
                "Temporarily hidden while magnifying. Arrange and Crop use your saved selection."
            )
        default:
            nil
        }
    }

    private var windowSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle(L10n.text("Stageを常に手前に表示", "Keep Stage in front"), isOn: $controller.isAlwaysOnTop)
            Toggle(L10n.text("Stageをすべての操作スペースに表示", "Show Stage on every Space"), isOn: $controller.followsAllSpaces)
                .help(L10n.text(
                    "フルスクリーンアプリを含む各Spaceへ表示します。",
                    "Includes Spaces containing full-screen apps."
                ))
            Toggle(isOn: $controller.presentationLock) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("Stageウインドウを保護", "Protect Stage Window"))
                    Text(L10n.text("閉じる・最小化を防ぎます。", "Prevents closing or minimizing Stage."))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accessSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            LabeledContent(L10n.text("画面共有", "Screen sharing")) {
                Label(accessStatusTitle, systemImage: accessStatusSymbol)
                    .foregroundStyle(.secondary)
            }
            Text(L10n.text(
                "選んだウインドウ・アプリ・画面だけを、その共有セッション中に取得します。音声は取得しません。",
                "Only the window, app, or display you choose is captured for that sharing session. Audio is not captured."
            ))
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            Button(
                requiresProForSourceAddition
                    ? L10n.text("Proでさらに追加…", "Add More with Pro…")
                    : L10n.text("ソースを追加…", "Add Source…"),
                action: controller.chooseSourceFromAccessGuide
            )
            .disabled(!controller.canRequestSourceAddition)
            Button(
                L10n.text("Macの画面収録アクセスを確認…", "Check Mac Screen Recording Access…"),
                action: controller.showMacScreenRecordingAccess
            )
            .buttonStyle(.link)

            Divider()

            Button(L10n.text("プライバシーポリシー", "Privacy Policy"), action: controller.openPrivacyPolicy)
                .buttonStyle(.link)
            DisclosureGroup(L10n.text("プライバシーとデータ", "Privacy and Data")) {
                PrivacyDetailsContent(controller: controller, capture: capture)
                    .padding(.top, 12)
            }
        }
    }

    private var requiresProForSourceAddition: Bool {
        StagePaneAccess.requiresProForNextSource(
            currentCount: capture.occupiedSourceSlots,
            hasProAccess: controller.hasProAccess
        )
    }

    private var accessStatusTitle: String {
        if capture.isPickerPresented { return L10n.text("macOSで選択中", "Choosing in macOS") }
        if capture.isCaptureActive { return L10n.text("このセッションで選択済み", "Selected for this session") }
        return L10n.text("ソース追加時に確認", "Confirmed when a source is added")
    }

    private var accessStatusSymbol: String {
        if capture.isPickerPresented { return "ellipsis.circle" }
        if capture.isCaptureActive { return "checkmark.shield" }
        return "shield"
    }
}

private struct SettingsProPane: View {
    @ObservedObject var controller: AppController
    @ObservedObject var purchases: ProPurchaseStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            LabeledContent("StagePane Pro", value: statusTitle)
            if purchases.entitlementState == .sourceBuild {
                Text(L10n.text(
                    "このビルドではすべての機能を利用できます。アプリ内購入はありません。",
                    "All features are available in this build. In-app purchases are unavailable."
                ))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Button(
                purchases.hasProAccess
                    ? L10n.text("詳細…", "Details…")
                    : L10n.text("購入・復元…", "Purchase or Restore…"),
                action: controller.showProUpgrade
            )
        }
    }

    private var statusTitle: String {
        switch purchases.entitlementState {
        case .checking: L10n.text("確認中", "Checking")
        case .free: L10n.text("未購入", "Not purchased")
        case .pro: L10n.text("有効", "Active")
        case .sourceBuild: L10n.text("ソースビルド", "Source build")
        }
    }
}

struct MacScreenRecordingAccessView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.text("Macの画面収録アクセス", "Mac Screen Recording Access"))
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHeading(.h1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label(
                        controller.hasMacScreenRecordingAccess
                            ? L10n.text("許可済み", "Allowed")
                            : L10n.text("未許可", "Not allowed"),
                        systemImage: controller.hasMacScreenRecordingAccess
                            ? "checkmark.circle" : "circle"
                    )
                    .font(.body.weight(.medium))
                    .accessibilityLabel(L10n.text("Macの画面収録アクセス", "Mac Screen Recording Access"))
                    .accessibilityValue(controller.hasMacScreenRecordingAccess
                        ? L10n.text("許可済み", "Allowed")
                        : L10n.text("未許可", "Not allowed"))

                    Text(L10n.text(
                        "このアクセスは任意です。未許可でも「ソースを追加」からmacOSで選んだ画面を共有できます。",
                        "This app-wide access is optional. You can still share content you select in the macOS picker using Add Source."
                    ))
                    .foregroundStyle(.secondary)

                    if controller.hasRequestedMacScreenRecordingAccess && !controller.hasMacScreenRecordingAccess {
                        Text(L10n.text(
                            "許可はまだ確認できません。システム設定の「プライバシーとセキュリティ」で画面収録の項目を確認してください。変更後はStagePaneの再起動が必要な場合があります。",
                            "Access is not confirmed yet. Check screen recording in System Settings > Privacy & Security. You may need to restart StagePane after making changes."
                        ))
                        .foregroundStyle(.secondary)
                    }
                }
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            Divider()
            HStack(spacing: 12) {
                if !controller.hasMacScreenRecordingAccess {
                    if controller.hasRequestedMacScreenRecordingAccess {
                        Button(L10n.text("システム設定を開く", "Open System Settings"), action: controller.openMacSystemSettings)
                    } else {
                        Button(L10n.text("許可する…", "Allow…"), action: controller.requestMacScreenRecordingAccess)
                    }
                }
                Spacer()
                Button(L10n.text("StagePaneを使う", "Continue"), action: controller.closeMacScreenRecordingAccess)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(minWidth: 520, minHeight: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .onExitCommand(perform: controller.closeMacScreenRecordingAccess)
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

private struct PointerAppearanceEditor: View {
    @Binding var appearance: PointerAppearance
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            pointerPreview
            VStack(alignment: .leading, spacing: 12) {
                sizeAndGlowControls
                colorControls
            }
        }
        .font(.system(size: 12))
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
        .accessibilityLabel(L10n.text("ポインタのプレビュー", "Pointer preview"))
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
                .accessibilityLabel(L10n.text("ポインタのサイズ", "Pointer size"))
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
                .accessibilityLabel(L10n.text("ポインタの発光", "Pointer glow"))
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
        .accessibilityLabel(L10n.text("ポインタの色", "Pointer color"))
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
