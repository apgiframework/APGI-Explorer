@testable import APGI_Explorer
import XCTest

final class ContextualHelpManagerTests: XCTestCase {
    var helpManager: ContextualHelpManager?

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.helpManager = ContextualHelpManager.shared
    }

    override func tearDownWithError() throws {
        self.helpManager = nil
    }

    func testContextualHelpManagerInitialization() {
        guard let helpManager = self.helpManager else {
            XCTFail("Help manager not initialized")
            return
        }
        XCTAssertNotNil(helpManager)
        XCTAssertFalse(helpManager.isHelpVisible)
        XCTAssertNil(helpManager.currentHelpContext)
        XCTAssertFalse(helpManager.completedTutorials.isEmpty) // Has default tutorials
    }

    func testShowAndDismissHelp() {
        guard let helpManager = self.helpManager else {
            XCTFail("Help manager not initialized")
            return
        }
        let context = HelpContext.profileCreation
        helpManager.showHelp(for: context)
        XCTAssertTrue(helpManager.isHelpVisible)
        XCTAssertEqual(helpManager.currentHelpContext, context)

        helpManager.dismissHelp()
        XCTAssertFalse(helpManager.isHelpVisible)
        XCTAssertNil(helpManager.currentHelpContext)
    }

    func testMarkTutorialCompleted() {
        guard let helpManager = self.helpManager else {
            XCTFail("Help manager not initialized")
            return
        }
        let tutorialId = "test_tutorial"
        XCTAssertFalse(helpManager.isTutorialCompleted(tutorialId))

        helpManager.markTutorialCompleted(tutorialId)
        XCTAssertTrue(helpManager.isTutorialCompleted(tutorialId))
    }

    func testGetTutorialForContext() throws {
        guard let helpManager = self.helpManager else {
            XCTFail("Help manager not initialized")
            return
        }
        let context = HelpContext.profileCreation
        let tutorial = helpManager.getTutorial(for: context)
        XCTAssertNotNil(tutorial)
        XCTAssertTrue(try XCTUnwrap(tutorial?.contexts.contains(context)))
    }

    func testHelpContextTitles() {
        XCTAssertEqual(HelpContext.profileCreation.title, "Profile Creation")
        XCTAssertEqual(HelpContext.settings.title, "Settings")
    }
}
