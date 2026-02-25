import Combine
import Foundation
import StoreKit
import SwiftUI

class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        self.updateListenerTask = self.listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Definitions

    enum ProductID: String, CaseIterable {
        case premiumMonthly = "com.lesoto.APGI-Explorer.premium.monthly"
        case premiumYearly = "com.lesoto.APGI-Explorer.premium.yearly"
        case professionalFeatures = "com.lesoto.APGI-Explorer.professional"
        case researchPack = "com.lesoto.APGI-Explorer.research.pack"
        case unlimitedProfiles = "com.lesoto.APGI-Explorer.unlimited.profiles"

        var displayName: String {
            switch self {
            case .premiumMonthly:
                NSLocalizedString("Premium Monthly", comment: "Product name")
            case .premiumYearly:
                NSLocalizedString("Premium Yearly", comment: "Product name")
            case .professionalFeatures:
                NSLocalizedString("Professional Features", comment: "Product name")
            case .researchPack:
                NSLocalizedString("Research Pack", comment: "Product name")
            case .unlimitedProfiles:
                NSLocalizedString("Unlimited Profiles", comment: "Product name")
            }
        }

        var description: String {
            switch self {
            case .premiumMonthly:
                NSLocalizedString("Unlock all premium features with monthly subscription", comment: "Product description")
            case .premiumYearly:
                NSLocalizedString("Unlock all premium features with yearly subscription (Save 20%)", comment: "Product description")
            case .professionalFeatures:
                NSLocalizedString("Professional assessment tools and advanced analytics", comment: "Product description")
            case .researchPack:
                NSLocalizedString("Advanced research export formats and statistical analysis tools", comment: "Product description")
            case .unlimitedProfiles:
                NSLocalizedString("Create unlimited psychological profiles", comment: "Product description")
            }
        }

        var isSubscription: Bool {
            switch self {
            case .premiumMonthly, .premiumYearly:
                true
            case .professionalFeatures, .researchPack, .unlimitedProfiles:
                false
            }
        }
    }

    // MARK: - Store Operations

    func loadProducts() async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: ProductID.allCases.map(\.rawValue))

            DispatchQueue.main.async {
                self.products = storeProducts.sorted { (product1: Product, product2: Product) -> Bool in
                    if product1.type == .autoRenewable, product2.type != .autoRenewable {
                        return true
                    } else if product1.type != .autoRenewable, product2.type == .autoRenewable {
                        return false
                    } else {
                        return product1.displayPrice < product2.displayPrice
                    }
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        self.isLoading = true
        self.errorMessage = nil

        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                let transaction = try checkVerified(verification)

                await deliverProduct(transaction)
                await finishTransaction(transaction)

                DispatchQueue.main.async {
                    self.purchasedProductIDs.insert(transaction.productID)
                }

                return transaction

            case .userCancelled:
                return nil

            case .pending:
                throw StoreError.paymentPending

            @unknown default:
                throw StoreError.unknown
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    func restorePurchases() async {
        self.isLoading = true
        self.errorMessage = nil

        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        do {
            try await AppStore.sync()
            await self.updatePurchasedProducts()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Transaction Management

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run { try self.checkVerified(result) }

                    await self.deliverProduct(transaction)
                    await self.finishTransaction(transaction)

                    _ = await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case let .verified(safe):
            return safe
        }
    }

    private func deliverProduct(_ transaction: StoreKit.Transaction) async {
        guard let productID = ProductID(rawValue: transaction.productID) else { return }

        switch productID {
        case .premiumMonthly, .premiumYearly:
            await self.enablePremiumFeatures()
        case .professionalFeatures:
            await self.enableProfessionalFeatures()
        case .researchPack:
            await self.enableResearchFeatures()
        case .unlimitedProfiles:
            await self.enableUnlimitedProfiles()
        }
    }

    private func finishTransaction(_ transaction: StoreKit.Transaction) async {
        await transaction.finish()
    }

    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try await MainActor.run { try self.checkVerified(result) }
                purchasedIDs.insert(transaction.productID)
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        DispatchQueue.main.async {
            self.purchasedProductIDs = purchasedIDs
        }
    }

    // MARK: - Feature Enablement

    private func enablePremiumFeatures() async {
        UserDefaults.standard.set(true, forKey: "premium_features_enabled")
        UserDefaults.standard.synchronize()
    }

    private func enableProfessionalFeatures() async {
        UserDefaults.standard.set(true, forKey: "professional_features_enabled")
        UserDefaults.standard.synchronize()
    }

    private func enableResearchFeatures() async {
        UserDefaults.standard.set(true, forKey: "research_features_enabled")
        UserDefaults.standard.synchronize()
    }

    private func enableUnlimitedProfiles() async {
        UserDefaults.standard.set(true, forKey: "unlimited_profiles_enabled")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Feature Access

    var hasPremiumFeatures: Bool {
        self.purchasedProductIDs.contains(ProductID.premiumMonthly.rawValue) ||
            self.purchasedProductIDs.contains(ProductID.premiumYearly.rawValue)
    }

    var hasProfessionalFeatures: Bool {
        self.purchasedProductIDs.contains(ProductID.professionalFeatures.rawValue) ||
            self.hasPremiumFeatures
    }

    var hasResearchFeatures: Bool {
        self.purchasedProductIDs.contains(ProductID.researchPack.rawValue) ||
            self.hasPremiumFeatures
    }

    var hasUnlimitedProfiles: Bool {
        self.purchasedProductIDs.contains(ProductID.unlimitedProfiles.rawValue) ||
            self.hasPremiumFeatures
    }

    // MARK: - Subscription Management

    func getSubscriptionStatus(for productID: String) async -> Product.SubscriptionInfo.Status? {
        guard let product = products.first(where: { $0.id == productID }),
              product.type == .autoRenewable
        else {
            return nil
        }

        guard let subscription = product.subscription else { return nil }

        do {
            let statuses = try await subscription.status
            return statuses.first
        } catch {
            print("Failed to get subscription status: \(error)")
            return nil
        }
    }

    func isSubscriptionActive(for productID: String) async -> Bool {
        guard self.purchasedProductIDs.contains(productID) else { return false }

        guard let subscriptionStatus = await getSubscriptionStatus(for: productID) else { return false }

        switch subscriptionStatus.state {
        case .expired:
            return false
        case .inBillingRetryPeriod:
            return false
        case .inGracePeriod:
            return true
        case .revoked:
            return false
        case .subscribed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case paymentPending
    case verificationFailed
    case productNotFound
    case purchaseFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .paymentPending:
            NSLocalizedString("Payment is pending approval", comment: "Store error")
        case .verificationFailed:
            NSLocalizedString("Transaction verification failed", comment: "Store error")
        case .productNotFound:
            NSLocalizedString("Product not found", comment: "Store error")
        case .purchaseFailed:
            NSLocalizedString("Purchase failed", comment: "Store error")
        case .unknown:
            NSLocalizedString("An unknown error occurred", comment: "Store error")
        }
    }
}

enum ProfileError: Error {
    case invalidData
}

// MARK: - Store Settings View

struct StoreSettingsView: View {
    @StateObject private var storeManager = StoreManager.shared
    @State private var showingPurchaseError = false

    var body: some View {
        NavigationView {
            List {
                ProductsSection(storeManager: self.storeManager)

                Section {
                    Button("Restore Purchases") {
                        Task {
                            await self.storeManager.restorePurchases()
                        }
                    }
                    .disabled(self.storeManager.isLoading)

                    Button("Refresh Products") {
                        Task {
                            await self.storeManager.loadProducts()
                        }
                    }
                    .disabled(self.storeManager.isLoading)
                }

                PurchasedProductsSection(purchasedProductIDs: self.storeManager.purchasedProductIDs, products: self.storeManager.products)
            }
            .navigationTitle("Store")
            .task {
                await self.storeManager.loadProducts()
                await self.storeManager.updatePurchasedProducts()
            }
            .alert("Purchase Error", isPresented: self.$showingPurchaseError) {
                Button("OK") {
                }
            } message: {
                if let errorMessage = storeManager.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: self.storeManager.errorMessage) { _, newValue in
                self.showingPurchaseError = newValue != nil
            }
        }
    }
}

// MARK: - Product Row

struct ProductRow: View {
    let product: Product
    let storeManager: StoreManager

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(self.product.displayName)
                    .font(.headline)
                Text(self.product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if self.product.type == .autoRenewable {
                    Text(self.product.subscription?.subscriptionPeriod.value ?? 0, format: .number)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(self.product.displayPrice)
                    .font(.title3)
                    .fontWeight(.semibold)

                if self.storeManager.purchasedProductIDs.contains(self.product.id) {
                    Text("Purchased")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        Task {
                            try? await self.storeManager.purchase(self.product)
                        }
                    }) {
                        Text("Purchase")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Products Section

struct ProductsSection: View {
    @ObservedObject var storeManager: StoreManager

    var body: some View {
        Section {
            if self.storeManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading products...")
                        .foregroundColor(.secondary)
                }
            } else if self.storeManager.products.isEmpty {
                Text("No products available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(self.storeManager.products, id: \.id) { product in
                    ProductRow(product: product, storeManager: self.storeManager)
                }
            }
        } header: {
            Text("Premium Features")
        }
    }
}

// MARK: - Purchased Products Section

struct PurchasedProductsSection: View {
    let purchasedProductIDs: Set<String>
    let products: [Product]

    var body: some View {
        if !self.purchasedProductIDs.isEmpty {
            Section("Purchased Items") {
                ForEach(Array(self.purchasedProductIDs), id: \.self) { productID in
                    if let product = products.first(where: { $0.id == productID }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.displayName)
                                    .font(.headline)
                                Text(product.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}
