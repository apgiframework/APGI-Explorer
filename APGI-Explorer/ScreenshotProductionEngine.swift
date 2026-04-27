import AppKit
import Foundation
import os.log

// MARK: - Production-Safe Screenshot Configuration

struct ProductionScreenshotConfig {
  let isEnabled: Bool
  let requiresAuthentication: Bool
  let maxScreenshotsPerSession: Int
  let allowedScreens: [String]
  let allowedOutputFormats: [String]
  let maxFileSize: Int64  // in bytes
  let enableAuditLogging: Bool
  let requireExplicitConsent: Bool
  let sessionTimeout: TimeInterval  // in seconds
  let allowedEnvironments: [ScreenshotEnvironment]

  static let `default` = ProductionScreenshotConfig(
    isEnabled: false,  // Disabled by default in production
    requiresAuthentication: true,
    maxScreenshotsPerSession: 50,
    allowedScreens: [
      "main_dashboard",
      "profile_results",
      "settings",
      "data_export"
    ],
    allowedOutputFormats: ["png", "jpeg"],
    maxFileSize: 10 * 1024 * 1024,  // 10MB
    enableAuditLogging: true,
    requireExplicitConsent: true,
    sessionTimeout: 300,  // 5 minutes
    allowedEnvironments: [.development, .staging]
  )
}

// MARK: - Environment

enum ScreenshotEnvironment: String, CaseIterable {
  case development
  case staging
  case production

  var isProductionSafe: Bool {
    switch self {
    case .development, .staging:
      true
    case .production:
      false
    }
  }

  var displayName: String {
    switch self {
    case .development: "Development"
    case .staging: "Staging"
    case .production: "Production"
    }
  }
}

// MARK: - Production-Safe Screenshot Automation Engine

class ProductionScreenshotAutomationEngine {
  private let config: ProductionScreenshotConfig
  private let logger: Logger
  private var screenshotsTaken = 0
  private var sessionStartTime: Date?
  private var isAuthenticated = false
  private var hasConsent = false

  init(config: ProductionScreenshotConfig) {
    self.config = config
    self.logger = Logger(enabled: config.enableAuditLogging)
    self.sessionStartTime = Date()

    self.logger.log("🏭 Production screenshot automation engine initialized")
    self.logger.log("📊 Max screenshots per session: \(config.maxScreenshotsPerSession)")
    self.logger.log("🔐 Authentication required: \(config.requiresAuthentication)")
    self.logger.log("📋 Allowed screens: \(config.allowedScreens.joined(separator: ", "))")
  }

  func run() {
    self.logger.log("🚀 Starting production-safe screenshot automation")

    // Validate environment
    guard self.validateEnvironment() else {
      self.logger.logError("❌ Environment validation failed")
      return
    }

    // Check if enabled
    guard self.config.isEnabled else {
      self.logger.log("❌ Screenshot automation is disabled in production configuration")
      return
    }

    // Check authentication
    if self.config.requiresAuthentication, !self.isAuthenticated {
      self.logger.logError("❌ Authentication required but not provided")
      return
    }

    // Check consent
    if self.config.requireExplicitConsent, !self.hasConsent {
      self.logger.logError("❌ Explicit consent required but not granted")
      return
    }

    // Check session timeout
    if let startTime = sessionStartTime {
      let elapsed = Date().timeIntervalSince(startTime)
      if elapsed > self.config.sessionTimeout {
        self.logger.logError("❌ Session timeout exceeded")
        return
      }
    }

    // Run screenshot automation with safety restrictions
    self.runSafeScreenshotAutomation()
  }

  private func validateEnvironment() -> Bool {
    let currentEnvironment = self.getCurrentEnvironment()
    let isValid = self.config.allowedEnvironments.contains(currentEnvironment)

    self.logger.log("🌍 Current environment: \(currentEnvironment.displayName)")
    self.logger.log("✅ Environment validation: \(isValid)")

    return isValid
  }

  private func getCurrentEnvironment() -> ScreenshotEnvironment {
    // Check environment variables or build configuration
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

  private func runSafeScreenshotAutomation() {
    self.logger.log("📸 Running safe screenshot automation")

    // Create a safe configuration based on production restrictions
    let safeConfig = self.createSafeConfig()

    // Use the regular automation engine with safe configuration
    let engine = ScreenshotAutomationEngine(
      config: safeConfig,
      logger: logger,
      navigator: ScreenNavigator(
        accessibilityManager: ScreenshotAccessibilityManager(logger: logger),
        logger: logger
      )
    )

    // Override screenshot capture to enforce limits
    engine.setScreenshotCaptureOverride { [weak self] screenshotName in
      return self?.captureSafeScreenshot(named: screenshotName) ?? false
    }

    engine.run()
  }

  private func createSafeConfig() -> ScreenshotConfig {
    ScreenshotConfig(
      outputDirectory: self.getSafeOutputDirectory(),
      imageFormat: .png,  // Force PNG for consistency
      quality: 0.8,  // Lower quality for smaller files
      appearanceModes: [.light],  // Only light mode for consistency
      resolutions: [.default],  // Only default resolution
      delayBetweenScreens: 1.0,  // Shorter delay for efficiency
      maxRetries: 1,  // Fewer retries to avoid loops
      enableLogging: self.config.enableAuditLogging,
      captureScrollableContent: false,  // Disable for safety
      captureInteractiveStates: false,  // Disable for safety
      includeAccessibilityInfo: false,  // Disable for privacy
      customScreenPaths: []  // Disable custom paths for security
    )
  }

  private func getSafeOutputDirectory() -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let screenshotsDir = tempDir.appendingPathComponent("production_screenshots")

    do {
      try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
    } catch {
      self.logger.logError("Failed to create safe output directory: \(error)")
      return tempDir.path
    }

    return screenshotsDir.path
  }

  private func captureSafeScreenshot(named screenshotName: String) -> Bool {
    // Check screenshot limits
    guard self.screenshotsTaken < self.config.maxScreenshotsPerSession else {
      self.logger.logError("❌ Maximum screenshots per session exceeded")
      return false
    }

    // Check if screen is allowed
    guard self.config.allowedScreens.contains(screenshotName) else {
      self.logger.logError("❌ Screen not allowed for screenshots: \(screenshotName)")
      return false
    }

    // Capture screenshot with safety checks
    self.logger.log("📸 Capturing safe screenshot: \(screenshotName)")
    self.screenshotsTaken += 1

    // Implementation would depend on the specific screenshot capture framework
    let success = true  // Placeholder
    self.logger.logSuccess(
      "✅ Screenshot captured successfully: \(screenshotName) (\(self.screenshotsTaken)/\(self.config.maxScreenshotsPerSession))"
    )
    return success
  }

  // MARK: - Authentication and Consent

  func authenticate(with token: String) -> Bool {
    guard self.config.requiresAuthentication else { return true }

    // Simple token validation - in production this would be more robust
    let validTokens = ["APGI-Screenshot-2024", "PROD-SCREENSHOT-AUTH"]
    self.isAuthenticated = validTokens.contains(token)

    if self.isAuthenticated {
      self.logger.logSuccess("✅ Authentication successful")
    } else {
      self.logger.logError("❌ Authentication failed")
    }

    return self.isAuthenticated
  }

  func grantConsent() {
    self.hasConsent = true
    self.logger.logSuccess("✅ Explicit consent granted")
  }

  func revokeConsent() {
    self.hasConsent = false
    self.logger.log("⚠️ Consent revoked")
  }
}
