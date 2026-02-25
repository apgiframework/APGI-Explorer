@testable import APGI_Explorer
import XCTest

final class ContextualHelpManagerTests: XCTestCase {
    var helpManager: ContextualHelpManager!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.helpManager = ContextualHelpManager.shared
    }

    override func tearDownWithError() throws {
        self.helpManager = nil
    }

    func testContextualHelpManagerInitialization() {
        XCTAssertNotNil(self.helpManager)
        XCTAssertFalse(self.helpManager.isHelpVisible)
        XCTAssertNil(self.helpManager.currentHelpContext)
        XCTAssertFalse(self.helpManager.completedTutorials.isEmpty) // Has default tutorials
    }

    func testShowAndDismissHelp() {
        let context = HelpContext.profileCreation
        self.helpManager.showHelp(for: context)
        XCTAssertTrue(self.helpManager.isHelpVisible)
        XCTAssertEqual(self.helpManager.currentHelpContext, context)

        self.helpManager.dismissHelp()
        XCTAssertFalse(self.helpManager.isHelpVisible)
        XCTAssertNil(self.helpManager.currentHelpContext)
    }

    func testMarkTutorialCompleted() {
        let tutorialId = "test_tutorial"
        XCTAssertFalse(self.helpManager.isTutorialCompleted(tutorialId))

        self.helpManager.markTutorialCompleted(tutorialId)
        XCTAssertTrue(self.helpManager.isTutorialCompleted(tutorialId))
    }

    func testGetTutorialForContext() throws {
        let context = HelpContext.profileCreation
        let tutorial = self.helpManager.getTutorial(for: context)
        XCTAssertNotNil(tutorial)
        XCTAssertTrue(try XCTUnwrap(tutorial?.contexts.contains(context)))
    }

    func testHelpContextTitles() {
        XCTAssertEqual(HelpContext.profileCreation.title, "Profile Creation")
        XCTAssertEqual(HelpContext.settings.title, "Settings")
    }
}
