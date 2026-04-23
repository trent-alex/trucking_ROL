import Foundation
import StoreKit
import Observation

/// StoreKit 2 manager for lifetime purchase IAP
/// Handles product loading, purchasing, and entitlement restoration
@MainActor
@Observable
class StoreManager {

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case lifetime = "ROL_Prepremium_Lifetime"
        case lifetimeFounder = "ROL_PrePremium_Lifetime_Founder"
    }

    // MARK: - Trial Constants

    private static let freeCalculationLimit = 5

    // MARK: - Observable State

    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var purchaseInProgress = false

    /// True if user has lifetime access (via purchase or promo code)
    var isLifetimeUnlocked: Bool = false

    // MARK: - Trial State

    /// Number of free calculations remaining
    var calculationsRemaining: Int {
        max(0, Self.freeCalculationLimit - KeychainHelper.calculationCount)
    }

    /// Whether user can perform a calculation (has trial remaining or is unlocked)
    var canPerformCalculation: Bool {
        isLifetimeUnlocked || calculationsRemaining > 0
    }

    /// Increment the calculation count (call after successful calculation)
    func incrementCalculationCount() {
        guard !isLifetimeUnlocked else { return }
        KeychainHelper.calculationCount += 1
    }

    // MARK: - Private Properties

    nonisolated(unsafe) private var transactionListener: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Check Keychain on init
        isLifetimeUnlocked = KeychainHelper.isLifetimeUnlocked

        // Start listening for transactions
        transactionListener = listenForTransactions()

        // Load products and restore entitlements
        Task {
            await loadProducts()
            await restoreEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    /// Loads available products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: productIDs)

            // Sort: full price first, then founder
            products = storeProducts.sorted { lhs, _ in
                lhs.id == ProductID.lifetime.rawValue
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Purchasing

    /// Purchase a product by ID
    /// - Parameter productID: The product ID to purchase
    /// - Returns: True if purchase succeeded
    @discardableResult
    func purchase(_ productID: ProductID) async -> Bool {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            errorMessage = "Product not found"
            return false
        }

        return await purchase(product)
    }

    /// Purchase a specific product
    /// - Parameter product: The StoreKit Product to purchase
    /// - Returns: True if purchase succeeded
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleSuccessfulPurchase(transaction)
                await transaction.finish()
                purchaseInProgress = false
                return true

            case .userCancelled:
                purchaseInProgress = false
                return false

            case .pending:
                errorMessage = "Purchase pending approval"
                purchaseInProgress = false
                return false

            @unknown default:
                errorMessage = "Unknown purchase result"
                purchaseInProgress = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            purchaseInProgress = false
            return false
        }
    }

    // MARK: - Entitlement Restoration

    /// Restore purchases from App Store
    func restoreEntitlements() async {
        isLoading = true
        errorMessage = nil

        // First check Keychain (promo code unlocks)
        if KeychainHelper.isLifetimeUnlocked {
            isLifetimeUnlocked = true
            isLoading = false
            return
        }

        // Then check App Store transactions
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                await handleSuccessfulPurchase(transaction)
            } catch {
                // Transaction failed verification, skip it
                continue
            }
        }

        isLoading = false
    }

    /// Sync with App Store (forces refresh)
    func syncWithAppStore() async {
        do {
            try await AppStore.sync()
            await restoreEntitlements()
        } catch {
            errorMessage = "Failed to sync: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Helpers

    /// Listen for transaction updates (purchases, restores, refunds)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.handleSuccessfulPurchase(transaction)
                    await transaction.finish()
                } catch {
                    // Transaction failed verification
                }
            }
        }
    }

    /// Verify transaction signature
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let item):
            return item
        }
    }

    /// Handle a verified successful purchase
    private func handleSuccessfulPurchase(_ transaction: StoreKit.Transaction) async {
        // Check if this is one of our lifetime products
        guard transaction.productID == ProductID.lifetime.rawValue ||
              transaction.productID == ProductID.lifetimeFounder.rawValue else {
            return
        }

        // Non-consumable: check it hasn't been revoked
        if transaction.revocationDate == nil {
            KeychainHelper.isLifetimeUnlocked = true
            await MainActor.run {
                isLifetimeUnlocked = true
            }
        } else {
            // Purchase was refunded/revoked
            KeychainHelper.isLifetimeUnlocked = false
            await MainActor.run {
                isLifetimeUnlocked = false
            }
        }
    }

    // MARK: - Helpers

    /// Get product by ID
    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    /// Get the full-price lifetime product
    var lifetimeProduct: Product? {
        product(for: .lifetime)
    }

    /// Get the discounted founder product
    var founderProduct: Product? {
        product(for: .lifetimeFounder)
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Future: Subscription Migration

    // When adding subscriptions:
    // 1. Add subscription ProductIDs to the enum
    // 2. Update loadProducts() to include subscription products
    // 3. Add subscription-specific entitlement checking in restoreEntitlements()
    // 4. Handle subscription expiration and renewal in handleSuccessfulPurchase()
    // 5. Add `isSubscriptionActive: Bool` published property
    // 6. Update `isPremium` computed property to check both lifetime AND subscription
    //
    // Example subscription ProductIDs:
    // case monthlyPro = "com.pivotallift.pro.monthly"
    // case yearlyPro = "com.pivotallift.pro.yearly"
}
