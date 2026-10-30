import XCTest

final class APGI_ExplorerUITests: XCTestCase {
  private var app: XCUIApplication = .init()

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.app = XCUIApplication()
    self.app.launchArguments = ["--uitesting"]
    self.app.launch()
  }

  override func tearDownWithError() throws {
    self.app.terminate()
  }

  /// Research ships off (`ExplorerBuildApproval.researchApproved == false`); no research entry may appear.
  func testResearchEntryIsAbsentInShippedBuilds() {
    let settingsTab = self.app.buttons["Settings"]
    if settingsTab.exists { settingsTab.tap() }
    XCTAssertFalse(self.app.staticTexts["Research participation"].exists)
    XCTAssertFalse(self.app.buttons["Learn more and take part…"].exists)
  }

  func testAppLaunch() {
    XCTAssertTrue(self.app.exists)
    XCTAssertTrue(self.app.windows.firstMatch.exists)
  }

  func testMainWindowExists() {
    let mainWindow = self.app.windows.firstMatch
    XCTAssertTrue(mainWindow.exists)
    XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
  }

  func testMenuItemsExist() {
    let menuBar = self.app.menuBars.firstMatch
    menuBar.buttons["APGI-Explorer"].tap()

    let menuItems = menuBar.children(matching: .menuItem)
    XCTAssertTrue(menuItems["About APGI-Explorer"].exists)
    XCTAssertTrue(menuItems["Preferences…"].exists)
    XCTAssertTrue(menuItems["Quit APGI-Explorer"].exists)
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

        let firstQuestion = self.app.staticTexts.containing(
          NSPredicate(format: "label CONTAINS 'Question'")
        ).firstMatch
        XCTAssertTrue(firstQuestion.waitForExistence(timeout: 3))

        let answerButtons = self.app.buttons.matching(
          NSPredicate(format: "label CONTAINS 'Answer'"))
        if answerButtons.count > 0 {
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
    for i in 0..<buttons.count {
      let button = buttons.element(boundBy: i)
      XCTAssertTrue(button.isHittable, "Button at index \(i) should be hittable")
    }

    let textFields = window.textFields
    for i in 0..<textFields.count {
      let textField = textFields.element(boundBy: i)
      XCTAssertTrue(textField.isHittable, "Text field at index \(i) should be hittable")
    }
  }

  func testKeyboardNavigation() {
    self.app.typeKey("\t", modifierFlags: [])
    XCTAssertTrue(self.app.windows.firstMatch.exists)

    self.app.typeKey("\t", modifierFlags: [.shift])
    XCTAssertTrue(self.app.windows.firstMatch.exists)
  }

  func testPerformanceOfAppLaunch() {
    measure {
      self.app.terminate()
      self.app.launch()

      let mainWindow = self.app.windows.firstMatch
      XCTAssertTrue(mainWindow.waitForExistence(timeout: 5))
    }
  }

  // MARK: - Window Management Tests

  func testWindowManagement() {
    let mainWindow = self.app.windows.firstMatch
    XCTAssertTrue(mainWindow.exists)

    // Test window resizing
    mainWindow.doubleClick()

    // Test window state persistence
    self.app.terminate()
    self.app.launch()

    let restoredWindow = self.app.windows.firstMatch
    XCTAssertTrue(restoredWindow.exists)
  }

  func testMultipleWindowFlow() {
    // Test opening state explorer window
    let menuBar = self.app.menuBars.firstMatch
    menuBar.buttons["APGI-Explorer"].tap()

    let viewMenu = menuBar.menuItems["View"]
    if viewMenu.exists {
      viewMenu.tap()

      let stateExplorerItem = menuBar.menuItems["Show State Explorer"]
      if stateExplorerItem.exists {
        stateExplorerItem.tap()

        // Verify new window opened
        let windows = self.app.windows.allElementsBoundByIndex
        XCTAssertTrue(windows.count >= 2, "Should have at least 2 windows open")
      }
    }
  }

  func testPanelTransitions() {
    let settingsTab = self.app.buttons["Settings"]
    if settingsTab.exists {
      settingsTab.tap()

      // Test panel transitions
      let panels = ["General", "Appearance", "Charts", "Privacy", "Cloud Sync"]
      for panel in panels {
        let panelButton = self.app.buttons[panel]
        if panelButton.exists {
          panelButton.tap()
          Thread.sleep(forTimeInterval: 0.3)

          let panelTitle = self.app.staticTexts[panel]
          XCTAssertTrue(panelTitle.exists, "Panel \(panel) should be visible")
        }
      }
    }
  }

  // MARK: - Stress Test Scenarios

  func testRapidProfileCreation() {
    let profilesTab = self.app.buttons["Profiles"]
    if profilesTab.exists {
      profilesTab.tap()

      for i in 1...10 {
        let addButton = self.app.buttons["Add Profile"]
        if addButton.exists {
          addButton.tap()

          let nameField = self.app.textFields["Profile Name"]
          if nameField.exists {
            nameField.tap()
            nameField.typeText("Stress Test Profile \(i)")

            let saveButton = self.app.buttons["Save"]
            if saveButton.exists {
              saveButton.tap()
              Thread.sleep(forTimeInterval: 0.2)
            }
          }
        }
      }

      // Verify app is still responsive
      let window = self.app.windows.firstMatch
      XCTAssertTrue(window.exists)
    }
  }

  func testMemoryPressureHandling() {
    // Simulate memory pressure by creating multiple profiles
    let profilesTab = self.app.buttons["Profiles"]
    if profilesTab.exists {
      profilesTab.tap()

      for i in 1...20 {
        let addButton = self.app.buttons["Add Profile"]
        if addButton.exists {
          addButton.tap()

          let nameField = self.app.textFields["Profile Name"]
          if nameField.exists {
            nameField.tap()
            nameField.typeText("Memory Test Profile \(i)")

            let saveButton = self.app.buttons["Save"]
            if saveButton.exists {
              saveButton.tap()
            }
          }
        }
      }

      // Verify no crash occurred
      let window = self.app.windows.firstMatch
      XCTAssertTrue(window.exists)
    }
  }

  // MARK: - Crash Handling Tests

  func testCrashRecovery() {
    // Test that app can recover from simulated crash scenarios
    let mainWindow = self.app.windows.firstMatch
    XCTAssertTrue(mainWindow.exists)

    // Navigate through all tabs to ensure state is preserved
    let tabs = ["Profiles", "Quiz", "Results", "Settings"]
    for tab in tabs {
      let tabButton = self.app.buttons[tab]
      if tabButton.exists {
        tabButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
      }
    }

    // Terminate and relaunch to test recovery
    self.app.terminate()
    self.app.launch()

    let restoredWindow = self.app.windows.firstMatch
    XCTAssertTrue(restoredWindow.exists)
  }

  // MARK: - Export/Import Stress Tests

  func testMultipleExportOperations() {
    let resultsTab = self.app.buttons["Results"]
    if resultsTab.exists {
      resultsTab.tap()

      let exportButton = self.app.buttons["Export"]
      if exportButton.exists {
        for _ in 1...5 {
          exportButton.tap()

          let exportSheet = self.app.sheets.firstMatch
          if exportSheet.waitForExistence(timeout: 2) {
            let cancelButton = exportSheet.buttons["Cancel"]
            if cancelButton.exists {
              cancelButton.tap()
            }
          }
          Thread.sleep(forTimeInterval: 0.3)
        }
      }
    }

    // Verify app is still responsive
    let window = self.app.windows.firstMatch
    XCTAssertTrue(window.exists)
  }
}
