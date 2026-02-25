@testable import APGI_Explorer
import StoreKit
import XCTest

final class StoreKitTests: XCTestCase {
    var storeManager: StoreManager?

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.storeManager = StoreManager.shared
    }

    override func tearDownWithError() throws {
        self.storeManager = nil
    }

    func testStoreManagerInitialization() throws {
        XCTAssertNotNil(try XCTUnwrap(self.storeManager))
        XCTAssertTrue(try XCTUnwrap(self.storeManager?.products.isEmpty))
        XCTAssertTrue(try XCTUnwrap(self.storeManager?.purchasedProductIDs.isEmpty))
        XCTAssertFalse(try XCTUnwrap(self.storeManager?.isLoading))
        XCTAssertNil(self.storeManager?.errorMessage)
    }

    func testProductIDDefinitions() {
        let productIDs: [StoreManager.ProductID] = [
            .premiumMonthly,
            .premiumYearly,
            .professionalFeatures,
            .researchPack,
            .unlimitedProfiles,
        ]

        for productID in productIDs {
            XCTAssertFalse(productID.displayName.isEmpty)
            XCTAssertFalse(productID.description.isEmpty)

            if productID.isSubscription {
                XCTAssertTrue([.premiumMonthly, .premiumYearly].contains(productID))
            }
            else {
                XCTAssertTrue([.professionalFeatures, .researchPack, .unlimitedProfiles].contains(productID))
            }
        }
    }

    func testProductIDRawValues() {
        XCTAssertEqual(StoreManager.ProductID.premiumMonthly.rawValue, "com.lesoto.APGI-Explorer.premium.monthly")
        XCTAssertEqual(StoreManager.ProductID.premiumYearly.rawValue, "com.lesoto.APGI-Explorer.premium.yearly")
        XCTAssertEqual(StoreManager.ProductID.professionalFeatures.rawValue, "com.lesoto.APGI-Explorer.professional")
        XCTAssertEqual(StoreManager.ProductID.researchPack.rawValue, "com.lesoto.APGI-Explorer.research.pack")
        XCTAssertEqual(StoreManager.ProductID.unlimitedProfiles.rawValue, "com.lesoto.APGI-Explorer.unlimited.profiles")
    }

    func testFeatureAccessFlags() throws {
        // Test initial state
        XCTAssertFalse(try XCTUnwrap(self.storeManager?.hasPremiumFeatures))
        XCTAssertFalse(try XCTUnwrap(self.storeManager?.hasProfessionalFeatures))
        XCTAssertFalse(try XCTUnwrap(self.storeManager?.hasResearchFeatures))
        XCTAssertFalse(try XCTUnwrap(self.storeManager?.hasUnlimitedProfiles))
    }

    func testStoreErrorDescriptions() {
        let errors: [StoreError] = [
            .paymentPending,
            .verificationFailed,
            .productNotFound,
            .purchaseFailed,
            .unknown,
        ]

        for error in errors {
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testProductLoading() async throws {
        let expectation = XCTestExpectation(description: "Product loading completes")

        Task {
            await self.storeManager?.loadProducts()

            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 10.0)

        // Verify loading state is reset
        XCTAssertFalse(try XCTUnwrap(self.storeManager?.isLoading))

        // Note: In test environment, products might be empty
        // The important thing is that the method completes without crashing
    }

    func testPurchaseRestoration() async throws {
        let expectation = XCTestExpectation(description: "Purchase restoration completes")

        Task {
            await self.storeManager?.restorePurchases()

            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 10.0)

        // Verify loading state is reset
        XCTAssertFalse(try XCTUnwrap(self.storeManager?.isLoading))

        // The important thing is that the method completes without crashing
    }
}
