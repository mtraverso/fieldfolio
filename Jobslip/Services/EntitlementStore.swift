import Foundation
import StoreKit

@MainActor
final class EntitlementStore: ObservableObject {
    static let monthlyID = "com.fieldfolio.app.pro.monthly"
    static let yearlyID = "com.fieldfolio.app.pro.yearly"
    static let lifetimeID = "com.fieldfolio.app.pro.lifetime"

    static let allProductIDs: Set<String> = [monthlyID, yearlyID, lifetimeID]

    static let freeClientLimit = 3
    static let freeJobLimit = 8

    @Published private(set) var isPro = false
    @Published private(set) var hasResolvedEntitlements = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        await loadProducts()
        await updateEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        purchaseError = nil
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            products = loaded.sorted { lhs, rhs in
                let order = [Self.monthlyID, Self.yearlyID, Self.lifetimeID]
                let li = order.firstIndex(of: lhs.id) ?? 99
                let ri = order.firstIndex(of: rhs.id) ?? 99
                return li < ri
            }
            if products.isEmpty {
                // Paywall shows static fallback prices; keep this quiet until a purchase is attempted.
                purchaseError = nil
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func purchase(productID: String) async {
        purchaseError = nil

        if products.first(where: { $0.id == productID }) == nil {
            await loadProducts()
        }

        guard let product = products.first(where: { $0.id == productID }) else {
            #if DEBUG
            // Simulator / no StoreKit config: still unlock so the paywall is testable.
            UserDefaults.standard.set(true, forKey: "FieldFolioDebugPro")
            await updateEntitlements()
            if isPro { return }
            #endif
            purchaseError = "Couldn’t load \(productID). Select Jobslip.storekit in the Run scheme’s StoreKit Configuration, then run again."
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateEntitlements()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                purchaseError = "Purchase didn’t complete."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restore() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await updateEntitlements()
            if !isPro {
                purchaseError = "No active Pro purchase found for this Apple ID."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func canAddClient(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeClientLimit
    }

    func canAddJob(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeJobLimit
    }

    var shouldWatermarkPDFs: Bool { !isPro }

    private func updateEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if Self.allProductIDs.contains(transaction.productID) {
                    entitled = true
                    break
                }
            }
        }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "FieldFolioDebugPro") {
            entitled = true
        }
        #endif
        if let suite = UserDefaults(suiteName: WidgetSnapshotWriter.suiteName) {
            #if DEBUG
            suite.set(entitled, forKey: "FieldFolioDebugPro")
            #endif
            suite.set(entitled, forKey: WidgetSnapshotWriter.isProKey)
            suite.synchronize()
        }
        let changed = isPro != entitled
        isPro = entitled
        hasResolvedEntitlements = true
        if changed || entitled {
            WidgetSnapshotWriter.setPro(entitled)
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await updateEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
