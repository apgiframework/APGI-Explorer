import Foundation
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Accessibility
import ScreenCaptureKit
import os.log

// MARK: - Screenshot Automation Engine
class ScreenshotAutomationEngine {
    private let config: ScreenshotConfig
    private let logger: Logger
    private let navigator: ScreenNavigator
    private var screenshotCaptureOverride: ((String) -> Bool)?

    init(config: ScreenshotConfig, logger: Logger, navigator: ScreenNavigator) {
        self.config = config
        self.logger = logger
        self.navigator = navigator
    }

    /// Set a custom screenshot capture override (used by production engine)
    func setScreenshotCaptureOverride(_ override: @escaping (String) -> Bool) {
        self.screenshotCaptureOverride = override
    }

    /// Run the complete screenshot automation
    func run() {
        logger.log("🚀 Starting screenshot automation")
        logger.log("📊 Configuration: \(config.imageFormat.rawValue), \(config.appearanceModes.count) modes, \(config.resolutions.count) resolutions")

        // Validate configuration
        guard validateConfiguration() else {
            logger.logError("❌ Configuration validation failed")
            return
        }

        // Create output directory
        guard createOutputDirectory() else {
            logger.logError("❌ Failed to create output directory")
            return
        }

        var totalScreenshots = 0
        var successfulScreenshots = 0

        // Iterate through all screens
        for screen in ScreenNavigation.allScreens {
            if !shouldCaptureScreen(screen) {
                logger.log("⏭️ Skipping screen: \(screen.name)")
                continue
            }

            // Navigate to screen
            guard navigator.navigate(to: screen) else {
                logger.logError("❌ Failed to navigate to screen: \(screen.name)")
                continue
            }

            // Capture screenshots for this screen
            let screenScreenshots = captureScreenshotsForScreen(screen)
            totalScreenshots += screenScreenshots.total
            successfulScreenshots += screenScreenshots.successful

            // Wait between screens
            if config.delayBetweenScreens > 0 {
                Thread.sleep(forTimeInterval: config.delayBetweenScreens)
            }
        }

        // Generate report
        generateReport(totalScreenshots: totalScreenshots, successful: successfulScreenshots)

        logger.logSuccess("✅ Screenshot automation completed")
        logger.log("📊 Results: \(successfulScreenshots)/\(totalScreenshots) screenshots captured")
    }

    private func validateConfiguration() -> Bool {
        // Check output directory
        _ = URL(fileURLWithPath: config.outputDirectory)
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: config.outputDirectory, isDirectory: &isDirectory)

        if exists && !isDirectory.boolValue {
            logger.logError("❌ Output path exists but is not a directory: \(config.outputDirectory)")
            return false
        }

        // Check quality range
        if config.quality < 0.1 || config.quality > 1.0 {
            logger.logError("❌ Quality must be between 0.1 and 1.0, got: \(config.quality)")
            return false
        }

        // Check delay
        if config.delayBetweenScreens < 0 {
            logger.logError("❌ Delay cannot be negative: \(config.delayBetweenScreens)")
            return false
        }

        // Check max retries
        if config.maxRetries < 0 || config.maxRetries > 10 {
            logger.logError("❌ Max retries must be between 0 and 10, got: \(config.maxRetries)")
            return false
        }

        logger.log("✅ Configuration validation passed")
        return true
    }

    private func createOutputDirectory() -> Bool {
        let outputDir = URL(fileURLWithPath: config.outputDirectory)

        do {
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            logger.log("✅ Output directory created: \(config.outputDirectory)")
            return true
        } catch {
            logger.logError("❌ Failed to create output directory: \(error)")
            return false
        }
    }

    private func shouldCaptureScreen(_ screen: ScreenNavigation) -> Bool {
        // Check if screen is in custom screen paths
        if !config.customScreenPaths.isEmpty {
            return config.customScreenPaths.contains { $0.name == screen.name }
        }

        // Otherwise, capture all screens
        return true
    }

    private func captureScreenshotsForScreen(_ screen: ScreenNavigation) -> (total: Int, successful: Int) {
        logger.log("📸 Capturing screenshots for screen: \(screen.name)")

        var total = 0
        var successful = 0

        // Iterate through appearance modes
        for appearanceMode in config.appearanceModes {
            // Set appearance mode
            setAppearanceMode(appearanceMode)
            Thread.sleep(forTimeInterval: 1.0) // Wait for appearance change

            // Iterate through resolutions
            for resolution in config.resolutions {
                // Set resolution
                setResolution(resolution)
                Thread.sleep(forTimeInterval: 0.5) // Wait for resolution change

                // Capture screenshot
                let screenshotName = generateScreenshotName(screen: screen, appearance: appearanceMode, resolution: resolution)

                if captureScreenshot(named: screenshotName) {
                    successful += 1
                }
                total += 1

                // Small delay between captures
                Thread.sleep(forTimeInterval: 0.2)
            }
        }

        logger.log("📊 Screen results: \(successful)/\(total) screenshots captured")
        return (total: total, successful: successful)
    }

    private func setAppearanceMode(_ mode: AppearanceMode) {
        logger.log("🎨 Setting appearance mode: \(mode.displayName)")

        switch mode {
        case .light:
            // Set light mode
            DispatchQueue.main.async {
                NSApp.appearance = NSAppearance(named: .aqua)
            }
        case .dark:
            // Set dark mode
            DispatchQueue.main.async {
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        case .auto:
            // Set auto mode
            DispatchQueue.main.async {
                NSApp.appearance = nil
            }
        }
    }

    private func setResolution(_ resolution: Resolution) {
        logger.log("📱 Setting resolution: \(resolution.displayName)")

        // Resolution setting would depend on the specific requirements
        // This is a placeholder for resolution implementation
    }

    private func generateScreenshotName(screen: ScreenNavigation, appearance: AppearanceMode, resolution: Resolution) -> String {
        var name = screen.screenshotName

        if config.appearanceModes.count > 1 {
            name += "_\(appearance.rawValue)"
        }

        if config.resolutions.count > 1 {
            name += "_\(resolution.rawValue)"
        }

        return name
    }

    private func captureScreenshot(named screenshotName: String) -> Bool {
        // Use override if provided (for production safety)
        if let override = screenshotCaptureOverride {
            return override(screenshotName)
        }

        logger.log("📸 Capturing screenshot: \(screenshotName)")

        var retryCount = 0
        while retryCount < config.maxRetries {
            if doCaptureScreenshot(named: screenshotName) {
                return true
            }

            retryCount += 1
            if retryCount < config.maxRetries {
                logger.log("⚠️ Screenshot failed, retrying... (\(retryCount)/\(config.maxRetries))")
                Thread.sleep(forTimeInterval: 1.0)
            }
        }

        logger.logError("❌ Failed to capture screenshot after \(config.maxRetries) retries: \(screenshotName)")
        return false
    }

    private func doCaptureScreenshot(named screenshotName: String) -> Bool {
        // Capture screenshot using ScreenCaptureKit or alternative method
        guard let screenshot = captureScreenImage() else {
            logger.logError("❌ Failed to capture screen image")
            return false
        }

        // Save screenshot
        let fileName = "\(screenshotName).\(config.imageFormat.fileExtension)"
        let filePath = URL(fileURLWithPath: config.outputDirectory).appendingPathComponent(fileName)

        guard saveScreenshot(screenshot, to: filePath) else {
            logger.logError("❌ Failed to save screenshot: \(fileName)")
            return false
        }

        logger.logSuccess("✅ Screenshot saved: \(fileName)")
        return true
    }

    private func captureScreenImage() -> NSImage? {
        // Implementation would use ScreenCaptureKit or CGScreenCapture
        // This is a placeholder implementation
        return nil
    }

    private func saveScreenshot(_ image: NSImage, to url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return false
        }

        let imageData: Data?

        switch config.imageFormat {
        case .png:
            imageData = bitmapImage.representation(using: .png, properties: [:])
        case .jpeg:
            let properties = [NSBitmapImageRep.PropertyKey.init(rawValue: "NSImageCompressionFactor"): config.quality]
            imageData = bitmapImage.representation(using: .jpeg, properties: properties)
        case .heic:
            // HEIC support would require additional implementation
            imageData = bitmapImage.representation(using: .png, properties: [:])
        }

        guard let data = imageData else {
            return false
        }

        do {
            try data.write(to: url)
            return true
        } catch {
            logger.logError("❌ Failed to write screenshot data: \(error)")
            return false
        }
    }

    private func generateReport(totalScreenshots: Int, successful: Int) {
        logger.log("📋 Generating screenshot report")

        let report = ScreenshotReport(
            totalScreenshots: totalScreenshots,
            successfulScreenshots: successful,
            config: config,
            timestamp: Date(),
            outputPath: config.outputDirectory
        )

        let reportPath = URL(fileURLWithPath: config.outputDirectory).appendingPathComponent("screenshot_report.json")

        do {
            let reportData = try JSONEncoder().encode(report)
            try reportData.write(to: reportPath)
            logger.logSuccess("✅ Report generated: \(reportPath.path)")
        } catch {
            logger.logError("❌ Failed to generate report: \(error)")
        }
    }
}

// MARK: - Screenshot Report
struct ScreenshotReport: Codable {
    let totalScreenshots: Int
    let successfulScreenshots: Int
    let config: ScreenshotConfig
    let timestamp: Date
    let outputPath: String

    var successRate: Double {
        guard totalScreenshots > 0 else { return 0.0 }
        return Double(successfulScreenshots) / Double(totalScreenshots)
    }

    var duration: TimeInterval {
        // This would be calculated based on actual timing
        return 0.0
    }
}
