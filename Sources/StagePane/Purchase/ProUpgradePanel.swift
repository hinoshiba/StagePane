import SwiftUI

struct ProUpgradePanel: View {
    @ObservedObject var controller: AppController
    @ObservedObject var purchases: ProPurchaseStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                upgradeHero

                if purchases.hasProAccess {
                    activeProCard
                } else {
                    triggerCard
                    purchaseCard
                    benefitGrid
                    planComparison
                }

                privacyNote
            }
            .padding(.top, 30)
            .padding(.horizontal, 30)
            .padding(.bottom, 34)
            .frame(maxWidth: 960, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("StagePane Pro")
    }

    private var upgradeHero: some View {
        HStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                StagePanePalette.indigo.opacity(0.30),
                                StagePanePalette.aqua.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                BrandMark(size: 74)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(StagePanePalette.aqua)
                    .offset(x: 42, y: -38)
            }
            .frame(width: 126, height: 116)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("STAGEPANE PRO")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(StagePanePalette.aquaReadable)
                Text(L10n.text(
                    "あなたの発表を、あなたのステージで。",
                    "Make every presentation your own."
                ))
                .font(.system(.title, design: .rounded, weight: .bold))
                .tracking(-0.7)
                .accessibilityHeading(.h1)
                Text(L10n.text(
                    "買い切りでソース数の制限がなくなり、ロゴも非表示にできます。",
                    "One purchase removes StagePane’s source limit and lets you hide the StagePane mark."
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(StagePanePalette.aqua.opacity(0.18))
                )
        )
    }

    @ViewBuilder
    private var triggerCard: some View {
        switch controller.proUpgradeTrigger {
        case .sourceLimit:
            UpgradeReasonCard(
                symbol: "rectangle.3.group.fill",
                title: L10n.text(
                    "さらにソースを追加するにはPro",
                    "Add more sources with Pro"
                ),
                detail: L10n.text(
                    "現在のソースはそのままです。購入後、追加する内容をAppleの選択画面で選べます。",
                    "Your current sources stay in place. After purchase, choose the next item in Apple’s picker."
                )
            )
        case .watermark:
            UpgradeReasonCard(
                symbol: "sparkles.rectangle.stack.fill",
                title: L10n.text(
                    "ロゴのないStageはProで使えます",
                    "A mark-free Stage is included with Pro"
                ),
                detail: L10n.text(
                    "購入後、Stage、カーテン、Audience画像からStagePaneロゴをすぐに非表示にします。",
                    "After purchase, the StagePane mark is removed immediately from the Stage, Curtain, and Audience images."
                )
            )
        case .direct:
            EmptyView()
        }
    }

    private var benefitGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 230), spacing: 12)],
            spacing: 12
        ) {
            ProBenefitCard(
                symbol: "rectangle.3.group.fill",
                title: L10n.text(
                    "アプリ側のソース数制限なし",
                    "No app-imposed source limit"
                ),
                detail: L10n.text(
                    "スライド、デモ、コード、資料をひとつのStageへ。",
                    "Bring slides, a demo, references, and more onto one Stage."
                )
            )
            ProBenefitCard(
                symbol: "rectangle.badge.minus",
                title: L10n.text("ロゴを非表示", "Hide the StagePane mark"),
                detail: L10n.text(
                    "Stage、カーテン、保存するAudience画像まで、すっきり表示。",
                    "Keep the Stage, Curtain, and saved Audience images clean."
                )
            )
            ProBenefitCard(
                symbol: "checkmark.seal.fill",
                title: L10n.text("買い切り", "One-time purchase"),
                detail: L10n.text(
                    "サブスクリプション、StagePaneアカウント、広告はありません。",
                    "No subscription, StagePane account, or advertising."
                )
            )
        }
    }

    private var planComparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("無料版も、発表に必要な安全機能はそのまま。", "The free app keeps every safety essential."))
                .font(.headline)

            PlanComparisonRow(
                title: L10n.text("同時に使えるソース", "Simultaneous sources"),
                freeValue: L10n.text("4つ", "Four"),
                proValue: L10n.text("アプリ側の上限なし", "No app limit")
            )
            Divider()
            PlanComparisonRow(
                title: L10n.text("StagePaneロゴ", "StagePane mark"),
                freeValue: L10n.text("表示", "Shown"),
                proValue: L10n.text("表示／非表示", "Optional")
            )
            Divider()
            PlanComparisonRow(
                title: L10n.text(
                    "カーテン・停止・配置・切り抜き・手書き",
                    "Curtain, Stop, Arrange, Crop, and Draw"
                ),
                freeValue: L10n.text("すべて利用可", "Included"),
                proValue: L10n.text("すべて利用可", "Included")
            )
        }
        .cardSurface()
    }

    private var purchaseCard: some View {
        VStack(spacing: 14) {
            if let statusMessage = purchases.statusMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: purchases.operationState == .pending
                        ? "clock.badge.exclamationmark"
                        : "info.circle.fill")
                        .foregroundStyle(purchases.operationState == .failed ? .orange : StagePanePalette.aquaReadable)
                    Text(statusMessage)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
            }

            Button {
                Task { await purchases.purchase() }
            } label: {
                HStack(spacing: 9) {
                    if purchases.operationState == .purchasing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(purchaseButtonTitle)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!purchases.canPurchase)
            .keyboardShortcut(.defaultAction)

            Text(L10n.text(
                "一度だけのお支払いです。サブスクリプションではありません。価格と通貨はApp Storeが表示します。",
                "Pay once. This is not a subscription. Price and currency are provided by the App Store."
            ))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button {
                    Task { await purchases.restorePurchases() }
                } label: {
                    if purchases.operationState == .restoring {
                        Label(L10n.text("復元中…", "Restoring…"), systemImage: "arrow.clockwise")
                    } else {
                        Label(L10n.text("購入を復元", "Restore Purchases"), systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(purchases.isBusy || purchases.operationState == .pending)

                if purchases.product == nil,
                   purchases.operationState != .loadingProduct {
                    Button {
                        Task { await purchases.retryLoadingProduct() }
                    } label: {
                        Label(L10n.text("再読み込み", "Reload"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .disabled(purchases.isBusy)
                }

                Button {
                    controller.selectWorkspaceSection(.canvas)
                } label: {
                    Text(L10n.text("無料版を続ける", "Continue Free"))
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .cardSurface()
    }

    private var activeProCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 13) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(StagePanePalette.mintReadable)
                VStack(alignment: .leading, spacing: 3) {
                    Text(purchases.entitlementState == .sourceBuild
                        ? L10n.text("ソースビルドでは全機能を利用できます", "All features are available in source builds")
                        : L10n.text("StagePane Proが有効です", "StagePane Pro is active"))
                        .font(.headline)
                    Text(L10n.text(
                        "StagePaneによる件数制限なしでソースを追加し、ロゴ表示も切り替えられます。",
                        "You can add sources without an app-imposed limit and choose whether to show the StagePane mark."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            if let statusMessage = purchases.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                if controller.proUpgradeTrigger == .sourceLimit,
                   controller.canRequestSourceAddition {
                    Button(action: controller.chooseSource) {
                        Label(L10n.text("次のソースを追加", "Add the Next Source"), systemImage: "plus")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                } else if controller.proUpgradeTrigger == .watermark {
                    Button {
                        controller.requestWatermarkVisibility(false)
                        controller.selectWorkspaceSection(.appearance)
                    } label: {
                        Label(L10n.text("ロゴを非表示", "Hide the StagePane Mark"), systemImage: "rectangle.badge.minus")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }

                Button {
                    controller.selectWorkspaceSection(.canvas)
                } label: {
                    Text(L10n.text("キャンバスへ戻る", "Return to Canvas"))
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .cardSurface()
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(StagePanePalette.aquaReadable)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("購入はAppleが処理", "Purchase handled by Apple"))
                    .font(.caption.weight(.semibold))
                Text(L10n.text(
                    "購入状態はStoreKitの検証済み取引で確認します。StagePaneのアカウントや解析SDKは追加しません。画面内容を購入処理へ渡すこともありません。",
                    "Access is based on StoreKit-verified transactions. StagePane adds no account or analytics SDK and never provides screen content to the purchase flow."
                ))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                Button(L10n.text("プライバシーポリシー", "Privacy Policy")) {
                    controller.openPrivacyPolicy()
                }
                .buttonStyle(.link)
                .font(.caption2)
            }
        }
        .cardSurface()
    }

    private var purchaseButtonTitle: String {
        if purchases.operationState == .loadingProduct {
            return L10n.text("価格を読み込み中…", "Loading Price…")
        }
        if purchases.operationState == .purchasing {
            return L10n.text("購入を確認中…", "Completing Purchase…")
        }
        guard let price = purchases.product?.displayPrice else {
            return L10n.text("StagePane Proを購入", "Purchase StagePane Pro")
        }
        return L10n.text(
            "StagePane Proを購入 — \(price)",
            "Purchase StagePane Pro — \(price)"
        )
    }
}

private struct UpgradeReasonCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(StagePanePalette.aquaReadable)
                .frame(width: 34, height: 34)
                .background(StagePanePalette.aquaReadable.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(StagePanePalette.indigo.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(StagePanePalette.indigo.opacity(0.20)))
        .accessibilityElement(children: .combine)
    }
}

private struct ProBenefitCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(StagePanePalette.aquaReadable)
            Text(title).font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .cardSurface(cornerRadius: 16, padding: 17)
        .accessibilityElement(children: .combine)
    }
}

private struct PlanComparisonRow: View {
    let title: String
    let freeValue: String
    let proValue: String

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 0) {
            GridRow {
                Text(title)
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(freeValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)
                Text(proValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(StagePanePalette.aquaReadable)
                    .frame(width: 112, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.text(
            "\(title)、無料版: \(freeValue)、Pro: \(proValue)",
            "\(title), Free: \(freeValue), Pro: \(proValue)"
        ))
    }
}
