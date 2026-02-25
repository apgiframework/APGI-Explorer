@testable import APGI_Explorer
import XCTest

final class LocalizationTests: XCTestCase {
    var localizationManager: LocalizationManager?

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.localizationManager = LocalizationManager.shared
    }

    override func tearDownWithError() throws {
        self.localizationManager = nil
    }

    func testLocalizationManagerInitialization() throws {
        XCTAssertNotNil(try XCTUnwrap(self.localizationManager))
        XCTAssertEqual(self.localizationManager?.currentLanguage, .english)
    }

    func testSupportedLanguages() {
        let languages: [LocalizationManager.SupportedLanguage] = [
            .english, .spanish, .french, .german, .russian,
        ]

        for language in languages {
            XCTAssertFalse(language.displayName.isEmpty)
            XCTAssertFalse(language.nativeName.isEmpty)
            XCTAssertFalse(language.localeIdentifier.isEmpty)
        }
    }

    func testLanguageProperties() {
        // Test English
        XCTAssertEqual(LocalizationManager.SupportedLanguage.english.rawValue, "en")
        XCTAssertEqual(LocalizationManager.SupportedLanguage.english.localeIdentifier, "en_US")

        // Test Spanish
        XCTAssertEqual(LocalizationManager.SupportedLanguage.spanish.rawValue, "es")
        XCTAssertEqual(LocalizationManager.SupportedLanguage.spanish.localeIdentifier, "es_ES")

        // Test French
        XCTAssertEqual(LocalizationManager.SupportedLanguage.french.rawValue, "fr")
        XCTAssertEqual(LocalizationManager.SupportedLanguage.french.localeIdentifier, "fr_FR")

        // Test German
        XCTAssertEqual(LocalizationManager.SupportedLanguage.german.rawValue, "de")
        XCTAssertEqual(LocalizationManager.SupportedLanguage.german.localeIdentifier, "de_DE")

        // Test Chinese Simplified
        XCTAssertEqual(LocalizationManager.SupportedLanguage.russian.rawValue, "zh-Hans")
        XCTAssertEqual(LocalizationManager.SupportedLanguage.russian.localeIdentifier, "zh_Hans_CN")
    }

    func testLanguageSwitching() throws {
        let originalLanguage = try XCTUnwrap(self.localizationManager?.currentLanguage)

        // Switch to Spanish
        self.localizationManager?.setLanguage(.spanish)
        XCTAssertEqual(self.localizationManager?.currentLanguage, .spanish)

        // Switch to French
        self.localizationManager?.setLanguage(.french)
        XCTAssertEqual(self.localizationManager?.currentLanguage, .french)

        // Restore original
        self.localizationManager?.setLanguage(originalLanguage)
        XCTAssertEqual(self.localizationManager?.currentLanguage, originalLanguage)
    }

    func testLocalizedStringFallback() throws {
        let testKey = "nonexistent_key_12345"
        let localizedString = try XCTUnwrap(self.localizationManager?.localizedString(for: testKey))

        // Should return the key if not found in localization
        XCTAssertEqual(localizedString, testKey)
    }

    func testLocalizedStringWithArguments() throws {
        let testKey = "test_key_with_arg"
        let testArg = "argument"
        let localizedString = try XCTUnwrap(self.localizationManager?.localizedString(for: testKey, arguments: testArg))

        // Should return the key if not found in localization
        XCTAssertTrue(localizedString.contains(testKey))
    }

    func testStringExtensionLocalized() {
        let testKey = "test_string"
        let localizedString = testKey.localized

        XCTAssertEqual(localizedString, testKey)
    }

    func testTextExtensionLocalized() {
        let testKey = "test_text"
        let text = Text(localized: testKey)

        // Just verify it doesn't crash
        XCTAssertNotNil(text)
    }

    func testLocalizationUtils() {
        let testDate = Date()
        let relativeTime = LocalizationUtils.formatRelativeTime(from: testDate)
        XCTAssertNotNil(relativeTime)
        XCTAssertFalse(relativeTime.isEmpty)

        let formattedDate = LocalizationUtils.formatDate(testDate)
        XCTAssertNotNil(formattedDate)
        XCTAssertFalse(formattedDate.isEmpty)

        let testNumber = 1234.56
        let formattedNumber = LocalizationUtils.formatNumber(testNumber)
        XCTAssertNotNil(formattedNumber)
        XCTAssertFalse(formattedNumber.isEmpty)

        let testPercentage = 75.5
        let formattedPercentage = LocalizationUtils.formatPercentage(testPercentage)
        XCTAssertNotNil(formattedPercentage)
        XCTAssertFalse(formattedPercentage.isEmpty)
    }
}
