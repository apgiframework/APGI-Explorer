# 📸 Screenshot Automation

Automated screenshot generation system for APGI-Explorer documentation, marketing materials, and testing.

---

## 🚀 Quick Start

### Prerequisites

Before using any screenshot functionality, the app needs **Screen Recording permission**:

```swift
import Foundation

// Check permission
if !ScreenRecordingPermission.hasPermission {
    ScreenRecordingPermission.requestPermission()
    // User must grant in System Settings > Privacy & Security > Screen Recording
}
```

### Method A: Quick Start (Simplest)

Use the convenience function in `ScreenshotAutomation.swift`:

```swift
import Foundation

// Run with default settings (~/Desktop/Screenshots, PNG, Light+Dark modes, multiple resolutions)
quickStartScreenshotAutomation()

// Or specify custom output directory
quickStartScreenshotAutomation(outputDirectory: "/path/to/screenshots")
```

**Default configuration** (`ScreenshotConfig.default`):

| Setting                  | Value                                                      |
|--------------------------|------------------------------------------------------------|
| **Output**               | `~/Desktop/Screenshots`                                    |
| **Format**               | PNG                                                        |
| **Quality**              | 0.9                                                        |
| **Appearance modes**     | Light + Dark                                               |
| **Resolutions**          | Default (1200×800), Large (1920×1080), Small (1024×768)    |
| **Delay between screens**| 2.0 seconds                                                |

---

## ⚙️ Advanced Usage

### Method B: Custom Configuration

Create your own configuration for more control:

```swift
import Foundation

// 1. Create custom config
var config = ScreenshotConfig.default
config.outputDirectory = "/Users/me/AppScreenshots"
config.imageFormat = .jpeg
config.quality = 0.95
config.appearanceModes = [.light]  // Only light mode
config.resolutions = [.large]       // Only large resolution
config.delayBetweenScreens = 1.0
config.enableLogging = true

// 2. Create components
let logger = Logger(enabled: true)
let accessibilityManager = ScreenshotAccessibilityManager(logger: logger)
let navigator = ScreenNavigator(accessibilityManager: accessibilityManager, logger: logger)

// 3. Create and run engine
let engine = ScreenshotAutomationEngine(config: config, logger: logger, navigator: navigator)
engine.run()
```

### Method C: Define Custom Screens to Capture

Configure which screens to capture (defined in `ScreenNavigation.allScreens`):

```swift
import Foundation

// Default screens include:
// - "Main Dashboard" (no navigation steps)
// - "Profile Creation" (taps create_profile_button)
// - "Profile Results" (completes quiz)
// - "Profile Comparison" (taps compare_profiles)
// - "Settings" (taps settings_button)
// - "Data Export" (taps export_button)

// To capture only specific screens:
var config = ScreenshotConfig.default
config.customScreenPaths = [
    CustomScreenPath(
        name: "Settings",
        path: "settings",
        description: "App settings page",
        interactions: [],
        delay: 1.0
    )
]
```

---

## 🖥️ Command Line Interface

The system supports CLI arguments via `ScreenshotAutomationRunner`:

```bash
# Basic screenshot mode
xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode

# Custom output directory and format
xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode \
  --output-dir ~/Desktop/Screenshots --format jpeg --quality 0.9

# Production mode with safety restrictions
xcodebuild -scheme APGI-Explorer run -arguments --screenshot-mode --production
```

### CLI Options

| Option                  | Description                                         |
|-------------------------|-----------------------------------------------------|
| `--screenshot-mode`     | Enable screenshot automation mode                   |
| `--production`          | Run in production mode with safety restrictions     |
| `--output-dir <path>`   | Custom output directory for screenshots             |
| `--format <format>`     | Image format (`png`, `jpeg`, `heic`)                |
| `--quality <0.0-1.0>`   | Image quality (0.1 to 1.0)                          |
| `--help`, `-h`          | Show help message                                   |

---

## 🔒 Production-Safe Mode

For production environments with safety restrictions:

```swift
import Foundation

let config = ProductionScreenshotConfig.default

// Must authenticate and grant consent
let engine = ProductionScreenshotAutomationEngine(config: config)
if engine.authenticate(with: "APGI-Screenshot-2024") {
    engine.grantConsent()
    engine.run()
}
```

**Production restrictions include:**

- ✅ Max 50 screenshots per session
- ✅ Only allowed screens: `main_dashboard`, `profile_results`, `settings`, `data_export`
- ✅ Session timeout: 5 minutes
- ✅ Authentication required

---

## 🔄 How the Engine Works

The `ScreenshotAutomationEngine` follows this workflow:

1. **`run()`** - Main entry point that orchestrates the entire process
2. **`validateConfiguration()`** - Checks output directory, quality range, delays, retries
3. **`createOutputDirectory()`** - Creates output folder if needed
4. **Loop through screens**:
   - For each screen in `ScreenNavigation.allScreens`
   - Navigate using `navigator.navigate(to:)`
   - Capture screenshots for each appearance mode + resolution combination
   - Generate unique filename: `{screenshotName}_{appearance}_{resolution}.{format}`
5. **`captureScreenshot(named:)`** - Captures and saves image
6. **`generateReport()`** - Creates JSON report of all screenshots

### Screenshot Capture Process

1. Find main window with identifier `"main"`
2. Capture window content using `cacheDisplay(in:to:)` (modern macOS 15+ compatible)
3. Save as PNG/JPEG/HEIC to output directory
4. Retry up to `maxRetries` times on failure

---

## 📝 Customizing Screens

To add new screens, edit `ScreenNavigation.allScreens` in `ScreenshotConfiguration.swift`:

```swift
ScreenNavigation(
    name: "My New Screen",
    identifier: "my_screen",
    navigationSteps: [
        NavigationStep(type: .tapElement("my_button"), delay: 1.0),
        NavigationStep(type: .wait(2.0), delay: 0.5)
    ],
    expectedElements: ["expected_view", "another_element"],  // For verification
    screenshotName: "my_screen",
    description: "Description of this screen"
)
```

---

## 📊 Output

All screenshots are saved to the output directory with names like:

```text
dashboard_light_large.png
profile_results_dark_default.png
settings_light_small.png
```

A `screenshot_report.json` is generated with results including:

- Total screenshots attempted
- Successful captures
- Configuration used
- Timestamp
- Success rate

---

## 📝 Summary

| Use Case              | Method                                                  |
|-----------------------|---------------------------------------------------------|
| Quick test            | `quickStartScreenshotAutomation()`                      |
| Custom settings       | Create `ScreenshotConfig` → `ScreenshotAutomationEngine`|
| Specific screens only | Set `config.customScreenPaths`                          |
| CI/CD automation      | CLI with `--screenshot-mode`                            |
| Production deployment | `ProductionScreenshotAutomationEngine` with auth        |

---

## 🔧 Development

### Testing Components

```swift
#if DEBUG
ScreenshotAutomationRunner.debugTestComponents()
#endif
```

This tests:

- Logger functionality
- Configuration loading
- Accessibility manager
- Screen navigator

### Debug Logging

Set `enableLogging = true` in your configuration to get detailed console and file logging during screenshot automation runs.
