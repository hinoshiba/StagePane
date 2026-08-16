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
                    PreferenceToggle(
                        title: L10n.text("カーソルを表示", "Show pointer"),
                        detail: L10n.text(
                            "選択したソース内のポインタをプレビューします。",
                            "Include the pointer from your chosen source."
                        ),
                        symbol: "cursorarrow",
                        value: $controller.showsCursor
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

                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.text("画面収録のシステム設定", "Screen Recording settings"))
                            .font(.headline)
                        Text(L10n.text(
                            "権限を後から取り消したり、再確認できます。",
                            "Review or revoke permission at any time."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: controller.openScreenCaptureSettings) {
                        Label(L10n.text("システム設定を開く", "Open System Settings"), systemImage: "gear")
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
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
        if capture.isCaptureActive { return "rectangle.inset.filled" }
        switch capture.phase {
        case .choosing, .preparing: return "ellipsis.circle.fill"
        default: return "checkmark.shield.fill"
        }
    }

    private var captureStatusColor: Color {
        if captureNeedsAttention { return .orange }
        if capture.isCaptureActive { return StagePanePalette.mintReadable }
        return StagePanePalette.aquaReadable
    }

    private var captureStatusTitle: String {
        if captureNeedsAttention {
            return L10n.text("プレビューの確認が必要", "Preview needs attention")
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

                VStack(alignment: .leading, spacing: 9) {
                    Text(L10n.text("重要な制約", "Important limitation"))
                        .font(.headline)
                    Text(L10n.text(
                        "StagePaneはmacOSにディスプレイや別のデスクトップ環境を追加しません。他アプリのウインドウを直接操作する機能もありません。ユーザーが選んだ内容を、会議アプリで共有できる通常のウインドウへ表示します。",
                        "StagePane does not add a display or alternate desktop environment to macOS, and it does not directly control other apps. It presents user-selected content inside a regular window that meeting apps can share."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.orange.opacity(0.18)))

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
