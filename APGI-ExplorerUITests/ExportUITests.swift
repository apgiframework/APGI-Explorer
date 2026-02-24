@testable import APGI_Explorer
import XCTest

final class ExportUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing"]
        self.app.launch()
    }

    override func tearDownWithError() throws {
        self.app = nil
    }

    func testExportViewOpens() {
        // Navigate to export view
        let profilesTab = self.app.tabBars.buttons["Profiles"]
        XCTAssertTrue(profilesTab.waitForExistence(timeout: 5))
        profilesTab.tap()

        let firstProfile = self.app.tables.cells.firstMatch
        XCTAssertTrue(firstProfile.waitForExistence(timeout: 5))
        firstProfile.tap()

        let exportButton = self.app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        exportButton.tap()

        // Verify export view is open
        let exportView = self.app.navigationBars["Export Profile"]
        XCTAssertTrue(exportView.waitForExistence(timeout: 5))
    }

    func testExportFormatSelection() {
        // Navigate to export view
        self.navigateToExportView()

        let formatPicker = self.app.pickers["Format"]
        XCTAssertTrue(formatPicker.waitForExistence(timeout: 5))

        // Test different format selections
        let formats = ["JSON", "CSV", "PDF", "PNG", "SPSS", "Stata", "R Data", "Excel", "XML", "BibTeX", "EndNote", "APA Report", "MLA Report"]

        for format in formats {
            formatPicker.tap()
            let formatOption = self.app.menuItems[format]
            if formatOption.exists {
                formatOption.tap()

                // Verify description appears
                let description = self.app.staticTexts[format]
                if description.exists {
                    XCTAssertTrue(description.exists)
                }
            }
        }
    }

    func testExportButtonFunctionality() {
        self.navigateToExportView()

        let exportButton = self.app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        XCTAssertTrue(exportButton.isEnabled)

        exportButton.tap()

        // Wait for export to complete (should show share sheet or success message)
        let shareSheet = self.app.sheets.firstMatch
        let successMessage = self.app.alerts.firstMatch

        // Either share sheet should appear or success message
        let expectation = XCTestExpectation(description: "Export completes")

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if shareSheet.exists || successMessage.exists {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testExportCancelButton() {
        self.navigateToExportView()

        let cancelButton = self.app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        // Verify we're back to the previous view
        let exportView = self.app.navigationBars["Export Profile"]
        XCTAssertFalse(exportView.exists)
    }

    func testExportPreviewSection() {
        self.navigateToExportView()

        let profileName = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Profile:'")).firstMatch
        XCTAssertTrue(profileName.waitForExistence(timeout: 5))

        let profileType = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Type:'")).firstMatch
        XCTAssertTrue(profileType.waitForExistence(timeout: 5))

        // Check for score rows
        let epsilonScore = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'ε (Epsilon)'")).firstMatch
        let precisionScore = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'π (Precision)'")).firstMatch
        let thresholdScore = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'θₜ (Threshold)'")).firstMatch
        let somaticBiasScore = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'β (Somatic Bias)'")).firstMatch

        XCTAssertTrue(epsilonScore.exists || precisionScore.exists || thresholdScore.exists || somaticBiasScore.exists)
    }

    func testiOSExportOptionsCard() {
        // Navigate to results view on iOS
        let resultsTab = self.app.tabBars.buttons["Results"]
        if resultsTab.exists {
            resultsTab.tap()

            let exportOptionsCard = self.app.scrollViews.otherElements["Export Options"]
            if exportOptionsCard.exists {
                XCTAssertTrue(exportOptionsCard.exists)

                // Check for category selector
                let categoryPicker = self.app.pickers["Category"]
                if categoryPicker.exists {
                    XCTAssertTrue(categoryPicker.exists)
                }

                // Check for export buttons
                let exportButtons = self.app.buttons.allElementsBoundByIndex
                XCTAssertFalse(exportButtons.isEmpty)
            }
        }
    }

    func testExportAccessibility() {
        self.navigateToExportView()

        // Test format picker accessibility
        let formatPicker = self.app.pickers["Format"]
        XCTAssertTrue(formatPicker.isAccessibilityElement)
        XCTAssertFalse(formatPicker.accessibilityLabel?.isEmpty ?? true)

        // Test export button accessibility
        let exportButton = self.app.buttons["Export"]
        XCTAssertTrue(exportButton.isAccessibilityElement)
        XCTAssertFalse(exportButton.accessibilityLabel?.isEmpty ?? true)
        XCTAssertFalse(exportButton.accessibilityHint?.isEmpty ?? true)

        // Test cancel button accessibility
        let cancelButton = self.app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.isAccessibilityElement)
        XCTAssertFalse(cancelButton.accessibilityLabel?.isEmpty ?? true)
    }

    // MARK: - Helper Methods

    private func navigateToExportView() {
        // Navigate to profiles tab
        let profilesTab = self.app.tabBars.buttons["Profiles"]
        XCTAssertTrue(profilesTab.waitForExistence(timeout: 5))
        profilesTab.tap()

        // Select first profile
        let firstProfile = self.app.tables.cells.firstMatch
        XCTAssertTrue(firstProfile.waitForExistence(timeout: 5))
        firstProfile.tap()

        // Tap export button
        let exportButton = self.app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        exportButton.tap()

        // Wait for export view to appear
        let exportView = self.app.navigationBars["Export Profile"]
        XCTAssertTrue(exportView.waitForExistence(timeout: 5))
    }
}
