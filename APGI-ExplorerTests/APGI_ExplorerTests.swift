@testable import APGI_Explorer
import XCTest

final class APGI_ExplorerTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testAPGIScorerInitialization() {
        let scorer = APGIScorer()
        XCTAssertNotNil(scorer)
        XCTAssertEqual(scorer.currentProfile, nil)
    }

    func testProfileCreation() {
        let profile = ProfileEntity(context: PersistenceController.preview.container.viewContext)
        profile.id = UUID()
        profile.name = "Test Profile"
        profile.createdAt = Date()

        XCTAssertEqual(profile.name, "Test Profile")
        XCTAssertNotNil(profile.id)
        XCTAssertNotNil(profile.createdAt)
    }

    func testQuizModelInitialization() {
        let quizModel = QuizModel()
        XCTAssertNotNil(quizModel)
        XCTAssertEqual(quizModel.currentQuestionIndex, 0)
        XCTAssertTrue(quizModel.answers.isEmpty)
    }

    func testSecurityManagerKeychainOperations() throws {
        let securityManager = SecurityManager.shared
        let testData = "test_data_123"
        let testKey = "test_key"

        try securityManager.storeSessionToken(testData)
        let retrievedToken = try securityManager.retrieveSessionToken()
        XCTAssertEqual(retrievedToken, testData)

        try securityManager.clearAllSecureData()
        let clearedToken = try? securityManager.retrieveSessionToken()
        XCTAssertNil(clearedToken)
    }

    func testKeychainManagerDataIntegrity() throws {
        let keychain = KeychainManager.shared
        let testKey = "integrity_test"
        let testData = Data("integrity_test_data".utf8)

        try keychain.store(testData, forKey: testKey)
        let retrievedData = try keychain.retrieve(forKey: testKey)
        XCTAssertEqual(retrievedData, testData)

        try keychain.delete(forKey: testKey)
        XCTAssertFalse(keychain.contains(forKey: testKey))
    }

    func testPerformanceOfProfileCalculation() {
        let scorer = APGIScorer()
        measure {
            for _ in 0 ..< 100 {
                _ = scorer.calculateScore(for: [:])
            }
        }
    }

    func testAppStateTransitions() {
        let appState = AppState()
        XCTAssertNotNil(appState)
    }

    func testUserDefaultsManager() {
        let userDefaults = UserDefaultsManager.shared
        let testKey = "test_preference"
        let testValue = "test_value"

        userDefaults.set(testValue, forKey: testKey)
        let retrievedValue = userDefaults.string(forKey: testKey)
        XCTAssertEqual(retrievedValue, testValue)

        userDefaults.removeObject(forKey: testKey)
        let removedValue = userDefaults.string(forKey: testKey)
        XCTAssertNil(removedValue)
    }
}
