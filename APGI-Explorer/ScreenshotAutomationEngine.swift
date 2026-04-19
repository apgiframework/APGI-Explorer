import Accessibility
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import ScreenCaptureKit
import UniformTypeIdentifiers
import os.log

// MARK: - Screenshot Automation Engine

class ScreenshotAutomationEngine {
  private let config: ScreenshotConfig
  private let logger: Logger
  private let navigator: ScreenNavigator
  private var screenshotCaptureOverride: ((String) -> Bool)?
  private var activeResolutionScale: CGFloat = 1.0

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
    self.logger.log("🚀 Starting screenshot automation")
    self.logger.log(
      "📊 Configuration: \(self.config.imageFormat.rawValue), \(self.config.appearanceModes.count) modes, \(self.config.resolutions.count) resolutions"
    )

    // Validate configuration
    guard self.validateConfiguration() else {
      self.logger.logError("❌ Configuration validation failed")
      return
    }

    // Create output directory
    guard self.createOutputDirectory() else {
      self.logger.logError("❌ Failed to create output directory")
      return
    }

    var totalScreenshots = 0
    var successfulScreenshots = 0

    // Iterate through all screens
    for screen in ScreenNavigation.allScreens {
      if !self.shouldCaptureScreen(screen) {
        self.logger.log("⏭️ Skipping screen: \(screen.name)")
        continue
      }

      // Navigate to screen
      guard self.navigator.navigate(to: screen) else {
        self.logger.logError("❌ Failed to navigate to screen: \(screen.name)")
        continue
      }

      // Capture screenshots for this screen
      let screenScreenshots = self.captureScreenshotsForScreen(screen)
      totalScreenshots += screenScreenshots.total
      successfulScreenshots += screenScreenshots.successful

      // Wait between screens
      if self.config.delayBetweenScreens > 0 {
        Thread.sleep(forTimeInterval: self.config.delayBetweenScreens)
      }
    }

    // Generate report
    self.generateReport(totalScreenshots: totalScreenshots, successful: successfulScreenshots)

    self.logger.logSuccess("✅ Screenshot automation completed")
    self.logger.log("📊 Results: \(successfulScreenshots)/\(totalScreenshots) screenshots captured")
  }

  private func validateConfiguration() -> Bool {
    // Check output directory
    _ = URL(fileURLWithPath: self.config.outputDirectory)
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(
      atPath: self.config.outputDirectory, isDirectory: &isDirectory)

    if exists && !isDirectory.boolValue {
      self.logger.logError(
        "❌ Output path exists but is not a directory: \(self.config.outputDirectory)")
      return false
    }

    // Check quality range
    if self.config.quality < 0.1 || self.config.quality > 1.0 {
      self.logger.logError("❌ Quality must be between 0.1 and 1.0, got: \(self.config.quality)")
      return false
    }

    // Check delay
    if self.config.delayBetweenScreens < 0 {
      self.logger.logError("❌ Delay cannot be negative: \(self.config.delayBetweenScreens)")
      return false
    }

    // Check max retries
    if self.config.maxRetries < 0 || self.config.maxRetries > 10 {
      self.logger.logError("❌ Max retries must be between 0 and 10, got: \(self.config.maxRetries)")
      return false
    }

    self.logger.log("✅ Configuration validation passed")
    return true
  }

  private func createOutputDirectory() -> Bool {
    let outputDir = URL(fileURLWithPath: config.outputDirectory)

    do {
      try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
      self.logger.log("✅ Output directory created: \(self.config.outputDirectory)")
      return true
    } catch {
      self.logger.logError("❌ Failed to create output directory: \(error)")
      return false
    }
  }

  private func shouldCaptureScreen(_ screen: ScreenNavigation) -> Bool {
    // Check if screen is in custom screen paths
    if !self.config.customScreenPaths.isEmpty {
      return self.config.customScreenPaths.contains { $0.name == screen.name }
    }

    // Otherwise, capture all screens
    return true
  }

  private func captureScreenshotsForScreen(_ screen: ScreenNavigation) -> (
    total: Int, successful: Int
  ) {
    self.logger.log("📸 Capturing screenshots for screen: \(screen.name)")

    var total = 0
    var successful = 0

    // Iterate through appearance modes
    for appearanceMode in self.config.appearanceModes {
      // Set appearance mode
      self.setAppearanceMode(appearanceMode)
      Thread.sleep(forTimeInterval: 1.0)  // Wait for appearance change

      // Iterate through resolutions
      for resolution in self.config.resolutions {
        // Set resolution
        self.setResolution(resolution)
        Thread.sleep(forTimeInterval: 0.5)  // Wait for resolution change

        // Capture screenshot
        let screenshotName = self.generateScreenshotName(
          screen: screen, appearance: appearanceMode, resolution: resolution)

        if self.captureScreenshot(named: screenshotName) {
          successful += 1
        }
        total += 1

        // Small delay between captures
        Thread.sleep(forTimeInterval: 0.2)
      }
    }

    self.logger.log("📊 Screen results: \(successful)/\(total) screenshots captured")
    return (total: total, successful: successful)
  }

  private func setAppearanceMode(_ mode: AppearanceMode) {
    self.logger.log("🎨 Setting appearance mode: \(mode.displayName)")

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
    self.logger.log("📱 Setting resolution: \(resolution.displayName)")
    self.activeResolutionScale = max(0.25, min(3.0, resolution.scaleFactor))
  }

  private func generateScreenshotName(
    screen: ScreenNavigation, appearance: AppearanceMode, resolution: Resolution
  ) -> String {
    var name = screen.screenshotName

    if self.config.appearanceModes.count > 1 {
      name += "_\(appearance.rawValue)"
    }

    if self.config.resolutions.count > 1 {
      name += "_\(resolution.rawValue)"
    }

    return name
  }

  private func captureScreenshot(named screenshotName: String) -> Bool {
    // Use override if provided (for production safety)
    if let override = screenshotCaptureOverride {
      return override(screenshotName)
    }

    self.logger.log("📸 Capturing screenshot: \(screenshotName)")

    var retryCount = 0
    while retryCount < self.config.maxRetries {
      if self.doCaptureScreenshot(named: screenshotName) {
        return true
      }

      retryCount += 1
      if retryCount < self.config.maxRetries {
        self.logger.log(
          "⚠️ Screenshot failed, retrying... (\(retryCount)/\(self.config.maxRetries))")
        Thread.sleep(forTimeInterval: 1.0)
      }
    }

    self.logger.logError(
      "❌ Failed to capture screenshot after \(self.config.maxRetries) retries: \(screenshotName)")
    return false
  }

  private func doCaptureScreenshot(named screenshotName: String) -> Bool {
    // Capture screenshot using ScreenCaptureKit or alternative method
    guard let screenshot = captureScreenImage() else {
      self.logger.logError("❌ Failed to capture screen image")
      return false
    }

    // Save screenshot
    let fileName = "\(screenshotName).\(config.imageFormat.fileExtension)"
    let filePath = URL(fileURLWithPath: config.outputDirectory).appendingPathComponent(fileName)

    guard self.saveScreenshot(screenshot, to: filePath) else {
      self.logger.logError("❌ Failed to save screenshot: \(fileName)")
      return false
    }

    self.logger.logSuccess("✅ Screenshot saved: \(fileName)")
    return true
  }

  private func captureScreenImage() -> NSImage? {
    let displayID = CGMainDisplayID()
    let displayBounds = CGDisplayBounds(displayID)

    guard
      let cgImage = CGWindowListCreateImage(
        displayBounds,
        .optionOnScreenOnly,
        kCGNullWindowID,
        [.bestResolution, .boundsIgnoreFraming]
      )
    else {
      return nil
    }

    let baseImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

    guard self.activeResolutionScale != 1.0 else {
      return baseImage
    }

    let targetSize = NSSize(
      width: max(1, floor(baseImage.size.width * self.activeResolutionScale)),
      height: max(1, floor(baseImage.size.height * self.activeResolutionScale))
    )

    let resized = NSImage(size: targetSize)
    resized.lockFocus()
    baseImage.draw(in: NSRect(origin: .zero, size: targetSize))
    resized.unlockFocus()
    return resized
  }

  private func saveScreenshot(_ image: NSImage, to url: URL) -> Bool {
    guard let tiffData = image.tiffRepresentation,
      let bitmapImage = NSBitmapImageRep(data: tiffData)
    else {
      return false
    }

    let imageData: Data?

    switch self.config.imageFormat {
    case .png:
      imageData = bitmapImage.representation(using: .png, properties: [:])
    case .jpeg:
      let properties = [
        NSBitmapImageRep.PropertyKey(rawValue: "NSImageCompressionFactor"): self.config.quality
      ]
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
      self.logger.logError("❌ Failed to write screenshot data: \(error)")
      return false
    }
  }

  private func generateReport(totalScreenshots: Int, successful: Int) {
    self.logger.log("📋 Generating screenshot report")

    let report = ScreenshotReport(
      totalScreenshots: totalScreenshots,
      successfulScreenshots: successful,
      config: config,
      timestamp: Date(),
      outputPath: config.outputDirectory
    )

    let reportPath = URL(fileURLWithPath: config.outputDirectory).appendingPathComponent(
      "screenshot_report.json")

    do {
      let reportData = try JSONEncoder().encode(report)
      try reportData.write(to: reportPath)
      self.logger.logSuccess("✅ Report generated: \(reportPath.path)")
    } catch {
      self.logger.logError("❌ Failed to generate report: \(error)")
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
    guard self.totalScreenshots > 0 else { return 0.0 }
    return Double(self.successfulScreenshots) / Double(self.totalScreenshots)
  }

  var duration: TimeInterval {
    // This would be calculated based on actual timing
    0.0
  }
}
