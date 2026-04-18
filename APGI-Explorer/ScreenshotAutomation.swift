import Accessibility
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import ScreenCaptureKit
import UniformTypeIdentifiers
import os.log

// MARK: - Screenshot Automation Main Entry Point

// This file serves as the main entry point and imports all screenshot automation components

// Import all screenshot automation modules
// Note: In Swift, files in the same module are automatically available
// The separate files created contain:
// - ScreenshotConfiguration.swift - Configuration and types
// - ScreenshotNavigator.swift - Screen navigation logic
// - ScreenshotAccessibilityManager.swift - Accessibility management
// - ScreenshotLogger.swift - Logging functionality
// - ScreenshotAutomationEngine.swift - Main automation engine
// - ScreenshotProductionEngine.swift - Production-safe engine
// - ScreenshotAutomationRunner.swift - Main execution and CLI

// MARK: - Legacy Compatibility

// These extensions provide backward compatibility with any existing code
// that might reference the original file structure

extension ScreenshotAutomationEngine {
  /// Convenience initializer for legacy compatibility
  convenience init(config: ScreenshotConfig) {
    let logger = Logger(enabled: config.enableLogging)
    let accessibilityManager = ScreenshotAccessibilityManager(logger: logger)
    let navigator = ScreenNavigator(accessibilityManager: accessibilityManager, logger: logger)
    self.init(config: config, logger: logger, navigator: navigator)
  }
}

extension ScreenshotAccessibilityManager {
  /// Legacy method for backward compatibility
  func tapElement(name: String) -> Bool {
    clickElement(withIdentifier: name)
  }
}

// MARK: - Quick Start Functions

/// Quick start function for simple screenshot automation
func quickStartScreenshotAutomation(outputDirectory: String? = nil) {
  let config = ScreenshotConfig.default
  var mutableConfig = config
  if let outputDir = outputDirectory {
    mutableConfig.outputDirectory = outputDir
  }

  let engine = ScreenshotAutomationEngine(config: mutableConfig)
  engine.run()
}

/// Quick start function for production-safe screenshot automation
func quickStartProductionScreenshotAutomation(authToken: String? = nil) {
  let config = ProductionScreenshotConfig.default

  if let token = authToken {
    let engine = ProductionScreenshotAutomationEngine(config: config)
    if engine.authenticate(with: token) {
      engine.grantConsent()
      engine.run()
    }
  } else {
    os_log("🔐 Authentication token required for production mode", log: OSLog.default, type: .info)
    os_log(
      "💡 Provide token or set SCREENSHOT_AUTH_TOKEN environment variable", log: OSLog.default,
      type: .info)
  }
}

// MARK: - Debug Utilities

#if DEBUG
  extension ScreenshotAutomationRunner {
    /// Debug function to test individual components
    static func debugTestComponents() {
      os_log("🧪 Testing screenshot automation components...", log: OSLog.default, type: .info)

      // Test logger
      let logger = Logger(enabled: true)
      logger.log("📝 Logger test successful")

      // Test configuration
      let config = ScreenshotConfig.default
      os_log("✅ Configuration test successful", log: OSLog.default, type: .info)
      os_log(
        "   Output directory: %{public}@", log: OSLog.default, type: .info, config.outputDirectory)
      os_log(
        "   Image format: %{public}@", log: OSLog.default, type: .info, config.imageFormat.rawValue)

      // Test accessibility manager
      let accessibilityManager = ScreenshotAccessibilityManager(logger: logger)
      os_log("✅ Accessibility manager test successful", log: OSLog.default, type: .info)

      // Test navigator
      _ = ScreenNavigator(accessibilityManager: accessibilityManager, logger: logger)
      os_log("✅ Screen navigator test successful", log: OSLog.default, type: .info)

      os_log("🎉 All components tested successfully!", log: OSLog.default, type: .info)
    }
  }
#endif

// MARK: - Entry Point

/// Main entry point for screenshot automation
func startScreenshotAutomation() {
  let arguments = CommandLine.arguments
  if arguments.contains("--screenshot-mode") {
    ScreenshotAutomationRunner.runWithArguments(arguments)
  }
}

// MARK: - Migration Notes

/*
 The original ScreenshotAutomation.swift file has been refactored into multiple
 focused files to address SwiftLint violations:

 - ScreenshotConfiguration.swift - Configuration and types
 - ScreenshotNavigator.swift - Screen navigation logic
 - ScreenshotAccessibilityManager.swift - Accessibility management
 - ScreenshotLogger.swift - Logging functionality
 - ScreenshotAutomationEngine.swift - Main automation engine
 - ScreenshotProductionEngine.swift - Production-safe engine
 - ScreenshotAutomationRunner.swift - Main execution and CLI

 This file now serves as the main entry point with legacy compatibility.
 */
