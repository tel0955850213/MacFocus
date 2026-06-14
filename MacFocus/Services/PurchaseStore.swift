import Foundation
import StoreKit

/// StoreKit 2 subscription store. Sells "Focus Quest Pro" (monthly / yearly) and
/// tracks the entitlement. Exposed both as a singleton (so non-View code like
/// ProgressStore can read `isPro`) and as an ObservableObject for the UI.
@MainActor
final class PurchaseStore: ObservableObject {
    static let shared = PurchaseStore()

    /// Product IDs — must match App Store Connect / the StoreKit config file.
    static let monthlyID = "com.donaldlin.macfocus.pro.monthly"
    static let yearlyID  = "com.donaldlin.macfocus.pro.yearly"
    private var productIDs: [String] { [Self.monthlyID, Self.yearlyID] }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task { await refresh() }
    }

    deinit { updatesTask?.cancel() }

    /// Load products and re-check entitlement.
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            lastError = error.localizedDescription
        }
        await updateEntitlement()
    }

    /// Purchase a product. Returns true on a verified success.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await updateEntitlement()
                    return isPro
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Restore purchases (re-sync with the App Store).
    func restore() async {
        do { try await AppStore.sync() } catch { lastError = error.localizedDescription }
        await updateEntitlement()
    }

    /// Re-derive `isPro` from current entitlements.
    func updateEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updateEntitlement()
                }
            }
        }
    }
}
