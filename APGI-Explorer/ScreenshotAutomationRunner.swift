import AppKit
import Foundation
import os.log

// MARK: - Main Execution

class ScreenshotAutomationRunner {
  static func run() {
    os_log("🔍 ScreenshotAutomationRunner started")
    os_log("📅 Date: %@", Date().description)
    os_log("🖥️ macOS Version: %@", ProcessInfo.processInfo.operatingSystemVersionString)

    // Check if we're in a safe environment
    let currentEnvironment = self.getCurrentEnvironment()
    os_log("🌍 Environment: %@", currentEnvironment.displayName)

    if currentEnvironment == .production {
      self.runProductionMode()
    } else {
      self.runDevelopmentMode()
    }
  }

  private static func getCurrentEnvironment() -> ScreenshotEnvironment {
    // Check environment variables
    if let envVar = ProcessInfo.processInfo.environment["APGI_ENVIRONMENT"] {
      return ScreenshotEnvironment(rawValue: envVar.lowercased()) ?? .production
    }

    // Check build configuration
    #if DEBUG
      return .development
    #elseif STAGING
      return .staging
    #else
      return .production
    #endif
  }

  private static func runDevelopmentMode() {
    os_log("🛠️ Running in DEVELOPMENT mode")

    // Check screen recording permission
    guard ScreenRecordingPermission.hasPermission else {
      os_log("❌ Screen recording permission not granted")
      ScreenRecordingPermission.requestPermission()
      os_log("💡 Please grant permission in System Preferences and try again")
      return
    }

    os_log("✅ Screen recording permission granted")

    // Create configuration
    let config = ScreenshotConfig.default

    // Create logger
    let logger = Logger(enabled: config.enableLogging)

    // Create components
    let accessibilityManager = ScreenshotAccessibilityManager(logger: logger)
    let navigator = ScreenNavigator(accessibilityManager: accessibilityManager, logger: logger)
    let engine = ScreenshotAutomationEngine(config: config, logger: logger, navigator: navigator)

    os_log("🚀 Starting screenshot automation in development mode")
    os_log("📊 Output directory: %@", config.outputDirectory)
    os_log(
      "🎨 Appearance modes: %@", config.appearanceModes.map(\.displayName).joined(separator: ", "))
    os_log("📱 Resolutions: %@", config.resolutions.map(\.displayName).joined(separator: ", "))

    // Run automation
    engine.run()
  }

  private static func runProductionMode() {
    os_log("🏭 Running in PRODUCTION mode with safety restrictions")

    let config = ProductionScreenshotConfig.default

    // Check if screenshot automation is enabled
    guard config.isEnabled else {
      os_log("❌ Screenshot automation is disabled in production configuration")
      os_log("💡 To enable, set ProductionScreenshotConfig.default.isEnabled = true")
      return
    }

    // Check authentication if required
    if config.requiresAuthentication {
      os_log("🔐 Authentication required for screenshot automation in production")
      guard self.authenticateUser() else {
        os_log("❌ Authentication failed - aborting screenshot automation")
        return
      }
    }

    // Request screen recording permission
    guard ScreenRecordingPermission.hasPermission else {
      os_log("❌ Screen recording permission not granted")
      ScreenRecordingPermission.requestPermission()
      os_log("💡 Please grant permission in System Preferences and try again")
      return
    }

    os_log("✅ Production screenshot automation starting with safety restrictions")
    os_log("📸 Max screenshots per session: %d", config.maxScreenshotsPerSession)
    os_log("📋 Allowed screens: %@", config.allowedScreens.joined(separator: ", "))

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
      os_log("🔐 Invalid or missing authentication token")
      os_log("💡 Set environment variable SCREENSHOT_AUTH_TOKEN=APGI-Screenshot-2024")
    }

    return isValidToken
  }
}

// MARK: - Command Line Interface

extension ScreenshotAutomationRunner {
  static func runWithArguments(_ arguments: [String]) {
    os_log("📝 Processing command line arguments: %@", arguments)

    let (config, productionMode) = self.parseArguments(arguments)

    if productionMode {
      self.runProductionMode()
    } else {
      self.runWithCustomConfig(config)
    }
  }

  private static func parseArguments(_ arguments: [String]) -> (
    config: ScreenshotConfig, productionMode: Bool
  ) {
    var config = ScreenshotConfig.default
    var productionMode = false

    for (index, argument) in arguments.enumerated() {
      switch argument {
      case "--screenshot-mode":
        continue
      case "--production":
        productionMode = true
        os_log("🏭 Production mode enabled")
      case "--output-dir":
        config = self.handleOutputDirectory(config, arguments: arguments, index: index)
      case "--format":
        config = self.handleFormat(config, arguments: arguments, index: index)
      case "--quality":
        config = self.handleQuality(config, arguments: arguments, index: index)
      case "--help", "-h":
        self.printHelp()
        return (config, productionMode)
      default:
        if argument.hasPrefix("--") {
          os_log("⚠️ Unknown argument: %@", argument)
        }
      }
    }

    return (config, productionMode)
  }

  private static func handleOutputDirectory(
    _ config: ScreenshotConfig, arguments: [String], index: Int
  ) -> ScreenshotConfig {
    var newConfig = config
    if index + 1 < arguments.count {
      newConfig.outputDirectory = arguments[index + 1]
      os_log("📁 Custom output directory: %@", newConfig.outputDirectory)
    }
    return newConfig
  }

  private static func handleFormat(_ config: ScreenshotConfig, arguments: [String], index: Int)
    -> ScreenshotConfig {
    var newConfig = config
    if index + 1 < arguments.count {
      let formatString = arguments[index + 1]
      if let format = ImageFormat(rawValue: formatString) {
        newConfig.imageFormat = format
        os_log("🖼️ Custom format: %@", format.rawValue)
      }
    }
    return newConfig
  }

  private static func handleQuality(_ config: ScreenshotConfig, arguments: [String], index: Int)
    -> ScreenshotConfig {
    var newConfig = config
    if index + 1 < arguments.count {
      let qualityString = arguments[index + 1]
      if let quality = Double(qualityString) {
        newConfig.quality = max(0.1, min(1.0, quality))
        os_log("🎨 Custom quality: %f", newConfig.quality)
      }
    }
    return newConfig
  }

  private static func runWithCustomConfig(_ config: ScreenshotConfig) {
    os_log("🛠️ Running with custom configuration")

    // Check screen recording permission
    guard ScreenRecordingPermission.hasPermission else {
      os_log("❌ Screen recording permission not granted")
      ScreenRecordingPermission.requestPermission()
      os_log("💡 Please grant permission in System Preferences and try again")
      return
    }

    // Create logger
    let logger = Logger(enabled: config.enableLogging)

    // Create components
    let accessibilityManager = ScreenshotAccessibilityManager(logger: logger)
    let navigator = ScreenNavigator(accessibilityManager: accessibilityManager, logger: logger)
    let engine = ScreenshotAutomationEngine(config: config, logger: logger, navigator: navigator)

    os_log("🚀 Starting screenshot automation with custom configuration")

    // Run automation
    engine.run()
  }

  private static func printHelp() {
    os_log(
      """
      📸 APGI Explorer Screenshot Automation

      USAGE:
        xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode [OPTIONS]

      OPTIONS:
        --screenshot-mode          Enable screenshot automation mode
        --production               Run in production mode with safety restrictions
        --output-dir <path>        Custom output directory for screenshots
        --format <format>          Image format (png, jpeg, heic)
        --quality <0.0-1.0>       Image quality (0.1 to 1.0)
        --help, -h                 Show this help message

      EXAMPLES:
        # Run with default settings
        xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode

        # Run in production mode
        xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode --production

        # Custom output directory and format
        xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode \
          --output-dir ~/Desktop/Screenshots --format jpeg

        # High quality PNGs
        xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode --format png --quality 1.0

      ENVIRONMENT VARIABLES:
        SCREENSHOT_AUTH_TOKEN      Authentication token for production mode
        APGI_ENVIRONMENT          Environment (development, staging, production)

      For more information, see the documentation.
      """)
  }
}
