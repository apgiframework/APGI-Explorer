import XCTest

@testable import APGI_Explorer

@MainActor
final class ContextualHelpManagerTests: XCTestCase {
  // swiftlint:disable:next implicitly_unwrapped_optional
  private var helpManager: ContextualHelpManager!

  override func setUpWithError() throws {
    continueAfterFailure = false
    self.helpManager = ContextualHelpManager.shared
    // Reset completed tutorials for clean test state
    UserDefaults.standard.removeObject(forKey: "completedTutorials")
    self.helpManager.resetCompletedTutorials()
  }

  override func tearDownWithError() throws {
    // Clean up UserDefaults
    UserDefaults.standard.removeObject(forKey: "completedTutorials")
    self.helpManager = nil
  }

  func testContextualHelpManagerInitialization() throws {
    let manager = try XCTUnwrap(self.helpManager)
    XCTAssertNotNil(manager)
    XCTAssertFalse(manager.isHelpVisible)
    XCTAssertNil(manager.currentHelpContext)
    XCTAssertFalse(manager.availableTutorials.isEmpty)  // Has default tutorials
  }

  func testShowAndDismissHelp() throws {
    let manager = try XCTUnwrap(self.helpManager)
    let context = HelpContext.profileCreation
    manager.showHelp(for: context)
    XCTAssertTrue(manager.isHelpVisible)
    XCTAssertEqual(manager.currentHelpContext, context)

    manager.dismissHelp()
    XCTAssertFalse(manager.isHelpVisible)
    XCTAssertNil(manager.currentHelpContext)
  }

  func testMarkTutorialCompleted() throws {
    let manager = try XCTUnwrap(self.helpManager)
    let tutorialId = "test_tutorial"
    XCTAssertFalse(manager.isTutorialCompleted(tutorialId))

    manager.markTutorialCompleted(tutorialId)
    XCTAssertTrue(manager.isTutorialCompleted(tutorialId))
  }

  func testGetTutorialForContext() throws {
    let manager = try XCTUnwrap(self.helpManager)
    let context = HelpContext.profileCreation
    let tutorial = manager.getTutorial(for: context)
    XCTAssertNotNil(tutorial)
    XCTAssertTrue(tutorial?.contexts.contains(context) ?? false)
  }

  func testHelpContextTitles() {
    XCTAssertEqual(HelpContext.profileCreation.title, "Profile Creation")
    XCTAssertEqual(HelpContext.settings.title, "Settings")
  }
}
