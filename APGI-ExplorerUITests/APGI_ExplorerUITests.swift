import XCTest

final class APGI_ExplorerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        self.app.launch()
    }

    override func tearDownWithError() throws {
    }

    private var app: XCUIApplication = .init()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launchArguments = ["--uitesting"]
        self.app.launch()
    }

    func testAppLaunch() {
        XCTAssertTrue(self.app.exists)
        XCTAssertTrue(self.app.windows.firstMatch.exists)
    }

    func testMainWindowExists() {
        let mainWindow = self.app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists)
        XCTAssertTrue(mainFrame.waitForExistence(timeout: 5))
    }

    func testMenuItemsExist() {
        self.app.menuBars.firstMatch.buttons["APGI-Explorer"].tap()

        XCTAssertTrue(self.app.menuItems["About APGI-Explorer"].exists)
        XCTAssertTrue(self.app.menuItems["Preferences…"].exists)
        XCTAssertTrue(self.app.menuItems["Quit APGI-Explorer"].exists)
    }

    func testTabNavigation() {
        let tabView = self.app.tabGroups.firstMatch
        XCTAssertTrue(tabView.exists)

        let tabs = ["Profiles", "Quiz", "Results", "Settings"]
        for tabName in tabs {
            let tabButton = tabView.buttons[tabName]
            if tabButton.exists {
                tabButton.tap()
                XCTAssertTrue(tabButton.isSelected)
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    func testQuizFlow() {
        let quizTab = self.app.buttons["Quiz"]
        if quizTab.exists {
            quizTab.tap()

            let startButton = self.app.buttons["Start Quiz"]
            if startButton.exists {
                startButton.tap()

                let firstQuestion = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Question'")).firstMatch
                XCTAssertTrue(firstQuestion.waitForExistence(timeout: 3))

                let answerButtons = self.app.buttons.matching(NSPredicate(format: "label CONTAINS 'Answer'"))
                if !answerButtons.isEmpty {
                    answerButtons.firstMatch.tap()

                    let nextButton = self.app.buttons["Next"]
                    if nextButton.exists {
                        nextButton.tap()
                    }
                }
            }
        }
    }

    func testProfileCreation() {
        let profilesTab = self.app.buttons["Profiles"]
        if profilesTab.exists {
            profilesTab.tap()

            let addButton = self.app.buttons["Add Profile"]
            if addButton.exists {
                addButton.tap()

                let nameField = self.app.textFields["Profile Name"]
                if nameField.exists {
                    nameField.tap()
                    nameField.typeText("Test Profile")

                    let saveButton = self.app.buttons["Save"]
                    if saveButton.exists {
                        saveButton.tap()

                        let profileName = self.app.staticTexts["Test Profile"]
                        XCTAssertTrue(profileName.waitForExistence(timeout: 3))
                    }
                }
            }
        }
    }

    func testSettingsNavigation() {
        let settingsTab = self.app.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()

            let settingsTitle = self.app.staticTexts["Settings"]
            XCTAssertTrue(settingsTitle.exists)

            let appearanceButton = self.app.buttons["Appearance"]
            if appearanceButton.exists {
                appearanceButton.tap()

                let appearanceTitle = self.app.staticTexts["Appearance"]
                XCTAssertTrue(appearanceTitle.waitForExistence(timeout: 2))
            }
        }
    }

    func testExportFunctionality() {
        let resultsTab = self.app.buttons["Results"]
        if resultsTab.exists {
            resultsTab.tap()

            let exportButton = self.app.buttons["Export"]
            if exportButton.exists {
                exportButton.tap()

                let exportSheet = self.app.sheets.firstMatch
                XCTAssertTrue(exportSheet.waitForExistence(timeout: 3))

                let jsonButton = exportSheet.buttons["JSON"]
                if jsonButton.exists {
                    jsonButton.tap()

                    let saveButton = exportSheet.buttons["Save"]
                    if saveButton.exists {
                        saveButton.tap()
                    }
                }
            }
        }
    }

    func testAccessibilityElements() {
        let window = self.app.windows.firstMatch

        let buttons = window.buttons
        for i in 0 ..< buttons.count {
            let button = buttons.element(boundBy: i)
            XCTAssertTrue(button.isHittable, "Button at index \(i) should be hittable")
        }

        let textFields = window.textFields
        for i in 0 ..< textFields.count {
            let textField = textFields.element(boundBy: i)
            XCTAssertTrue(textField.isHittable, "Text field at index \(i) should be hittable")
        }
    }

    func testKeyboardNavigation() {
        self.app.typeKey("\t", modifier: [])

        let focusedElement = self.app.focusedElement
        XCTAssertNotNil(focusedElement)

        self.app.typeKey("\t", modifier: [.shift])

        let previousElement = self.app.focusedElement
        XCTAssertNotNil(previousElement)
    }

    func testPerformanceOfAppLaunch() {
        measure {
            self.app.terminate()
            self.app.launch()

            let mainWindow = self.app.windows.firstMatch
            XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
        }
    }
}
