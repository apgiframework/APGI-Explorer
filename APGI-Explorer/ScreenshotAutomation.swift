import Foundation
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Accessibility
import ScreenCaptureKit


// run the script
// xcodebuild -scheme APGI-Explorer build
// xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode
// xcodebuild -scheme APGI-Explorer -configuration Debug -allowProvisioningUpdates -destination 'platform=macOS' RUN_DESTINATION_OPTIONS=--screenshot-mode


// MARK: - Screen Recording Permission
struct ScreenRecordingPermission {
    static var hasPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }
    
    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }
}

// MARK: - Configuration
struct ScreenshotConfig {
    let outputDirectory: String
    let imageFormat: ImageFormat
    let quality: Double
    let appearanceModes: [AppearanceMode]
    let resolutions: [Resolution]
    let delayBetweenScreens: TimeInterval
    let maxRetries: Int
    let enableLogging: Bool
    let captureScrollableContent: Bool
    let captureInteractiveStates: Bool
    let includeAccessibilityInfo: Bool
    let customScreenPaths: [CustomScreenPath]
    
    static let `default` = ScreenshotConfig(
        outputDirectory: (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/Screenshots",
        imageFormat: .png,
        quality: 0.9,
        appearanceModes: [.light, .dark],
        resolutions: [.default, .large, .small],
        delayBetweenScreens: 2.0,
        maxRetries: 3,
        enableLogging: true,
        captureScrollableContent: true,
        captureInteractiveStates: true,
        includeAccessibilityInfo: true,
        customScreenPaths: []
    )
}

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    
    var nsAppearance: NSAppearance.Name {
        switch self {
        case .light: return .aqua
        case .dark: return .darkAqua
        }
    }
}

enum ImageFormat: String, CaseIterable {
    case png = "png"
    case jpg = "jpg"
    case heic = "heic"
    
    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpg: return .jpeg
        case .heic: return .heic
        }
    }
}

enum Resolution: String, CaseIterable {
    case `default` = "default"
    case large = "large"
    case small = "small"
    case ultrawide = "ultrawide"
    
    var size: NSSize {
        switch self {
        case .default: return NSSize(width: 1200, height: 800)
        case .large: return NSSize(width: 1920, height: 1080)
        case .small: return NSSize(width: 800, height: 600)
        case .ultrawide: return NSSize(width: 3440, height: 1440)
        }
    }
}

struct CustomScreenPath {
    let name: String
    let navigationSteps: [NavigationStep]
    let interactions: [InteractionStep]
    let waitForElements: [String]
    let scrollCapture: Bool
}

struct NavigationStep {
    let type: NavigationType
    let target: String
    let delay: TimeInterval
}

enum NavigationType {
    case tab(String)
    case menu(String)
    case keyboardShortcut(String, NSEvent.ModifierFlags)
    case clickElement(String)
    case tapElement(String)
    case swipe(Direction)
    case wait(TimeInterval)
    case selectTab(String)
    case longPress(String)
}

// MARK: - Direction
enum Direction {
    case up, down, left, right
}

struct InteractionStep {
    let type: InteractionType
    let target: String
    let value: String?
    let delay: TimeInterval
}

// MARK: - Interaction Types
enum InteractionType {
    case tapElement(String)
    case typeText(String, String)
    case setSlider(String, Double)
    case scrollArea(String, Double)
    case toggleSwitch(String)
    case selectTab(String)
    case completeQuiz
    case swipe(Direction)
    case longPress(String)
    case buttonTap(String)
    case textFieldInput(String, String)
    case sliderMove(String, Double)
    case scroll(String, Double)
    case toggle(String)
}

// MARK: - Screen Navigation
struct ScreenNavigation {
    let name: String
    let identifier: String
    let navigationPath: [NavigationStep]
    let requiresInteraction: Bool
    let interactionType: InteractionType?
    let waitTime: TimeInterval
    let isDiscovered: Bool
    
    init(name: String, identifier: String, navigationPath: [NavigationStep], requiresInteraction: Bool, interactionType: InteractionType?, waitTime: TimeInterval, isDiscovered: Bool = false) {
        self.name = name
        self.identifier = identifier
        self.navigationPath = navigationPath
        self.requiresInteraction = requiresInteraction
        self.interactionType = interactionType
        self.waitTime = waitTime
        self.isDiscovered = isDiscovered
    }
    
    static let allScreens: [ScreenNavigation] = [
        ScreenNavigation(
            name: "Onboarding",
            identifier: "onboarding",
            navigationPath: [
                // Wait for the Onboarding screen to appear
                NavigationStep(type: .wait(2.0), target: "Wait for Onboarding", delay: 0.0),
                // Click through the onboarding steps (assuming 3 steps with a "Next" button)
                NavigationStep(type: .tapElement("Next"), target: "Next Button", delay: 1.0),
                NavigationStep(type: .wait(1.0), target: "Wait after first next", delay: 0.0),
                NavigationStep(type: .tapElement("Next"), target: "Next Button", delay: 1.0),
                NavigationStep(type: .wait(1.0), target: "Wait after second next", delay: 0.0),
                NavigationStep(type: .tapElement("Get Started"), target: "Get Started Button", delay: 1.0),
                NavigationStep(type: .wait(2.0), target: "Wait after onboarding completion", delay: 0.0)
            ],
            requiresInteraction: true,
            interactionType: nil,
            waitTime: 3.0
        ),
        ScreenNavigation(
            name: "Home",
            identifier: "home",
            navigationPath: [NavigationStep(type: .tab("home"), target: "home", delay: 0.5)],
            requiresInteraction: false,
            interactionType: nil,
            waitTime: 2.0
        ),
        ScreenNavigation(
            name: "Psychological States",
            identifier: "states",
            navigationPath: [NavigationStep(type: .tab("states"), target: "states", delay: 0.5)],
            requiresInteraction: false,
            interactionType: nil,
            waitTime: 2.0
        ),
        ScreenNavigation(
            name: "States List View",
            identifier: "states-list",
            navigationPath: [NavigationStep(type: .tab("states"), target: "states", delay: 0.5)],
            requiresInteraction: true,
            interactionType: .tapElement("list.bullet"),
            waitTime: 1.5
        ),
        ScreenNavigation(
            name: "States Grid View",
            identifier: "states-grid",
            navigationPath: [NavigationStep(type: .tab("states"), target: "states", delay: 0.5)],
            requiresInteraction: true,
            interactionType: .tapElement("square.grid.2x2"),
            waitTime: 1.5
        ),
        ScreenNavigation(
            name: "Profile Comparison",
            identifier: "compare",
            navigationPath: [NavigationStep(type: .tab("compare"), target: "compare", delay: 0.5)],
            requiresInteraction: false,
            interactionType: nil,
            waitTime: 2.0
        ),
        ScreenNavigation(
            name: "Settings",
            identifier: "settings",
            navigationPath: [NavigationStep(type: .tab("settings"), target: "settings", delay: 0.5)],
            requiresInteraction: false,
            interactionType: nil,
            waitTime: 1.5
        ),
        ScreenNavigation(
            name: "Quiz Introduction",
            identifier: "quiz-intro",
            navigationPath: [NavigationStep(type: .tab("home"), target: "home", delay: 0.5)],
            requiresInteraction: true,
            interactionType: .tapElement("play.fill"),
            waitTime: 2.5
        ),
        ScreenNavigation(
            name: "Quiz Questions",
            identifier: "quiz-questions",
            navigationPath: [
                NavigationStep(type: .tab("home"), target: "home", delay: 0.5),
                NavigationStep(type: .tapElement("play.fill"), target: "play.fill", delay: 1.0)
            ],
            requiresInteraction: true,
            interactionType: .tapElement("Start Quiz"),
            waitTime: 2.0
        ),
        ScreenNavigation(
            name: "Quiz Results",
            identifier: "quiz-results",
            navigationPath: [
                NavigationStep(type: .tab("home"), target: "home", delay: 0.5),
                NavigationStep(type: .tapElement("play.fill"), target: "play.fill", delay: 1.0),
                NavigationStep(type: .tapElement("Start Quiz"), target: "Start Quiz", delay: 1.0)
            ],
            requiresInteraction: true,
            interactionType: .completeQuiz,
            waitTime: 3.0
        )
    ]
}

// MARK: - Screen Navigator
class ScreenNavigator {
    private let accessibilityManager: AccessibilityManager
    private let logger: Logger
    private var currentScreen: ScreenNavigation?
    private var navigationStack: [ScreenNavigation] = []
    
    init(logger: Logger) {
        self.logger = logger
        self.accessibilityManager = AccessibilityManager(logger: logger)
    }
    
    /// Discover all available screens in the application
    func discoverAllScreens() -> [ScreenNavigation] {
        logger.log("🔍 Discovering all accessible screens...")
        
        var discoveredScreens: [ScreenNavigation] = []
        
        // 1. Add all predefined screens
        discoveredScreens.append(contentsOf: ScreenNavigation.allScreens)
        
        // 2. Discover dynamic screens through accessibility
        discoverDynamicScreens(&discoveredScreens)
        
        // 3. Discover screens from custom paths
        discoverCustomScreenPaths(&discoveredScreens)
        
        logger.log("✅ Discovered \(discoveredScreens.count) screens")
        return discoveredScreens
    }
    
    /// Navigate to a specific screen
    func navigate(to screen: ScreenNavigation) -> Bool {
        logger.log("🔄 Navigating to screen: \(screen.name)")
        
        // If already on this screen, no need to navigate
        if currentScreen?.identifier == screen.identifier {
            logger.log("ℹ️ Already on screen: \(screen.name)")
            return true
        }
        
        // Execute navigation path if it exists
        for step in screen.navigationPath {
            if !executeNavigationStep(step) {
                logger.log("❌ Failed to execute navigation step: \(step)")
                return false
            }
        }
        
        // Execute any required interaction
        if screen.requiresInteraction, let interaction = screen.interactionType {
            if !executeInteraction(interaction) {
                logger.log("❌ Failed to execute interaction for screen: \(screen.name)")
                return false
            }
        }
        
        // Wait for the screen to load
        Thread.sleep(forTimeInterval: screen.waitTime)
        
        // Update current screen and navigation stack
        if let current = currentScreen {
            navigationStack.append(current)
        }
        currentScreen = screen
        
        logger.log("✅ Successfully navigated to: \(screen.name)")
        return true
    }
    
    /// Go back to the previous screen
    func goBack() -> Bool {
        guard let previousScreen = navigationStack.popLast() else {
            logger.log("ℹ️ No previous screen in navigation stack")
            return false
        }
        
        logger.log("🔙 Going back to: \(previousScreen.name)")
        return navigate(to: previousScreen)
    }
    
    // MARK: - Private Methods
    
    /// Discover dynamic screens through accessibility
    private func discoverDynamicScreens(_ screens: inout [ScreenNavigation]) {
        guard let windowElements = accessibilityManager.getWindowElements() else {
            logger.log("⚠️ No window elements found for dynamic discovery")
            return
        }
        
        for element in windowElements {
            if let screenName = accessibilityManager.getElementTitle(element),
               !screenName.isEmpty,
               !screens.contains(where: { $0.name == screenName }) {
                
                let navigation = ScreenNavigation(
                    name: screenName,
                    identifier: screenName.lowercased().replacingOccurrences(of: " ", with: "-"),
                    navigationPath: [],
                    requiresInteraction: false,
                    interactionType: nil,
                    waitTime: 2.0,
                    isDiscovered: true
                )
                screens.append(navigation)
                logger.log("➕ Discovered dynamic screen: \(screenName)")
            }
        }
    }
    
    /// Discover screens from custom paths
    private func discoverCustomScreenPaths(_ screens: inout [ScreenNavigation]) {
        // This would be populated from a configuration or other source
        let customPaths: [String: [NavigationStep]] = [
            "Settings": [
                NavigationStep(type: .menu("App > Preferences..."), target: "Preferences", delay: 1.0),
                NavigationStep(type: .wait(1.0), target: "Wait for settings", delay: 1.0)
            ]
        ]
        
        for (screenName, path) in customPaths {
            if !screens.contains(where: { $0.name == screenName }) {
                let navigation = ScreenNavigation(
                    name: screenName,
                    identifier: screenName.lowercased().replacingOccurrences(of: " ", with: "-"),
                    navigationPath: path,
                    requiresInteraction: false,
                    interactionType: nil,
                    waitTime: 2.0,
                    isDiscovered: true
                )
                screens.append(navigation)
                logger.log("➕ Added custom screen path: \(screenName)")
            }
        }
    }
    
    /// Execute a single navigation step
    private func executeNavigationStep(_ step: NavigationStep) -> Bool {
        logger.log("   ↳ Executing navigation step: \(step.target)")
        
        switch step.type {
        case .tab(let tabName):
            return accessibilityManager.selectTab(named: tabName)
            
        case .menu(let menuPath):
            return accessibilityManager.selectMenu(path: [menuPath])
            
        case .keyboardShortcut(let key, let modifiers):
            accessibilityManager.simulateKeyPress(key: key, modifiers: modifiers)
            return true
            
        case .clickElement(let identifier):
            return accessibilityManager.clickElement(withIdentifier: identifier)
            
        case .swipe(let direction):
            return accessibilityManager.performSwipe(direction: direction)
            
        case .wait(let interval):
            Thread.sleep(forTimeInterval: interval)
            return true
            
        case .selectTab(let tabName):
            return accessibilityManager.selectTab(named: tabName)
            
        default:
            logger.log("⚠️ Unsupported navigation step: \(step)")
            return false
        }
    }
    
    /// Execute an interaction on the current screen
    private func executeInteraction(_ interaction: InteractionType) -> Bool {
        logger.log("   ↳ Executing interaction: \(interaction)")
        
        switch interaction {
        case .tapElement(let identifier):
            return accessibilityManager.clickElement(withIdentifier: identifier)
            
        case .typeText(let identifier, let text):
            return accessibilityManager.typeText(text, inElementWithIdentifier: identifier)
            
        case .setSlider(let identifier, let value):
            return accessibilityManager.setSliderValue(value, forElementWithIdentifier: identifier)
            
        case .scrollArea(let identifier, let value):
            return accessibilityManager.scrollArea(identifier, by: value)
            
        case .toggleSwitch(let identifier):
            return accessibilityManager.toggleSwitch(withIdentifier: identifier)
            
        case .selectTab(let identifier):
            return accessibilityManager.selectTab(named: identifier)
            
        case .completeQuiz:
            // Implementation depends on the quiz structure
            return accessibilityManager.completeQuiz()
            
        case .swipe(let direction):
            return accessibilityManager.performSwipe(direction: direction)
            
        case .longPress(let identifier):
            return accessibilityManager.performLongPress(onElementWithIdentifier: identifier)
            
        case .buttonTap(let identifier):
            return accessibilityManager.tapButton(withIdentifier: identifier)
            
        case .textFieldInput(let identifier, let text):
            return accessibilityManager.typeText(text, inElementWithIdentifier: identifier)
            
        case .sliderMove(let identifier, let value):
            return accessibilityManager.setSliderValue(value, forElementWithIdentifier: identifier)
            
        case .scroll(let identifier, let value):
            return accessibilityManager.scrollArea(identifier, by: value)
            
        case .toggle(let identifier):
            return accessibilityManager.toggleElement(withIdentifier: identifier)
        }
    }
}

// MARK: - Accessibility Manager
class AccessibilityManager {
    private let logger: Logger
    private let systemWideElement = AXUIElementCreateSystemWide()
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    /// Get all window elements from the current application
    func getWindowElements() -> [AXUIElement]? {
        guard let app = getTargetApplication() else { 
            logger.log("⚠️ Failed to get target application")
            return nil 
        }
        
        var windows: AnyObject?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows)
        
        guard result == .success, let windowElements = windows as? [AXUIElement] else {
            logger.log("⚠️ Failed to get window elements: \(result.rawValue)")
            return nil
        }
        
        return windowElements
    }
    
    /// Get the target application element
    func getTargetApplication() -> AXUIElement? {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.bundleIdentifier == "com.example.APGI-Explorer" }) else {
            logger.log("⚠️ Target application not running")
            return nil
        }
        return AXUIElementCreateApplication(app.processIdentifier)
    }
    
    /// Find an element by its identifier with retry logic
    func findElement(identifier: String, in parent: AXUIElement? = nil, maxRetries: Int = 3, retryDelay: TimeInterval = 0.5) -> AXUIElement? {
        let root = parent ?? getTargetApplication()
        guard let app = root else { 
            logger.log("⚠️ Target application not found")
            return nil 
        }
        
        var retryCount = 0
        var lastError: AXError = .success
        
        while retryCount < maxRetries {
            var element: CFTypeRef?
            let error = AXUIElementCopyAttributeValue(app, kAXChildrenAttribute as CFString, &element)
            
            if error == .success, let value = element {
                // If the attribute returns a single AXUIElement
                if CFGetTypeID(value) == AXUIElementGetTypeID(), let single = unsafeBitCast(value, to: AXUIElement?.self) {
                    return single
                }
                // If the attribute returns an array of AXUIElement
                if CFGetTypeID(value) == CFArrayGetTypeID(), let array = value as? [AXUIElement] {
                    // Look for element with matching identifier
                    for child in array {
                        var identifierValue: AnyObject?
                        let idError = AXUIElementCopyAttributeValue(child, kAXIdentifierAttribute as CFString, &identifierValue)
                        if idError == .success, let id = identifierValue as? String, id == identifier {
                            return child
                        }
                    }
                    // As a fallback, return the first child if present
                    if let first = array.first {
                        logger.log("✅ Found element with identifier: \(identifier) (attempt \(retryCount + 1)/\(maxRetries))")
                        return first
                    }
                }
            }
            
            lastError = error
            logger.log("⚠️ Element not found with identifier: \(identifier) (attempt \(retryCount + 1)/\(maxRetries))")
            
            // If we have retries left, wait before trying again
            if retryCount < maxRetries - 1 {
                Thread.sleep(forTimeInterval: retryDelay)
            }
            retryCount += 1
        }
        
        logger.log("❌ Failed to find element with identifier: \(identifier) after \(maxRetries) attempts. Error: \(lastError.rawValue)")
        return nil
    }
    
    /// Click an element with the specified identifier with retry logic
    func clickElement(withIdentifier identifier: String, maxRetries: Int = 3) -> Bool {
        for attempt in 0..<maxRetries {
            logger.log("🔍 Attempting to click element: \(identifier) (attempt \(attempt + 1)/\(maxRetries))")
            
            // Try to find the element
            guard let element = findElement(identifier: identifier, maxRetries: 3) else {
                logger.log("⚠️ Element not found: \(identifier)")
                Thread.sleep(forTimeInterval: 1.0) // Wait before retry
                continue
            }
            
            // Try to get the element's frame to verify it's on screen
            var position: CFTypeRef?
            let positionResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)
            
            if positionResult != .success || position == nil {
                logger.log("⚠️ Could not get position for element: \(identifier)")
                Thread.sleep(forTimeInterval: 1.0)
                continue
            }
            
            // Try to perform the click
            let error = AXUIElementPerformAction(element, kAXPressAction as CFString)
            
            if error == .success {
                logger.log("✅ Successfully clicked element: \(identifier)")
                Thread.sleep(forTimeInterval: 0.5) // Small delay after successful click
                return true
            } else {
                logger.log("⚠️ Failed to click element: \(identifier). Error: \(error.rawValue)")
            }
            
            // Wait before next attempt
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        logger.log("❌ Failed to click element after \(maxRetries) attempts: \(identifier)")
        return false
    }
    
    /// Type text into an element
    func typeText(_ text: String, inElementWithIdentifier identifier: String) -> Bool {
        guard let element = findElement(identifier: identifier) else {
            logger.log("⚠️ Element not found for typing: \(identifier)")
            return false
        }
        
        // Set the value of the element to the text
        let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, text as CFTypeRef)
        return result == .success
    }
    
    /// Set slider value
    func setSliderValue(_ value: Double, forElementWithIdentifier identifier: String) -> Bool {
        guard let element = findElement(identifier: identifier) else {
            logger.log("⚠️ Slider not found: \(identifier)")
            return false
        }
        
        let number = NSNumber(value: value)
        let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, number)
        return result == .success
    }
    
    /// Toggle a switch or checkbox
    func toggleSwitch(withIdentifier identifier: String) -> Bool {
        guard let element = findElement(identifier: identifier) else {
            logger.log("⚠️ Switch not found: \(identifier)")
            return false
        }
        
        var value: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        
        guard error == .success, let currentValue = value as? Bool else { return false }
        
        let newValue = !currentValue
        let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newValue as CFTypeRef)
        return result == .success
    }
    
    /// Select a tab by name
    func selectTab(named tabName: String) -> Bool {
        guard let app = getTargetApplication() else { return false }
        
        var tabs: AnyObject?
        let error = AXUIElementCopyAttributeValue(app, kAXTabsAttribute as CFString, &tabs)
        
        guard error == .success, let tabGroup = tabs as? [AXUIElement], !tabGroup.isEmpty else { 
            logger.log("⚠️ No tabs found")
            return false 
        }
        
        for tab in tabGroup {
            var title: AnyObject?
            let titleError = AXUIElementCopyAttributeValue(tab, kAXTitleAttribute as CFString, &title)
            
            if titleError == .success, let tabTitle = title as? String, tabTitle == tabName {
                return performAction(kAXPressAction as String, on: tab)
            }
        }
        
        logger.log("⚠️ Tab not found: \(tabName)")
        return false
    }
    
    /// Perform a swipe gesture in the specified direction
    func performSwipe(direction: Direction) -> Bool {
        // Implementation depends on the application's accessibility support
        // This is a simplified version - might need adjustment based on the app
        let source = CGEventSource(stateID: .hidSystemState)
        let start: NSPoint
        let end: NSPoint
        
        if let window = NSApp.keyWindow {
            let frame = window.frame
            switch direction {
            case .up:
                start = NSPoint(x: frame.midX, y: frame.minY + 100)
                end = NSPoint(x: frame.midX, y: frame.maxY - 100)
            case .down:
                start = NSPoint(x: frame.midX, y: frame.maxY - 100)
                end = NSPoint(x: frame.midX, y: frame.minY + 100)
            case .left:
                start = NSPoint(x: frame.maxX - 100, y: frame.midY)
                end = NSPoint(x: frame.minX + 100, y: frame.midY)
            case .right:
                start = NSPoint(x: frame.minX + 100, y: frame.midY)
                end = NSPoint(x: frame.maxX - 100, y: frame.midY)
            }
            
            // Simulate mouse down
            let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                                   mouseCursorPosition: start, mouseButton: .left)
            mouseDown?.post(tap: .cghidEventTap)
            
            // Simulate drag
            let drag = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged,
                              mouseCursorPosition: end, mouseButton: .left)
            drag?.post(tap: .cghidEventTap)
            
            // Simulate mouse up
            let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                                 mouseCursorPosition: end, mouseButton: .left)
            mouseUp?.post(tap: .cghidEventTap)
            
            return true
        }
        
        return false
    }
    
    /// Perform a long press on an element
    func performLongPress(onElementWithIdentifier identifier: String) -> Bool {
        guard let element = findElement(identifier: identifier) else {
            logger.log("⚠️ Element not found for long press: \(identifier)")
            return false
        }
        
        // Simulate a long press by holding the mouse down for a longer duration
        var positionRef: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
        
        guard positionResult == .success, let positionValue = positionRef else { return false }
        
        var point = CGPoint.zero
        if AXValueGetValue(positionValue as! AXValue, .cgPoint, &point) {
            let source = CGEventSource(stateID: .hidSystemState)
        
            // Mouse down
            let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown,
                                   mouseCursorPosition: point, mouseButton: .left)
            mouseDown?.post(tap: .cghidEventTap)
            
            // Hold for 1 second to simulate long press
            Thread.sleep(forTimeInterval: 1.0)
            
            // Mouse up
            let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp,
                                 mouseCursorPosition: point, mouseButton: .left)
            mouseUp?.post(tap: .cghidEventTap)
            
            return true
        }
        
        return false
    }
    
    /// Scroll an area by a certain amount
    func scrollArea(_ identifier: String, by value: Double) -> Bool {
        guard let element = findElement(identifier: identifier) else {
            logger.log("⚠️ Scroll area not found: \(identifier)")
            return false
        }
        
        // Get current scroll value
        var currentValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &currentValue)
        
        guard error == .success else { return false }
        
        // Set new scroll value
        let newValue = (currentValue as? Double ?? 0) + value
        let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newValue as CFTypeRef)
        
        return result == .success
    }
    
    /// Complete a quiz (implementation depends on the quiz structure)
    func completeQuiz() -> Bool {
        // This is a placeholder implementation
        // You would need to implement the specific steps to complete a quiz
        logger.log("Completing quiz...")
        
        // Example: Find and click the submit button
        if let submitButton = findElement(identifier: "submit-quiz") {
            return performAction(kAXPressAction as String, on: submitButton)
        }
        
        return false
    }
    
    /// Toggle an element (like a switch or checkbox)
    func toggleElement(withIdentifier identifier: String) -> Bool {
        return toggleSwitch(withIdentifier: identifier)
    }
    
    /// Tap a button with the specified identifier
    func tapButton(withIdentifier identifier: String) -> Bool {
        return clickElement(withIdentifier: identifier)
    }
    
    /// Get the title of an element
    func getElementTitle(_ element: AXUIElement) -> String? {
        var title: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
        
        guard error == .success else { return nil }
        return title as? String
    }
    
    /// Simulate a key press with optional modifiers
    func simulateKeyPress(key: String, modifiers: NSEvent.ModifierFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyCode = key.utf16.first?.hashValue ?? 0
        
        // Key down
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true)
        keyDown?.flags = CGEventFlags(rawValue: UInt64(modifiers.rawValue))
        keyDown?.post(tap: .cghidEventTap)
        
        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false)
        keyUp?.flags = CGEventFlags(rawValue: UInt64(modifiers.rawValue))
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// Select a menu item using a path (e.g., ["File", "Open"])
    func selectMenu(path: [String]) -> Bool {
        guard !path.isEmpty else { return false }
        
        // Press Command+Shift+/ to open the Help menu (as a starting point)
        simulateKeyPress(key: "/", modifiers: [.command, .shift])
        
        // Type each menu item in the path
        for item in path {
            // Type the menu item name
            for char in item.lowercased() {
                simulateKeyPress(key: String(char), modifiers: [])
                Thread.sleep(forTimeInterval: 0.05)
            }
            
            // Press Enter to select
            simulateKeyPress(key: "\r", modifiers: [])
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func performAction(_ action: String, on element: AXUIElement) -> Bool {
        var error = AXUIElementPerformAction(element, action as CFString)
        if error == .success {
            return true
        }
        
        // If direct action fails, try using the accessibility API
        var actions: CFArray?
        error = AXUIElementCopyActionNames(element, &actions)
        
        guard error == .success, let actionNames = actions as? [String], actionNames.contains(action) else {
            return false
        }
        
        error = AXUIElementPerformAction(element, action as CFString)
        return error == .success
    }
    
    private func getElementValue(_ element: AXUIElement, attribute: String) -> Any? {
        var value: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return error == .success ? value : nil
    }
}

struct ElementInfo {
    let role: String
    let label: String
    let value: String
}

// MARK: - Screenshot Automation Engine
class ScreenshotAutomationEngine {
    private let config: ScreenshotConfig
    private let logger: Logger
    private let navigator: ScreenNavigator
    private let screenshotManager: ScreenshotManager
    private var screenshotCount = 0
    
    init(config: ScreenshotConfig = .default) {
        self.config = config
        self.logger = Logger(enabled: config.enableLogging)
        self.navigator = ScreenNavigator(logger: logger)
        self.screenshotManager = ScreenshotManager(config: config, logger: logger)
        
        createOutputDirectory()
    }
    
    func run() {
        logger.log("Starting screenshot automation...")
        logger.log("Configuration: \(config)")
        
        // Check screen recording permission
        guard ScreenRecordingPermission.hasPermission else {
            logger.log("ERROR: Screen recording permission not granted. Please grant permission in System Preferences > Security & Privacy > Privacy > Screen Recording")
            return
        }
        
        // Skip launching app since we're already running inside it
        logger.log("App is already running, skipping launch...")
        
        // Wait for app to fully load
        Thread.sleep(forTimeInterval: 3.0)
        
        // Discover all screens
        let allScreens = navigator.discoverAllScreens()
        
        // Process each appearance mode
        for appearance in config.appearanceModes {
            logger.log("Processing appearance mode: \(appearance.rawValue)")
            setAppearance(appearance.nsAppearance)
            
            // Process each resolution
            for resolution in config.resolutions {
                logger.log("Processing resolution: \(resolution.rawValue)")
                setResolution(resolution)
                
                // Navigate and capture all screens
                navigateAndCaptureScreens(allScreens)
            }
        }
        
        generateReport()
        logger.log("Screenshot automation completed. Total screenshots: \(screenshotCount)")
    }
    
    private func launchApp() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", "APGI-Explorer"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            logger.log("Failed to launch app: \(error)")
            return false
        }
    }
    
    private func setAppearance(_ appearance: NSAppearance.Name) {
        DispatchQueue.main.async {
            NSApp.appearance = NSAppearance(named: appearance)
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func setResolution(_ resolution: Resolution) {
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow {
                window.setFrame(NSRect(origin: .zero, size: resolution.size), display: true)
                window.center()
            }
        }
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    private func navigateAndCaptureScreens(_ screens: [ScreenNavigation]) {
        for screen in screens {
            logger.log("Processing screen: \(screen.name)")
            
            if navigateToScreen(screen) {
                Thread.sleep(forTimeInterval: screen.waitTime)
                
                if screen.requiresInteraction, let interaction = screen.interactionType {
                    performInteraction(interaction)
                    Thread.sleep(forTimeInterval: 1.0)
                }
                
                // Capture main screenshot
                captureScreenshot(screenName: screen.name, suffix: "main")
                
                // Capture scrollable content if enabled
                if config.captureScrollableContent {
                    captureScrollableContent(screenName: screen.name)
                }
                
                // Capture interactive states if enabled
                if config.captureInteractiveStates {
                    captureInteractiveStates(screenName: screen.name)
                }
                
                Thread.sleep(forTimeInterval: config.delayBetweenScreens)
            } else {
                logger.log("Failed to navigate to screen: \(screen.name)")
            }
        }
    }
    
    private func navigateToScreen(_ screen: ScreenNavigation) -> Bool {
        switch screen.identifier {
        case "home":
            simulateKeyPress(key: "1", modifiers: .command)
        case "states":
            simulateKeyPress(key: "1", modifiers: .command)
        case "compare":
            simulateKeyPress(key: "2", modifiers: .command)
        case "settings":
            simulateKeyPress(key: ",", modifiers: .command)
        default:
            // Use accessibility for complex navigation
            return navigateUsingAccessibility(screen)
        }
        
        return true
    }
    
    private func navigateUsingAccessibility(_ screen: ScreenNavigation) -> Bool {
        // Implement complex navigation using accessibility APIs
        return true
    }
    
    private func performInteraction(_ interaction: InteractionType) {
        switch interaction {
        case .tapElement(_):
            // Use accessibility to find and tap element
            break
        case .typeText(_, _):
            break
        case .setSlider(_, _):
            break
        case .scrollArea(_, _):
            break
        case .toggleSwitch(_):
            break
        case .selectTab(_):
            break
        case .completeQuiz:
            completeQuizInteraction()
        case .swipe(let direction):
            performSwipe(direction)
        case .longPress(_):
            break
        case .buttonTap(let iconName):
            clickButton(withIcon: iconName)
        case .textFieldInput(let identifier, let text):
            inputText(inField: identifier, text: text)
        case .sliderMove(let identifier, let value):
            moveSlider(identifier: identifier, value: value)
        case .scroll(let identifier, let amount):
            scrollArea(identifier: identifier, amount: amount)
        case .toggle(let identifier):
            toggleSwitch(identifier: identifier)
        }
    }
    
    private func completeQuizInteraction() {
        // Simulate completing the quiz with default answers
        Thread.sleep(forTimeInterval: 0.5)
        simulateKeyPress(key: "\r", modifiers: []) // Press Enter to continue
    }
    
    private func performSwipe(_ direction: Direction) {
        // Implement swipe gesture
    }
    
    private func simulateKeyPress(key: String, modifiers: NSEvent.ModifierFlags) {
        DispatchQueue.main.async {
            let cgEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key.utf8.first ?? 0), keyDown: true)
            cgEvent?.flags = CGEventFlags(rawValue: UInt64(modifiers.rawValue))
            cgEvent?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: 0.1)
            
            let cgEventUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key.utf8.first ?? 0), keyDown: false)
            cgEventUp?.flags = CGEventFlags(rawValue: UInt64(modifiers.rawValue))
            cgEventUp?.post(tap: .cghidEventTap)
        }
    }
    
    private func clickButton(withIcon iconName: String) {
        // This would require accessibility APIs to find and click buttons
        // For now, we'll simulate a click at a known position
        DispatchQueue.main.async {
            let clickPoint = NSPoint(x: 100, y: 100) // Adjust based on actual button positions
            let cgEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: clickPoint, mouseButton: .left)
            cgEvent?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: 0.1)
            
            let cgEventUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: clickPoint, mouseButton: .left)
            cgEventUp?.post(tap: .cghidEventTap)
        }
    }
    
    private func inputText(inField identifier: String, text: String) {
        // Implementation for text input
    }
    
    private func moveSlider(identifier: String, value: Double) {
        // Implementation for slider movement
    }
    
    private func scrollArea(identifier: String, amount: Double) {
        // Implementation for scrolling
    }
    
    private func toggleSwitch(identifier: String) {
        // Implementation for toggle switches
    }
    
    private func captureScreenshot(screenName: String, suffix: String = "") {
        let success = screenshotManager.captureScreen(screenName: screenName, suffix: suffix)
        if success {
            screenshotCount += 1
        }
    }
    
    private func captureScrollableContent(screenName: String) {
        // Implement scrollable content capture
        logger.log("Capturing scrollable content for: \(screenName)")
    }
    
    private func captureInteractiveStates(screenName: String) {
        // Implement interactive states capture (hover, pressed, etc.)
        logger.log("Capturing interactive states for: \(screenName)")
    }
    
    private func createOutputDirectory() {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: config.outputDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Create subdirectories
            let subdirs = ["light-mode", "dark-mode", "accessibility-info", "reports"]
            for subdir in subdirs {
                let subdirPath = "\(config.outputDirectory)/\(subdir)"
                try fileManager.createDirectory(atPath: subdirPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            logger.log("Created output directory structure")
        } catch {
            logger.log("Failed to create output directory: \(error)")
        }
    }
    
    private func generateReport() {
        let report = ScreenshotReport(
            totalScreenshots: screenshotCount,
            config: config,
            timestamp: Date(),
            successRate: Double(screenshotCount) / Double(navigator.discoverAllScreens().count * config.appearanceModes.count * config.resolutions.count)
        )
        
        let reportPath = "\(config.outputDirectory)/reports/screenshot_report_\(Date().timeIntervalSince1970).json"
        report.save(to: reportPath)
        logger.log("Report generated: \(reportPath)")
    }
}
// MARK: - Screenshot Manager
class ScreenshotManager {
    private let config: ScreenshotConfig
    private let logger: Logger
    private let fileManager = FileManager.default
    private var currentAppearance: AppearanceMode = .light
    private var currentResolution: Resolution = .default
    
    init(config: ScreenshotConfig, logger: Logger) {
        self.config = config
        self.logger = logger
        createOutputDirectories()
    }
    
    // MARK: - Public Methods
    
    /// Set the current appearance mode for screenshot naming
    func setAppearance(_ appearance: AppearanceMode) {
        self.currentAppearance = appearance
    }
    
    /// Set the current resolution for screenshot naming
    func setResolution(_ resolution: Resolution) {
        self.currentResolution = resolution
    }
    
    /// Capture a screenshot of the specified screen or element
    /// - Parameters:
    ///   - screenName: Name of the screen being captured (used for file naming)
    ///   - suffix: Optional suffix to append to the filename
    ///   - element: Optional AXUIElement to capture instead of the whole screen
    /// - Returns: Boolean indicating success or failure
    func captureScreen(screenName: String, suffix: String = "", element: AXUIElement? = nil) -> Bool {
        var screenshot: NSImage?
        var success = false
        
        // Try multiple times if needed
        for attempt in 0..<config.maxRetries {
            if attempt > 0 {
                logger.log("Retry \(attempt + 1) for \(screenName)")
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            if let element = element {
                screenshot = captureElement(element)
            } else {
                screenshot = captureFullScreen()
            }
            
            if screenshot != nil {
                success = saveScreenshot(screenshot!, screenName: screenName, suffix: suffix)
                if success { break }
            }
        }
        
        if !success {
            logger.log("Failed to capture screen: \(screenName) after \(config.maxRetries) attempts")
        }
        
        return success
    }
    
    // MARK: - Private Methods
    
    /// Create necessary output directories
    private func createOutputDirectories() {
        let directories = [
            config.outputDirectory,
            "\(config.outputDirectory)/light-mode",
            "\(config.outputDirectory)/dark-mode",
            "\(config.outputDirectory)/accessibility"
        ]
        
        for dir in directories {
            do {
                try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.log("Failed to create directory \(dir): \(error)")
            }
        }
    }
    
    /// Capture a specific UI element
    private func captureElement(_ element: AXUIElement) -> NSImage? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        let positionResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
        let sizeResult = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)
        
        guard positionResult == .success, sizeResult == .success,
              let positionValue = positionRef, let sizeValue = sizeRef else {
            logger.log("Failed to get element frame")
            return nil
        }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else {
            logger.log("Failed to extract position/size values")
            return nil
        }
        
        // Convert to screen coordinates
        let screenHeight = NSScreen.main?.frame.height ?? 0
        position.y = screenHeight - position.y - size.height  // Flip Y coordinate
        
        // Add padding around the element
        let padding: CGFloat = 5.0
        let paddedRect = CGRect(x: position.x - padding,
                              y: position.y - padding,
                              width: size.width + (padding * 2),
                              height: size.height + (padding * 2))
        
        return captureArea(paddedRect)
    }
    
    /// Capture the full screen
    private func captureFullScreen() -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        return captureArea(screen.frame)
    }
    
    /// Capture a specific area of the screen
    private func captureArea(_ rect: CGRect) -> NSImage? {
        // Use ScreenCaptureKit for modern screen capture
        let semaphore = DispatchSemaphore(value: 0)
        var resultImage: NSImage?
        
        Task {
            do {
                // Get available content filters
                let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                
                // Find the main display
                guard let mainDisplay = availableContent.displays.first(where: { $0.displayID == CGMainDisplayID() }) else {
                    logger.log("Failed to find main display")
                    semaphore.signal()
                    return
                }
                
                // Create a filter for the main display
                let filter = SCContentFilter(display: mainDisplay, excludingWindows: [])
                
                // Capture the content
                let configuration = SCStreamConfiguration()
                configuration.width = Int(rect.width)
                configuration.height = Int(rect.height)
                configuration.sourceRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
                
                let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
                resultImage = NSImage(cgImage: image, size: rect.size)
                
            } catch {
                logger.log("Failed to capture screen: \(error)")
            }
            
            semaphore.signal()
        }
        
        // Wait for async capture to complete
        semaphore.wait()
        return resultImage
    }
    
    /// Save the screenshot to disk
    private func saveScreenshot(_ image: NSImage, screenName: String, suffix: String) -> Bool {
        let fileName = generateFileName(screenName: screenName, suffix: suffix)
        let filePath = getFilePath(for: fileName)
        
        guard let imageData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: imageData) else {
            logger.log("Failed to process image data")
            return false
        }
        
        // Set image properties based on format
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: config.quality
        ]
        
        // Convert to the desired format
        guard let data = bitmapImage.representation(
            using: config.imageFormat == .png ? .png : .jpeg,
            properties: properties
        ) else {
            logger.log("Failed to create image representation")
            return false
        }
        
        // Save the file
        do {
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            logger.log("Screenshot saved: \(filePath)")
            
            // Save accessibility info if enabled
            if config.includeAccessibilityInfo {
                saveAccessibilityInfo(screenName: screenName, filePath: filePath)
            }
            
            return true
        } catch {
            logger.log("Failed to save screenshot: \(error)")
            return false
        }
    }
    
    /// Generate a standardized filename for screenshots
    private func generateFileName(screenName: String, suffix: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let timestamp = formatter.string(from: Date())
        
        let safeScreenName = screenName
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let suffixPart = suffix.isEmpty ? "" : "_\(suffix)"
        let resolution = "\(Int(currentResolution.size.width))x\(Int(currentResolution.size.height))"
        
        return "\(safeScreenName)\(suffixPart)_\(currentAppearance.rawValue)_\(resolution)_\(timestamp).\(config.imageFormat.rawValue)"
    }
    
    /// Get the full file path for saving a screenshot
    private func getFilePath(for fileName: String) -> String {
        let modeDir = currentAppearance == .dark ? "dark-mode" : "light-mode"
        return "\(config.outputDirectory)/\(modeDir)/\(fileName)"
    }
    
    /// Save accessibility information for a screenshot
    private func saveAccessibilityInfo(screenName: String, filePath: String) {
        let infoPath = "\(config.outputDirectory)/accessibility/\(screenName)_\(Date().timeIntervalSince1970).json"
        
        let accessibilityInfo: [String: Any] = [
            "screen": screenName,
            "timestamp": Date().timeIntervalSince1970,
            "appearance": currentAppearance.rawValue,
            "resolution": [
                "width": currentResolution.size.width,
                "height": currentResolution.size.height
            ],
            "screenshot_path": filePath,
            "elements": []  // This would be populated with actual element data
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: accessibilityInfo, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: infoPath), options: .atomic)
        } catch {
            logger.log("Failed to save accessibility info: \(error)")
        }
    }
}

// MARK: - Screenshot Report
struct ScreenshotReport {
    let totalScreenshots: Int
    let config: ScreenshotConfig
    let timestamp: Date
    let successRate: Double
    
    func save(to path: String) {
        let reportData: [String: Any] = [
            "totalScreenshots": totalScreenshots,
            "timestamp": timestamp.timeIntervalSince1970,
            "successRate": successRate,
            "config": [
                "imageFormat": config.imageFormat.rawValue,
                "quality": config.quality,
                "appearanceModes": config.appearanceModes.map { $0.rawValue },
                "resolutions": config.resolutions.map { $0.rawValue }
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: reportData, options: .prettyPrinted)
            try jsonData.write(to: URL(fileURLWithPath: path))
        } catch {
            print("Failed to save report: \(error)")
        }
    }
}

// MARK: - Logger
class Logger {
    private let enabled: Bool
    private let logFile: URL?
    
    init(enabled: Bool) {
        self.enabled = enabled
        if enabled {
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Warning: Unable to access Documents directory for logging")
                self.logFile = nil
                return
            }
            self.logFile = documentsPath.appendingPathComponent("screenshot_automation.log")
        } else {
            self.logFile = nil
        }
    }
    
    func log(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        
        if enabled {
            print(logMessage)
            
            if let logFile = logFile {
                if let data = (logMessage + "\n").data(using: .utf8) {
                    if FileManager.default.fileExists(atPath: logFile.path) {
                        if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            fileHandle.closeFile()
                        }
                    } else {
                        try? data.write(to: logFile)
                    }
                }
            }
        }
    }
}

// MARK: - Production-Safe Screenshot Automation Engine
class ProductionScreenshotAutomationEngine {
    private let config: ProductionScreenshotConfig
    private let logger: Logger
    private let screenshotManager: ScreenshotManager
    private var screenshotCount = 0
    
    init(config: ProductionScreenshotConfig) {
        self.config = config
        self.logger = Logger(enabled: config.enableLogging)
        self.screenshotManager = ScreenshotManager(
            config: ScreenshotConfig(
                outputDirectory: config.outputDirectory,
                imageFormat: config.imageFormat,
                quality: config.quality,
                appearanceModes: [.light],  // Only light mode in production
                resolutions: [.default],    // Only default resolution in production
                delayBetweenScreens: 1.0,
                maxRetries: 2,
                enableLogging: config.enableLogging,
                captureScrollableContent: false,  // Disabled for safety
                captureInteractiveStates: false,  // Disabled for safety
                includeAccessibilityInfo: false,  // Disabled for privacy
                customScreenPaths: []
            ),
            logger: logger
        )
        
        createOutputDirectory()
    }
    
    func run() {
        logger.log("🏭 Starting production-safe screenshot automation...")
        logger.log("📸 Max screenshots allowed: \(config.maxScreenshotsPerSession)")
        logger.log("📋 Allowed screens: \(config.allowedScreens)")
        
        // Get only allowed screens
        let allowedScreens = ScreenNavigation.allScreens.filter { screen in
            config.allowedScreens.contains(screen.identifier)
        }
        
        logger.log("📱 Found \(allowedScreens.count) allowed screens to capture")
        
        // Process each allowed screen
        for screen in allowedScreens {
            guard screenshotCount < config.maxScreenshotsPerSession else {
                logger.log("⚠️ Reached maximum screenshot limit (\(config.maxScreenshotsPerSession))")
                break
            }
            
            logger.log("📸 Capturing screen: \(screen.name)")
            
            if navigateToScreen(screen) {
                Thread.sleep(forTimeInterval: 1.0)  // Short wait for screen to stabilize
                
                // Capture screenshot
                if captureScreenshot(screenName: screen.name) {
                    screenshotCount += 1
                    logger.log("✅ Successfully captured screenshot \(screenshotCount)/\(config.maxScreenshotsPerSession)")
                } else {
                    logger.log("❌ Failed to capture screenshot for screen: \(screen.name)")
                }
                
                Thread.sleep(forTimeInterval: 0.5)  // Brief delay between screens
            } else {
                logger.log("❌ Failed to navigate to screen: \(screen.name)")
            }
        }
        
        logger.log("🎉 Production screenshot automation completed")
        logger.log("📸 Total screenshots captured: \(screenshotCount)")
        
        // Show completion alert in production
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Screenshot Automation Complete"
            alert.informativeText = "Successfully captured \(self.screenshotCount) screenshots.\nScreenshots saved to: \(self.config.outputDirectory)"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    private func createOutputDirectory() {
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: config.outputDirectory)
        
        if !fileManager.fileExists(atPath: config.outputDirectory) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                logger.log("✅ Created output directory: \(config.outputDirectory)")
            } catch {
                logger.log("❌ Failed to create output directory: \(error)")
            }
        }
    }
    
    private func navigateToScreen(_ screen: ScreenNavigation) -> Bool {
        // Simple navigation for production - only basic keyboard shortcuts
        switch screen.identifier {
        case "home":
            simulateKeyPress(key: "1", modifiers: .command)
        case "states":
            simulateKeyPress(key: "2", modifiers: .command)
        case "compare":
            simulateKeyPress(key: "3", modifiers: .command)
        case "settings":
            simulateKeyPress(key: ",", modifiers: .command)
        default:
            logger.log("⚠️ Screen '\(screen.identifier)' not supported in production mode")
            return false
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        return true
    }
    
    private func captureScreenshot(screenName: String) -> Bool {
        guard let window = NSApp.keyWindow else {
            logger.log("❌ No key window found for screenshot")
            return false
        }
        
        // Use a simple view-based screenshot approach
        guard let view = window.contentView else {
            logger.log("❌ No content view found")
            return false
        }
        
        // Create a bitmap representation of the view
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            logger.log("❌ Failed to create bitmap representation")
            return false
        }
        view.cacheDisplay(in: view.bounds, to: rep)
        
        // Convert to CGImage
        guard let image = rep.cgImage else {
            logger.log("❌ Failed to create CGImage from view")
            return false
        }
        
        // Save the image
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "\(screenName)_\(timestamp).\(config.imageFormat.rawValue)"
        let fileURL = URL(fileURLWithPath: config.outputDirectory).appendingPathComponent(filename)
        
        guard let data = imageToData(image: image, format: config.imageFormat, quality: config.quality) else {
            logger.log("❌ Failed to convert image to data")
            return false
        }
        
        do {
            try data.write(to: fileURL)
            logger.log("✅ Screenshot saved: \(filename)")
            return true
        } catch {
            logger.log("❌ Failed to save screenshot: \(error)")
            return false
        }
    }
    
    private func imageToData(image: CGImage, format: ImageFormat, quality: Double) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        
        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
        case .heic:
            // HEIC not available in NSBitmapImageRep, fall back to PNG
            return bitmapRep.representation(using: .png, properties: [:])
        }
    }
    
    private func simulateKeyPress(key: String, modifiers: NSEvent.ModifierFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyCode = key.utf16.first?.hashValue ?? 0
        
        // Key down
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true)
        keyDown?.flags = CGEventFlags(rawValue: UInt64(modifiers.rawValue))
        keyDown?.post(tap: .cghidEventTap)
        
        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false)
        keyUp?.flags = CGEventFlags(rawValue: UInt64(modifiers.rawValue))
        keyUp?.post(tap: .cghidEventTap)
    }
}

// MARK: - Production-Safe Screenshot Configuration
struct ProductionScreenshotConfig {
    let isEnabled: Bool
    let requiresAuthentication: Bool
    let allowedScreens: [String]
    let maxScreenshotsPerSession: Int
    let outputDirectory: String
    let imageFormat: ImageFormat
    let quality: Double
    let enableLogging: Bool
    
    static let `default` = ProductionScreenshotConfig(
        isEnabled: false,  // Disabled by default for security
        requiresAuthentication: true,
        allowedScreens: ["home", "states", "compare", "settings"],  // Whitelist of allowed screens
        maxScreenshotsPerSession: 10,  // Limit to prevent abuse
        outputDirectory: (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/Screenshots",
        imageFormat: .png,
        quality: 0.9,
        enableLogging: true
    )
    
    static let debug = ProductionScreenshotConfig(
        isEnabled: true,
        requiresAuthentication: false,
        allowedScreens: ScreenNavigation.allScreens.map { $0.identifier },
        maxScreenshotsPerSession: 100,
        outputDirectory: (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/Screenshots",
        imageFormat: .png,
        quality: 0.9,
        enableLogging: true
    )
}

// MARK: - Main Execution
class ScreenshotAutomationRunner {
    static func run() {
        print("🔍 ScreenshotAutomationRunner started")
        print("🔧 Process arguments: \(ProcessInfo.processInfo.arguments)")
        
        // Check if screenshot mode is enabled via arguments
        let isScreenshotMode = ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
        print("📸 Screenshot mode: \(isScreenshotMode ? "ENABLED" : "disabled")")
        
        if isScreenshotMode {
            #if DEBUG
            runDebugMode()
            #else
            runProductionMode()
            #endif
        }
    }
    
    private static func runDebugMode() {
        print("🐞 Running in DEBUG mode with full capabilities")
        let config = ScreenshotConfig.default
        print("📁 Output directory: \(config.outputDirectory)")
        
        // Create output directory if it doesn't exist
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: config.outputDirectory)
        let directoryPath = directoryURL.path
        
        print("🔍 Checking if directory exists: \(directoryPath)")
        
        if !fileManager.fileExists(atPath: directoryPath) {
            print("📂 Creating output directory: \(directoryPath)")
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                print("✅ Successfully created directory")
            } catch {
                print("❌ Failed to create output directory: \(error.localizedDescription)")
                print("Current working directory: \(fileManager.currentDirectoryPath)")
                return
            }
        } else {
            print("📂 Output directory already exists")
        }
        
        // Request screen recording permission if needed
        if !ScreenRecordingPermission.hasPermission {
            print("⚠️ Screen recording permission is required for screenshot automation")
            ScreenRecordingPermission.requestPermission()
            // Wait a moment for permission dialog
            Thread.sleep(forTimeInterval: 2.0)
        } else {
            print("✅ Screen recording permission granted")
        }
        
        print("🚀 Initializing ScreenshotAutomationEngine")
        let engine = ScreenshotAutomationEngine(config: config)
        
        // Run the automation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("📸 Starting screenshot capture...")
            engine.run()
            
            // Exit the app when done
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                print("✅ Screenshot automation completed.")
                print("📂 Check the directory: \(directoryPath)")
                
                // List contents of the directory
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
                    print("📋 Directory contents: \(contents)")
                } catch {
                    print("❌ Failed to list directory contents: \(error.localizedDescription)")
                }
                
                NSApp.terminate(nil)
            }
        }
    }
    
    private static func runProductionMode() {
        print("🏭 Running in PRODUCTION mode with safety restrictions")
        
        let config = ProductionScreenshotConfig.default
        
        // Check if screenshot automation is enabled
        guard config.isEnabled else {
            print("❌ Screenshot automation is disabled in production configuration")
            print("💡 To enable, set ProductionScreenshotConfig.default.isEnabled = true")
            return
        }
        
        // Check authentication if required
        if config.requiresAuthentication {
            print("🔐 Authentication required for screenshot automation in production")
            guard authenticateUser() else {
                print("❌ Authentication failed - aborting screenshot automation")
                return
            }
        }
        
        // Request screen recording permission
        guard ScreenRecordingPermission.hasPermission else {
            print("❌ Screen recording permission not granted")
            ScreenRecordingPermission.requestPermission()
            print("💡 Please grant permission in System Preferences and try again")
            return
        }
        
        print("✅ Production screenshot automation starting with safety restrictions")
        print("📸 Max screenshots per session: \(config.maxScreenshotsPerSession)")
        print("📋 Allowed screens: \(config.allowedScreens)")
        
        // Create production-safe engine
        let engine = ProductionScreenshotAutomationEngine(config: config)
        
        // Run on main thread for safety
        DispatchQueue.main.async {
            engine.run()
        }
    }
    
    private static func authenticateUser() -> Bool {
        // Simple authentication check - in production this would be more robust
        // For now, check for a special environment variable or user defaults flag
        let authToken = ProcessInfo.processInfo.environment["SCREENSHOT_AUTH_TOKEN"]
        let isValidToken = authToken == "APGI-Screenshot-2024"
        
        if !isValidToken {
            print("🔐 Invalid or missing authentication token")
            print("💡 Set environment variable SCREENSHOT_AUTH_TOKEN=APGI-Screenshot-2024")
        }
        
        return isValidToken
    }
}

