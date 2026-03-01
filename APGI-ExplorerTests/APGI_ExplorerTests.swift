@testable import APGI_Explorer
import XCTest

final class APGI_ExplorerTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testAPGIScorerCalculateScore() {
        let scorer = APGIScorer()
        let sampleAnswers: [Int: Int] = [
            1: 3, 2: 4, 3: 2, 4: 3, 5: 4, // epsilon
            6: 2, 7: 3, 8: 4, 9: 2, 10: 3, // precision
            11: 4, 12: 3, 13: 2, 14: 4, 15: 3, // threshold
            16: 3, 17: 4, 18: 2, 19: 3, 20: 4, // somatic
            21: 3, 22: 2, 23: 4, 24: 3, 25: 2, // interactions
            26: 4, 27: 3, 28: 2, 29: 4, 30: 3, // temporal
            31: 2, 32: 4, 33: 3, 34: 2, 35: 4, // environmental
        ]

        let profile = scorer.calculateRobustScore(answers: sampleAnswers)

        XCTAssertNotNil(profile)
        XCTAssertGreaterThanOrEqual(profile.epsilon, 0)
        XCTAssertLessThanOrEqual(profile.epsilon, 100)
        XCTAssertGreaterThanOrEqual(profile.precision, 0)
        XCTAssertLessThanOrEqual(profile.precision, 100)
        XCTAssertGreaterThanOrEqual(profile.threshold, 0)
        XCTAssertLessThanOrEqual(profile.threshold, 100)
        XCTAssertGreaterThanOrEqual(profile.somaticBias, 0)
        XCTAssertLessThanOrEqual(profile.somaticBias, 100)
        XCTAssertGreaterThanOrEqual(profile.interactionScore, 0)
        XCTAssertLessThanOrEqual(profile.interactionScore, 100)
        XCTAssertGreaterThanOrEqual(profile.temporalStability, 0)
        XCTAssertLessThanOrEqual(profile.temporalStability, 100)
        XCTAssertGreaterThanOrEqual(profile.environmentalFit, 0)
        XCTAssertLessThanOrEqual(profile.environmentalFit, 100)
    }

    func testProfileCreation() {
        let profile = ProfileEntity(context: PersistenceController.preview.container.viewContext)
        profile.id = UUID()
        profile.name = "Test Profile"
        profile.dateCreated = Date()

        XCTAssertEqual(profile.name, "Test Profile")
        XCTAssertNotNil(profile.id)
        XCTAssertNotNil(profile.dateCreated)
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
