import StoreKit
import SwiftUI

@MainActor
final class SupportSubscriptionStore: ObservableObject {
    static let monthlyProductID = "7imuzi.EbbinghausReminder.support.monthly"

    enum LoadState {
        case idle
        case loading
        case loaded
        case failed
    }

    @Published private(set) var product: Product?
    @Published private(set) var isSubscribed = false
    @Published private(set) var hasCheckedEntitlement = false
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var isPurchasing = false
    @Published var errorMessage: String?

    private var transactionUpdatesTask: _Concurrency.Task<Void, Never>?

    init() {
        transactionUpdatesTask = observeTransactionUpdates()
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func prepare() async {
        async let products: Void = loadProduct()
        async let entitlement: Void = refreshEntitlement()
        _ = await (products, entitlement)
    }

    func loadProduct() async {
        guard loadState != .loading else { return }

        loadState = .loading
        errorMessage = nil

        do {
            product = try await Product.products(for: [Self.monthlyProductID]).first
            if product == nil {
                loadState = .failed
                errorMessage = "購入情報を読み込めませんでした。時間をおいて再度お試しください。"
            } else {
                loadState = .loaded
            }
        } catch {
            loadState = .failed
            errorMessage = "購入情報を読み込めませんでした。通信環境をご確認ください。"
        }
    }

    func purchase() async {
        guard let product, !isPurchasing else { return }

        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try Self.verified(verification)
                await transaction.finish()
                await refreshEntitlement()
            case .pending:
                errorMessage = "購入は承認待ちです。承認後に自動で反映されます。"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "購入を完了できませんでした。もう一度お試しください。"
        }
    }

    func restorePurchases() async {
        errorMessage = nil

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isSubscribed {
                errorMessage = "有効なサブスクリプションが見つかりませんでした。"
            }
        } catch {
            errorMessage = "購入情報を復元できませんでした。通信環境をご確認ください。"
        }
    }

    func refreshEntitlement() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.monthlyProductID,
                  transaction.revocationDate == nil else {
                continue
            }

            hasActiveSubscription = true
            break
        }

        isSubscribed = hasActiveSubscription
        hasCheckedEntitlement = true
        WidgetSnapshotStore.saveSubscriptionStatus(isSubscribed: hasActiveSubscription)
    }

    private func observeTransactionUpdates() -> _Concurrency.Task<Void, Never> {
        _Concurrency.Task { [weak self] in
            for await result in Transaction.updates {
                guard !_Concurrency.Task.isCancelled else { return }
                guard case .verified(let transaction) = result else { continue }
                guard transaction.productID == Self.monthlyProductID else { continue }

                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }
    }

    nonisolated private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw VerificationError.failed
        }
    }

    private enum VerificationError: Error {
        case failed
    }
}
