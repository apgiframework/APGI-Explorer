import Combine
import Foundation
import OSLog
import StoreKit
import SwiftUI

class StoreManager: ObservableObject {
  static let shared = StoreManager()

  @Published var products: [Product] = []
  @Published var purchasedProductIDs: Set<String> = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private init() {}

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
        NSLocalizedString(
          "Unlock all premium features with monthly subscription", comment: "Product description")
      case .premiumYearly:
        NSLocalizedString(
          "Unlock all premium features with yearly subscription (Save 20%)",
          comment: "Product description")
      case .professionalFeatures:
        NSLocalizedString(
          "Professional assessment tools and advanced analytics", comment: "Product description")
      case .researchPack:
        NSLocalizedString(
          "Advanced research export formats and statistical analysis tools",
          comment: "Product description")
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
    self.products = []
    self.isLoading = false
  }

  func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
    throw StoreError.productsDisabled
  }

  func restorePurchases() async {
    // Keep existing purchases untouched in the store; no entitlement enables this release.
    isLoading = false
    errorMessage = nil
  }

  func updatePurchasedProducts() async { purchasedProductIDs = [] }

  var hasPremiumFeatures: Bool { false }
  var hasProfessionalFeatures: Bool { false }
  var hasResearchFeatures: Bool { false }
  var hasUnlimitedProfiles: Bool { false }

  func getSubscriptionStatus(for productID: String) async -> Product.SubscriptionInfo.Status? { nil }
  func isSubscriptionActive(for productID: String) async -> Bool { false }

}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
  case productsDisabled
  case paymentPending
  case verificationFailed
  case productNotFound
  case purchaseFailed
  case unknown

  var errorDescription: String? {
    switch self {
    case .productsDisabled:
      "Paid products are unavailable pending validation."
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
  @ObservedObject private var storeManager = StoreManager.shared
  @State private var showingPurchaseError = false

  var body: some View {
    NavigationView {
      List {
        Text("Paid products are unavailable pending validation.")
          .foregroundStyle(.secondary)
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

        PurchasedProductsSection(
          purchasedProductIDs: self.storeManager.purchasedProductIDs,
          products: self.storeManager.products)
      }
      .navigationTitle("Store")
      .task {
        await self.storeManager.loadProducts()
        await self.storeManager.updatePurchasedProducts()
      }
      .alert(
        "Purchase Error", isPresented: self.$showingPurchaseError,
        actions: {
          Button("OK") {
          }
        },
        message: {
          if let errorMessage = storeManager.errorMessage {
            Text(errorMessage)
          }
        }
      )
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
          }, label: {
            Text("Purchase")
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 4)
              .background(Color.blue)
              .foregroundColor(.white)
              .cornerRadius(4)
          })
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
