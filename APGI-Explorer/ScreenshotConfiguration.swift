import Accessibility
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import os.log
import ScreenCaptureKit
import UniformTypeIdentifiers

// MARK: - Screen Recording Permission

enum ScreenRecordingPermission {
    static var hasPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }
}

// MARK: - Configuration

struct ScreenshotConfig: Codable {
    var outputDirectory: String
    var imageFormat: ImageFormat
    var quality: Double
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
        outputDirectory: FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Screenshots").path
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("Screenshots").path,
        imageFormat: .png,
        quality: 0.9,
        appearanceModes: [.light, .dark],
        resolutions: [.default, .large, .small],
        delayBetweenScreens: 2.0,
        maxRetries: 3,
        enableLogging: true,
        captureScrollableContent: true,
        captureInteractiveStates: true,
        includeAccessibilityInfo: false,
        customScreenPaths: []
    )
}

// MARK: - Image Format

enum ImageFormat: String, CaseIterable, Codable {
    case png
    case jpeg
    case heic

    var utType: UTType {
        switch self {
        case .png: .png
        case .jpeg: .jpeg
        case .heic: .heic
        }
    }

    var fileExtension: String {
        rawValue
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Codable {
    case light
    case dark
    case auto

    var displayName: String {
        switch self {
        case .light: "Light Mode"
        case .dark: "Dark Mode"
        case .auto: "Auto Mode"
        }
    }
}

// MARK: - Resolution

enum Resolution: String, CaseIterable, Codable {
    case `default`
    case large
    case small
    case custom

    var scaleFactor: CGFloat {
        switch self {
        case .default: 1.0
        case .large: 2.0
        case .small: 0.5
        case .custom: 1.0
        }
    }

    var displayName: String {
        switch self {
        case .default: "Default"
        case .large: "Large (2x)"
        case .small: "Small (0.5x)"
        case .custom: "Custom"
        }
    }

    /// Returns the CGSize for window resizing based on resolution
    var cgSize: CGSize {
        switch self {
        case .default:
            CGSize(width: 1200, height: 800)
        case .large:
            CGSize(width: 1920, height: 1080)
        case .small:
            CGSize(width: 1024, height: 768)
        case .custom:
            CGSize(width: 1200, height: 800)
        }
    }
}

// MARK: - Custom Screen Path

struct CustomScreenPath: Codable {
    let name: String
    let path: String
    let description: String
    let interactions: [InteractionType]
    let delay: TimeInterval
}

// MARK: - Direction

enum Direction: Codable {
    case upDirection, downDirection, leftDirection, rightDirection
}

// MARK: - Navigation Step

struct NavigationStep: Codable {
    let type: NavigationStepType
    let delay: TimeInterval
}

// MARK: - Navigation Step Type

enum NavigationStepType: Codable {
    case wait(TimeInterval)
    case tapElement(String)
    case tab
    case menu
    case keyboardShortcut(String, ModifierFlags)
    case clickElement(String)
    case swipe(Direction)
    case selectTab
    case longPress
    case completeQuiz
}

// MARK: - Custom Modifier Flags

struct ModifierFlags: Codable {
    let shift: Bool
    let control: Bool
    let option: Bool
    let command: Bool

    init(fromNSEventFlags flags: NSEvent.ModifierFlags) {
        self.shift = flags.contains(.shift)
        self.control = flags.contains(.control)
        self.option = flags.contains(.option)
        self.command = flags.contains(.command)
    }

    func toNSEventFlags() -> NSEvent.ModifierFlags {
        var result: NSEvent.ModifierFlags = []
        if self.shift { result.insert(.shift) }
        if self.control { result.insert(.control) }
        if self.option { result.insert(.option) }
        if self.command { result.insert(.command) }
        return result
    }
}

// MARK: - Interaction Types

enum InteractionType: Codable {
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
    let navigationSteps: [NavigationStep]
    let expectedElements: [String]
    let screenshotName: String
    let description: String

    static let allScreens: [ScreenNavigation] = [
        ScreenNavigation(
            name: "Main Dashboard",
            identifier: "main_dashboard",
            navigationSteps: [],
            expectedElements: ["dashboard_view", "profile_button", "settings_button"],
            screenshotName: "dashboard",
            description: "Main application dashboard showing overview and quick actions"
        ),
        ScreenNavigation(
            name: "Profile Creation",
            identifier: "profile_creation",
            navigationSteps: [
                NavigationStep(type: .tapElement("create_profile_button"), delay: 1.0),
                NavigationStep(type: .wait(2.0), delay: 0.5)
            ],
            expectedElements: ["quiz_view", "question_text", "answer_options"],
            screenshotName: "profile_creation",
            description: "Profile creation quiz interface"
        ),
        ScreenNavigation(
            name: "Profile Results",
            identifier: "profile_results",
            navigationSteps: [
                NavigationStep(type: .completeQuiz, delay: 1.0),
                NavigationStep(type: .wait(3.0), delay: 0.5)
            ],
            expectedElements: ["results_view", "profile_summary", "save_button"],
            screenshotName: "profile_results",
            description: "Profile results and analysis display"
        ),
        ScreenNavigation(
            name: "Profile Comparison",
            identifier: "profile_comparison",
            navigationSteps: [
                NavigationStep(type: .tapElement("compare_profiles"), delay: 1.0),
                NavigationStep(type: .wait(2.0), delay: 0.5)
            ],
            expectedElements: ["comparison_view", "profile_selector", "comparison_chart"],
            screenshotName: "profile_comparison",
            description: "Profile comparison interface"
        ),
        ScreenNavigation(
            name: "Settings",
            identifier: "settings",
            navigationSteps: [
                NavigationStep(type: .tapElement("settings_button"), delay: 1.0),
                NavigationStep(type: .wait(2.0), delay: 0.5)
            ],
            expectedElements: ["settings_view", "preferences_section", "privacy_section"],
            screenshotName: "settings",
            description: "Application settings and preferences"
        ),
        ScreenNavigation(
            name: "Data Export",
            identifier: "data_export",
            navigationSteps: [
                NavigationStep(type: .tapElement("export_button"), delay: 1.0),
                NavigationStep(type: .wait(2.0), delay: 0.5)
            ],
            expectedElements: ["export_view", "format_selector", "export_options"],
            screenshotName: "data_export",
            description: "Data export interface"
        )
    ]
}
