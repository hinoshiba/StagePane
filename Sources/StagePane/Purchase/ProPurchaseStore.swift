import Foundation
import StoreKit

@MainActor
final class ProPurchaseStore: ObservableObject {
    static let productID = "com.hinoshiba.stagepane.pro"

    enum EntitlementState: Equatable {
        case checking
        case free
        case pro
        case sourceBuild
    }

    enum OperationState: Equatable {
        case idle
        case loadingProduct
        case purchasing
        case pending
        case restoring
        case failed
    }

    @Published private(set) var entitlementState: EntitlementState
    @Published private(set) var operationState: OperationState = .idle
    @Published private(set) var product: Product?
    @Published private(set) var statusMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?
    private var entitlementRefreshGeneration: UInt = 0

    var hasProAccess: Bool {
        entitlementState == .pro || entitlementState == .sourceBuild
    }

    var isStoreCommerceEnabled: Bool {
#if STAGEPANE_APP_STORE
        true
#else
        false
#endif
    }

    var isBusy: Bool {
        switch operationState {
        case .loadingProduct, .purchasing, .restoring:
            true
        case .idle, .pending, .failed:
            false
        }
    }

    var canPurchase: Bool {
        product != nil &&
            AppStore.canMakePayments &&
            !hasProAccess &&
            !isBusy &&
            operationState != .pending
    }

    init() {
#if STAGEPANE_APP_STORE
        entitlementState = .checking
        // Close the restore/retry race before the initial async entitlement
        // check yields back to the main actor.
        operationState = .loadingProduct
        transactionUpdatesTask = observeTransactionUpdates()
        Task { [weak self] in
            await self?.prepare()
        }
#else
        // Source-built development binaries remain fully functional. Commerce
        // applies only to the official Mac App Store target.
        entitlementState = .sourceBuild
#endif
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    private func prepare() async {
        guard isStoreCommerceEnabled,
              operationState == .loadingProduct else { return }
        await refreshEntitlement()
        guard !hasProAccess else {
            operationState = .idle
            statusMessage = nil
            return
        }
        await loadProduct()
    }

    func retryLoadingProduct() async {
        guard isStoreCommerceEnabled,
              !hasProAccess,
              !isBusy,
              operationState != .pending else { return }
        operationState = .loadingProduct
        statusMessage = nil
        await refreshEntitlement()
        guard !hasProAccess else {
            operationState = .idle
            statusMessage = L10n.text(
                "StagePane Proが有効です。",
                "StagePane Pro is active."
            )
            return
        }
        await loadProduct()
    }

    func purchase() async {
        guard isStoreCommerceEnabled,
              !hasProAccess,
              !isBusy,
              operationState != .pending else { return }
        guard AppStore.canMakePayments else {
            operationState = .failed
            statusMessage = L10n.text(
                "このMacまたはApple Accountではアプリ内課金が許可されていません。スクリーンタイムや管理設定を確認してください。",
                "In-App Purchases are not allowed for this Mac or Apple Account. Check Screen Time or device-management settings."
            )
            return
        }
        guard let product else {
            statusMessage = L10n.text(
                "価格を取得できませんでした。再読み込みしてからお試しください。",
                "The price is unavailable. Reload the purchase information and try again."
            )
            operationState = .failed
            return
        }
        guard product.type == .nonConsumable else {
            statusMessage = L10n.text(
                "購入商品の設定を確認できませんでした。",
                "The purchase product is not configured correctly."
            )
            operationState = .failed
            return
        }

        operationState = .purchasing
        statusMessage = nil

        do {
            switch try await product.purchase() {
            case .success(let result):
                switch result {
                case .verified(let transaction):
                    guard transaction.productID == Self.productID else {
                        operationState = .failed
                        statusMessage = L10n.text(
                            "購入内容を確認できませんでした。",
                            "The purchased product could not be verified."
                        )
                        return
                    }
                    await transaction.finish()
                    await refreshEntitlement()
                    operationState = .idle
                    statusMessage = hasProAccess
                        ? L10n.text(
                            "StagePane Proが有効になりました。ありがとうございます。",
                            "StagePane Pro is now active. Thank you."
                        )
                        : L10n.text(
                            "購入は完了しましたが、権利をまだ確認できません。購入を復元してください。",
                            "The purchase completed, but access is not available yet. Try Restore Purchases."
                        )
                case .unverified:
                    operationState = .failed
                    statusMessage = L10n.text(
                        "App Storeが購入を検証できなかったため、機能を開放しませんでした。",
                        "The App Store could not verify the purchase, so Pro was not unlocked."
                    )
                }
            case .pending:
                operationState = .pending
                statusMessage = L10n.text(
                    "購入は承認待ちです。承認されると自動的にProが有効になります。",
                    "The purchase is awaiting approval. Pro will unlock automatically after approval."
                )
            case .userCancelled:
                operationState = .idle
            @unknown default:
                operationState = .failed
                statusMessage = L10n.text(
                    "購入を完了できませんでした。しばらくしてからお試しください。",
                    "The purchase could not be completed. Please try again later."
                )
            }
        } catch StoreKitError.userCancelled {
            operationState = .idle
            statusMessage = nil
        } catch StoreKitError.networkError {
            operationState = .failed
            statusMessage = L10n.text(
                "購入を完了できませんでした。App Storeへの接続を確認して、もう一度お試しください。",
                "The purchase could not be completed. Check your App Store connection and try again."
            )
        } catch StoreKitError.notAvailableInStorefront {
            operationState = .failed
            statusMessage = L10n.text(
                "StagePane Proは現在のApp Store地域では購入できません。",
                "StagePane Pro is not available in the current App Store storefront."
            )
        } catch {
            operationState = .failed
            statusMessage = L10n.text(
                "購入を完了できませんでした。App Storeの購入設定を確認して、もう一度お試しください。",
                "The purchase could not be completed. Check your App Store purchase settings and try again."
            )
        }
    }

    func restorePurchases() async {
        guard isStoreCommerceEnabled,
              !isBusy,
              operationState != .pending else { return }
        operationState = .restoring
        statusMessage = nil

        do {
            // AppStore.sync() may ask for Apple Account authentication, so it
            // is called only from the explicit Restore Purchases action.
            try await AppStore.sync()
            await refreshEntitlement()
            operationState = .idle
            statusMessage = hasProAccess
                ? L10n.text(
                    "StagePane Proの購入を復元しました。",
                    "Your StagePane Pro purchase was restored."
                )
                : L10n.text(
                    "このApple Accountで復元できる購入は見つかりませんでした。",
                    "No restorable purchase was found for this Apple Account."
                )
        } catch StoreKitError.userCancelled {
            operationState = .idle
            statusMessage = nil
        } catch StoreKitError.networkError {
            operationState = .failed
            statusMessage = L10n.text(
                "購入を復元できませんでした。App Storeへの接続を確認してください。",
                "Purchases could not be restored. Check your App Store connection."
            )
        } catch {
            operationState = .failed
            statusMessage = L10n.text(
                "購入を復元できませんでした。Apple Accountの購入設定を確認してください。",
                "Purchases could not be restored. Check the purchase settings for your Apple Account."
            )
        }
    }

    private func loadProduct() async {
        guard isStoreCommerceEnabled else { return }

        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first { $0.id == Self.productID }
            if hasProAccess {
                operationState = .idle
                statusMessage = nil
            } else if product == nil {
                operationState = .failed
                statusMessage = L10n.text(
                    "StagePane ProをApp Storeから読み込めませんでした。",
                    "StagePane Pro could not be loaded from the App Store."
                )
            } else if !AppStore.canMakePayments {
                operationState = .failed
                statusMessage = L10n.text(
                    "このMacまたはApple Accountではアプリ内課金が許可されていません。購入の復元は利用できます。",
                    "In-App Purchases are not allowed for this Mac or Apple Account. Restore Purchases remains available."
                )
            } else {
                operationState = .idle
            }
        } catch {
            product = nil
            if hasProAccess {
                operationState = .idle
                statusMessage = nil
            } else {
                operationState = .failed
                statusMessage = L10n.text(
                    "App Storeから価格を取得できませんでした。",
                    "The price could not be loaded from the App Store."
                )
            }
        }
    }

    private func refreshEntitlement() async {
        guard isStoreCommerceEnabled else { return }
        entitlementRefreshGeneration &+= 1
        let generation = entitlementRefreshGeneration
        var hasVerifiedEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productID,
                  transaction.revocationDate == nil else { continue }
            hasVerifiedEntitlement = true
        }

        // Launch, purchase, restore, and transaction updates may request a
        // refresh while another async scan is suspended. Only the newest
        // snapshot may publish access.
        guard generation == entitlementRefreshGeneration else { return }
        entitlementState = hasVerifiedEntitlement ? .pro : .free
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                switch result {
                case .verified(let transaction):
                    guard transaction.productID == Self.productID else { continue }
                    await self?.handleTransactionUpdate(transaction)
                case .unverified(let transaction, _):
                    guard transaction.productID == Self.productID else { continue }
                    self?.handleUnverifiedTransactionUpdate()
                }
            }
        }
    }

    private func handleUnverifiedTransactionUpdate() {
        guard operationState == .pending else { return }
        operationState = .failed
        statusMessage = L10n.text(
            "App Storeが購入を検証できなかったため、機能を開放しませんでした。",
            "The App Store could not verify the purchase, so Pro was not unlocked."
        )
    }

    private func handleTransactionUpdate(_ transaction: Transaction) async {
        let previouslyHadProAccess = hasProAccess
        await transaction.finish()
        await refreshEntitlement()

        if hasProAccess {
            statusMessage = L10n.text(
                "StagePane Proが有効になりました。",
                "StagePane Pro is now active."
            )
            // A purchase() or restorePurchases() call owns its busy state until
            // its StoreKit UI/operation returns. A pending approval has no such
            // owner, so the verified update completes it here.
            switch operationState {
            case .pending, .idle, .failed:
                operationState = .idle
            case .loadingProduct, .purchasing, .restoring:
                break
            }
        } else if previouslyHadProAccess || transaction.revocationDate != nil {
            statusMessage = L10n.text(
                "StagePane Proの購入状態が有効ではなくなりました。無料版の機能はそのまま利用できます。",
                "StagePane Pro is no longer active. Free features remain available."
            )
            if operationState == .pending {
                operationState = .idle
            }
        }
    }
}
