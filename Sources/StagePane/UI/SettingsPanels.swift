import AppKit
import StagePaneCore
import SwiftUI

struct AppearancePanel: View {
    @ObservedObject var controller: AppController

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

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("相手に見える画面", "Audience view"))
                        .font(.headline)
                        .padding(.bottom, 8)
                    PointerStylePicker(
                        selection: $controller.pointerStyle,
                        appearance: $controller.pointerAppearance
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
                    PreferenceToggle(
                        title: L10n.text("StagePaneロゴを表示", "Show StagePane mark"),
                        detail: L10n.text(
                            "相手に見える画面の右下に、小さなブランド表示を追加します。",
                            "Add a small brand mark to the lower-right of the Stage."
                        ),
                        symbol: "sparkles.rectangle.stack.fill",
                        value: $controller.showsWatermark
                    )
                }
                .cardSurface()
            }
            .padding(.top, 38)
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
    }
}

struct PermissionsPanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(
                    eyebrow: L10n.text("ACCESS CHECK", "ACCESS CHECK"),
                    title: L10n.text("macOSのアクセス確認", "Check macOS access"),
                    detail: L10n.text(
                        "StagePaneは、機能を使う時だけmacOSの確認画面を開きます。状態と用途はここでいつでも確認できます。",
                        "StagePane opens macOS confirmation only when you use a feature that needs it. Review each purpose and status here at any time."
                    )
                )

                PermissionAccessCard(
                    symbol: "rectangle.on.rectangle.angled",
                    title: L10n.text("画面共有", "Screen sharing"),
                    role: L10n.text("ソースごとに確認", "Confirmed per source"),
                    detail: L10n.text(
                        "「ソースを追加」でAppleの選択画面が開きます。そこで選んだウインドウ、アプリ、または画面だけを、その共有セッション中に表示します。別の広い画面収録許可は要求せず、音声も取得しません。",
                        "Add Source opens Apple’s picker. StagePane can display only the window, app, or display you choose, and only for that sharing session. It doesn’t request separate broad screen-recording access or capture audio."
                    ),
                    statusTitle: screenSharingStatusTitle,
                    statusSymbol: screenSharingStatusSymbol,
                    statusColor: screenSharingStatusColor,
                    isFocused: controller.permissionPanelFocus == .screenSharing
                ) {
                    addSourceButton
                }

                #if !STAGEPANE_APP_STORE
                PermissionAccessCard(
                    symbol: "hand.tap.fill",
                    title: L10n.text("プレビューから操作", "Control from preview"),
                    role: L10n.text("操作モードのみ", "Control mode only"),
                    detail: accessibilityDetail,
                    statusTitle: accessibilityStatusTitle,
                    statusSymbol: accessibilityStatusSymbol,
                    statusColor: accessibilityStatusColor,
                    isFocused: controller.permissionPanelFocus == .accessibility
                ) {
                    if controlModeIsAvailable {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) {
                                accessibilityActions
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                accessibilityActions
                            }
                        }
                    }
                }
                #endif

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(StagePanePalette.aquaReadable)
                        .accessibilityHidden(true)
                    Text(permissionFooterText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardSurface()
            }
            .padding(.top, 38)
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
        .onAppear {
            controller.refreshPermissionStatus()
        }
    }

    private var permissionFooterText: String {
        #if STAGEPANE_APP_STORE
        L10n.text(
            "この画面を開くだけでは、macOSの確認ダイアログは表示されません。ソースを解除するか、すべて停止すると、そのソース用の共有アクセスも終了します。",
            "Opening this page never shows a macOS consent dialog by itself. Removing a source or stopping all sources ends the sharing access for that source."
        )
        #else
        L10n.text(
            "この画面を開くだけでは、macOSの確認ダイアログは表示されません。ソースを解除すると共有アクセスが終了し、操作用のアクセシビリティ許可はシステム設定からいつでも取り消せます。",
            "Opening this page never shows a macOS consent dialog by itself. Removing a source ends its sharing access, and you can revoke Control's Accessibility access in System Settings at any time."
        )
        #endif
    }

    private var screenSharingStatusTitle: String {
        if capture.isPickerPresented {
            return L10n.text("macOSで選択中", "Choosing in macOS")
        }
        if capture.isCaptureActive {
            return L10n.text("選択済み", "Source selected")
        }
        return L10n.text("追加時に確認", "Confirmed when added")
    }

    private var screenSharingStatusSymbol: String {
        if capture.isPickerPresented { return "ellipsis.circle.fill" }
        if capture.isCaptureActive { return "checkmark.circle.fill" }
        return "checkmark.shield.fill"
    }

    private var screenSharingStatusColor: Color {
        StagePanePalette.mintReadable
    }

    private var addSourceButton: some View {
        Button(action: controller.chooseSource) {
            Label(L10n.text("ソースを追加", "Add Source"), systemImage: "plus")
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(!capture.canAddSource)
        .accessibilityHint(L10n.text(
            "Appleの共有内容選択画面を開きます。",
            "Opens Apple’s content-sharing picker."
        ))
    }

    #if !STAGEPANE_APP_STORE
    private var controlModeIsAvailable: Bool {
        if #available(macOS 15.2, *) { return true }
        return false
    }

    private var accessibilityStatusTitle: String {
        guard controlModeIsAvailable else {
            return L10n.text("macOS 15.2以降", "Requires macOS 15.2")
        }
        if controller.previewInputAccessGranted {
            return L10n.text("許可済み", "Allowed")
        }
        if controller.previewInputRequestWasAttempted {
            return L10n.text("現在のビルドは未許可", "Current build not allowed")
        }
        return L10n.text("未許可", "Not allowed")
    }

    private var accessibilityDetail: String {
        let base = L10n.text(
            "1つのウインドウとして追加したソース内で、押下に対応するボタンやコントロールをプレビューから操作するためだけに使います。配置と手書きには不要です。",
            "Used only to press supported buttons and controls from the preview in a source added as one window. Arrange and Draw don’t need it."
        )
        guard !controller.previewInputAccessGranted,
              controller.previewInputRequestWasAttempted else { return base }
        if controller.isAdHocDevelopmentBuild {
            return base + "\n\n" + L10n.text(
                "このアドホック開発版は、更新のたびにmacOS上で別のアプリとして扱われます。システム設定でStagePaneがONでも、次の手順で現在のアプリを登録し直してください。\n1. 古いStagePane行があれば選び「−」で削除\n2. 「＋」から \(controller.runningApplicationPath) を追加\n3. StagePaneをONにして、この画面で「再確認」",
                "This ad-hoc development build is treated as a different app by macOS after each update. Even if StagePane is On in System Settings, register the current app again:\n1. If an old StagePane row exists, select it and remove it with “−”\n2. Use “+” to add \(controller.runningApplicationPath)\n3. Turn StagePane on, then choose Recheck here"
            )
        }
        return base + "\n\n" + L10n.text(
            "システム設定の「プライバシーとセキュリティ」→「アクセシビリティ」で、現在のStagePaneをONにしてください。行がない場合は「＋」から \(controller.runningApplicationPath) を追加し、この画面で「再確認」を選んでください。",
            "Turn on the current StagePane in System Settings under Privacy & Security → Accessibility. If no row exists, use “+” to add \(controller.runningApplicationPath), then choose Recheck here."
        )
    }

    private var accessibilityStatusSymbol: String {
        guard controlModeIsAvailable else { return "minus.circle.fill" }
        return controller.previewInputAccessGranted
            ? "checkmark.circle.fill"
            : "exclamationmark.circle.fill"
    }

    private var accessibilityStatusColor: Color {
        guard controlModeIsAvailable else { return .secondary }
        return controller.previewInputAccessGranted
            ? StagePanePalette.mintReadable
            : .orange
    }

    @ViewBuilder
    private var accessibilityActions: some View {
        if controller.previewInputAccessGranted {
            Button(action: controller.refreshPermissionStatus) {
                Label(L10n.text("再確認", "Recheck"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        } else if controller.previewInputRequestWasAttempted {
            Button(action: controller.reviewPreviewInputAccess) {
                Label(L10n.text("アクセシビリティ設定を開く", "Open Accessibility Settings"), systemImage: "gear")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityHint(L10n.text(
                "macOSのアクセシビリティ設定を開きます。再登録手順はこのカードに表示されています。",
                "Opens macOS Accessibility settings. Re-registration steps are shown in this card."
            ))

            Button(action: controller.refreshPermissionStatus) {
                Label(L10n.text("再確認", "Recheck"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        } else {
            Button(action: controller.requestPreviewInputAccess) {
                Label(L10n.text("設定を続ける", "Continue Setup"), systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityHint(L10n.text(
                "macOSのアクセシビリティ確認画面を開きます。",
                "Opens the macOS Accessibility confirmation."
            ))

            Button(action: controller.openAccessibilitySettings) {
                Label(L10n.text("システム設定を開く", "Open System Settings"), systemImage: "gear")
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .accessibilityHint(L10n.text(
                "プライバシーとセキュリティのアクセシビリティ設定を開きます。",
                "Opens Accessibility in Privacy & Security."
            ))
        }
    }
    #endif
}

struct PrivacyPanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var capture: CaptureCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(
                    eyebrow: L10n.text("PRIVACY BY DESIGN", "PRIVACY BY DESIGN"),
                    title: L10n.text("StagePaneの画面処理は、Macの中だけ。", "StagePane processes your screen locally."),
                    detail: L10n.text(
                        "StagePane自身には録画・アップロード・解析・広告の経路がありません。共有時の送信は、会議アプリ側の機能とポリシーに従います。",
                        "StagePane itself has no recorder, upload path, analytics, or ads. When you share the Stage, transmission is handled by your meeting app."
                    )
                )

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
                        detail: L10n.text("保存せず破棄", "Displayed, then discarded")
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
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if capture.isCaptureActive || captureNeedsAttention {
                        Button(action: controller.stopPreview) {
                            Label(L10n.text("画面取得を完全に停止", "Stop Capture Completely"), systemImage: "stop.circle.fill")
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                    }
                }
                .cardSurface()

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("StagePaneがしないこと", "What StagePane never does"))
                        .font(.headline)
                        .padding(.bottom, 9)
                    PrivacyPromise(symbol: "externaldrive.badge.xmark", title: L10n.text("画面フレームをディスクへ保存しません", "Never writes screen frames to disk"))
                    Divider().padding(.leading, 42)
                    PrivacyPromise(symbol: "network.slash", title: L10n.text("画面や利用状況をネットワーク送信しません", "Never sends your screen or usage over the network"))
                    Divider().padding(.leading, 42)
                    PrivacyPromise(symbol: "waveform.badge.exclamationmark", title: L10n.text("音声・マイクを取得しません", "Never captures audio or microphone input"))
                    Divider().padding(.leading, 42)
                    PrivacyPromise(symbol: "person.crop.circle.badge.xmark", title: L10n.text("アカウントや追跡IDを作りません", "Never creates an account or tracking ID"))
                }
                .cardSurface()

            }
            .padding(.top, 38)
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
    }

    private var captureNeedsAttention: Bool {
        if case .failed = capture.phase { return true }
        return false
    }

    private var captureStatusSymbol: String {
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
                "取得は停止中です。最後のフレームと配置を保持したまま、ソース一覧から再開できます。",
                "Capture is paused. The last frames and layout remain in place until you resume from the source list."
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
                SectionHeading(
                    eyebrow: L10n.text("ABOUT", "ABOUT"),
                    title: "StagePane",
                    detail: L10n.text(
                        "見せたいものだけ、ひとつのステージへ。",
                        "A clean stage for everything you share."
                    )
                )

                HStack(spacing: 24) {
                    BrandMark(size: 92)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("StagePane")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Version \(version)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(L10n.text(
                            "画面共有専用のステージ",
                            "Screen Share Stage"
                        ))
                        .font(.subheadline)
                    }
                    Spacer()
                }
                .cardSurface()

                HStack(spacing: 10) {
                    Button {
                        controller.openBundledDocument(resource: "PRIVACY", extension: "md")
                    } label: {
                        Label(L10n.text("プライバシーポリシー", "Privacy Policy"), systemImage: "hand.raised.fill")
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
                        symbol: "apple.logo",
                        title: L10n.text("公開APIのみ", "Public APIs only"),
                        detail: L10n.text(
                            "SwiftUI、AppKit、ScreenCaptureKitを使ったサンドボックス対応設計です。",
                            "Built with SwiftUI, AppKit, and ScreenCaptureKit in an App Sandbox-ready architecture."
                        )
                    )
                    Divider().padding(.leading, 42)
                    AboutFact(
                        symbol: "shippingbox.fill",
                        title: L10n.text("第三者ランタイム依存なし", "No third-party runtime dependencies"),
                        detail: L10n.text(
                            "解析SDK、広告SDK、自動更新フレームワークを同梱していません。",
                            "Ships without analytics, advertising, or self-update frameworks."
                        )
                    )
                }
                .cardSurface()

                Text(L10n.text(
                        "ロゴとアイコンの著作物としての利用はApache-2.0で許諾されます。ただし、公式性や提携を示す商標としてStagePaneの名称・ロゴを使う権利は付与されません。詳しくは同梱の商標ポリシーを確認してください。",
                        "Apache-2.0 licenses copyright use of the logo and icon artwork, but it does not grant trademark rights to use the StagePane name or marks to imply official status or affiliation. See the bundled trademark policy for details."
                ))
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.top, 38)
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
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
                .accessibilityHint(L10n.pointerStyleDetail(selection))

                Text(L10n.pointerStyleDetail(selection))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)

                if selection == .redDot {
                    PointerAppearanceEditor(appearance: $appearance)
                        .padding(.top, 3)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct PointerAppearanceEditor: View {
    @Binding var appearance: PointerAppearance

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.82))
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

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(L10n.text("サイズ", "Size"))
                        .frame(width: 42, alignment: .leading)
                    Slider(
                        value: diameterBinding,
                        in: PointerAppearance.minimumDiameter...PointerAppearance.maximumDiameter,
                        step: 1
                    )
                    .accessibilityLabel(L10n.text("ポインターのサイズ", "Pointer size"))
                    Text("\(Int(appearance.diameter.rounded())) pt")
                        .font(.caption.monospacedDigit())
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
                    Text("\(Int((appearance.glow * 100).rounded()))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 43, alignment: .trailing)
                }

                HStack {
                    ColorPicker(
                        L10n.text("色", "Color"),
                        selection: colorBinding,
                        supportsOpacity: false
                    )
                    .accessibilityLabel(L10n.text("ポインターの色", "Pointer color"))

                    Spacer()

                    Button(L10n.text("標準に戻す", "Reset")) {
                        appearance = .presentationDefault
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint(L10n.text(
                        "赤色、22ポイント、中程度の発光に戻します。",
                        "Restore red, 22 points, and medium glow."
                    ))
                }
            }
            .font(.caption)
        }
        .padding(12)
        .background(
            Color.primary.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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

private struct PermissionAccessCard<Actions: View>: View {
    let symbol: String
    let title: String
    let role: String
    let detail: String
    let statusTitle: String
    let statusSymbol: String
    let statusColor: Color
    let isFocused: Bool
    let actions: Actions

    init(
        symbol: String,
        title: String,
        role: String,
        detail: String,
        statusTitle: String,
        statusSymbol: String,
        statusColor: Color,
        isFocused: Bool,
        @ViewBuilder actions: () -> Actions
    ) {
        self.symbol = symbol
        self.title = title
        self.role = role
        self.detail = detail
        self.statusTitle = statusTitle
        self.statusSymbol = statusSymbol
        self.statusColor = statusColor
        self.isFocused = isFocused
        self.actions = actions()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(StagePanePalette.aquaReadable)
                    .frame(width: 36, height: 36)
                    .background(
                        StagePanePalette.aquaReadable.opacity(0.11),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                        Text(role)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(StagePanePalette.indigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                StagePanePalette.indigo.opacity(0.10),
                                in: Capsule()
                            )
                    }

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Label(statusTitle, systemImage: statusSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.10), in: Capsule())
                    .accessibilityLabel(title)
                    .accessibilityValue(statusTitle)
            }

            actions
        }
        .cardSurface()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isFocused ? StagePanePalette.aquaReadable.opacity(0.72) : .clear,
                    lineWidth: 2
                )
        )
        .accessibilityElement(children: .contain)
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
                .font(.caption.weight(.bold))
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FlowArrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.caption.weight(.bold))
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
                .font(.caption.weight(.black))
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
