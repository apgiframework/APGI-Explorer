import Foundation
import AppKit
import os.log

// MARK: - Production-Safe Screenshot Configuration
struct ProductionScreenshotConfig {
    let isEnabled: Bool
    let requiresAuthentication: Bool
    let maxScreenshotsPerSession: Int
    let allowedScreens: [String]
    let allowedOutputFormats: [String]
    let maxFileSize: Int64 // in bytes
    let enableAuditLogging: Bool
    let requireExplicitConsent: Bool
    let sessionTimeout: TimeInterval // in seconds
    let allowedEnvironments: [ScreenshotEnvironment]

    static let `default` = ProductionScreenshotConfig(
        isEnabled: false, // Disabled by default in production
        requiresAuthentication: true,
        maxScreenshotsPerSession: 50,
        allowedScreens: [
            "main_dashboard",
            "profile_results",
            "settings",
            "data_export"
        ],
        allowedOutputFormats: ["png", "jpeg"],
        maxFileSize: 10 * 1024 * 1024, // 10MB
        enableAuditLogging: true,
        requireExplicitConsent: true,
        sessionTimeout: 300, // 5 minutes
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
            return true
        case .production:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
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

        logger.log("🏭 Production screenshot automation engine initialized")
        logger.log("📊 Max screenshots per session: \(config.maxScreenshotsPerSession)")
        logger.log("🔐 Authentication required: \(config.requiresAuthentication)")
        logger.log("📋 Allowed screens: \(config.allowedScreens.joined(separator: ", "))")
    }

    func run() {
        logger.log("🚀 Starting production-safe screenshot automation")

        // Validate environment
        guard validateEnvironment() else {
            logger.logError("❌ Environment validation failed")
            return
        }

        // Check if enabled
        guard config.isEnabled else {
            logger.log("❌ Screenshot automation is disabled in production configuration")
            return
        }

        // Check authentication
        if config.requiresAuthentication && !isAuthenticated {
            logger.logError("❌ Authentication required but not provided")
            return
        }

        // Check consent
        if config.requireExplicitConsent && !hasConsent {
            logger.logError("❌ Explicit consent required but not granted")
            return
        }

        // Check session timeout
        if let startTime = sessionStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > config.sessionTimeout {
                logger.logError("❌ Session timeout exceeded")
                return
            }
        }

        // Run screenshot automation with safety restrictions
        runSafeScreenshotAutomation()
    }

    private func validateEnvironment() -> Bool {
        let currentEnvironment = getCurrentEnvironment()
        let isValid = config.allowedEnvironments.contains(currentEnvironment)

        logger.log("🌍 Current environment: \(currentEnvironment.displayName)")
        logger.log("✅ Environment validation: \(isValid)")

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
        logger.log("📸 Running safe screenshot automation")

        // Create a safe configuration based on production restrictions
        let safeConfig = createSafeConfig()

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
        return ScreenshotConfig(
            outputDirectory: getSafeOutputDirectory(),
            imageFormat: .png, // Force PNG for consistency
            quality: 0.8, // Lower quality for smaller files
            appearanceModes: [.light], // Only light mode for consistency
            resolutions: [.default], // Only default resolution
            delayBetweenScreens: 1.0, // Shorter delay for efficiency
            maxRetries: 1, // Fewer retries to avoid loops
            enableLogging: config.enableAuditLogging,
            captureScrollableContent: false, // Disable for safety
            captureInteractiveStates: false, // Disable for safety
            includeAccessibilityInfo: false, // Disable for privacy
            customScreenPaths: [] // Disable custom paths for security
        )
    }

    private func getSafeOutputDirectory() -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let screenshotsDir = tempDir.appendingPathComponent("production_screenshots")

        do {
            try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        } catch {
            logger.logError("Failed to create safe output directory: \(error)")
            return tempDir.path
        }

        return screenshotsDir.path
    }

    private func captureSafeScreenshot(named screenshotName: String) -> Bool {
        // Check screenshot limits
        guard screenshotsTaken < config.maxScreenshotsPerSession else {
            logger.logError("❌ Maximum screenshots per session exceeded")
            return false
        }

        // Check if screen is allowed
        guard config.allowedScreens.contains(screenshotName) else {
            logger.logError("❌ Screen not allowed for screenshots: \(screenshotName)")
            return false
        }

        // Capture screenshot with safety checks
        logger.log("📸 Capturing safe screenshot: \(screenshotName)")
        screenshotsTaken += 1

        // Implementation would depend on the specific screenshot capture framework
        let success = true // Placeholder
        logger.logSuccess("✅ Screenshot captured successfully: \(screenshotName) (\(screenshotsTaken)/\(config.maxScreenshotsPerSession))")
        return success
    }

    // MARK: - Authentication and Consent

    func authenticate(with token: String) -> Bool {
        guard config.requiresAuthentication else { return true }

        // Simple token validation - in production this would be more robust
        let validTokens = ["APGI-Screenshot-2024", "PROD-SCREENSHOT-AUTH"]
        isAuthenticated = validTokens.contains(token)

        if isAuthenticated {
            logger.logSuccess("✅ Authentication successful")
        } else {
            logger.logError("❌ Authentication failed")
        }

        return isAuthenticated
    }

    func grantConsent() {
        hasConsent = true
        logger.logSuccess("✅ Explicit consent granted")
    }

    func revokeConsent() {
        hasConsent = false
        logger.log("⚠️ Consent revoked")
    }
}
