import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    // Auto-update can be implemented via:
    // - Sparkle framework (https://sparkle-project.org) for direct distribution
    // - App Store Connect for Mac App Store distribution
    // - Custom update checking via GitHub Releases API
    // Note: Implementation choice depends on distribution channel
  }

  func applicationWillTerminate(_: Notification) {
    // Cleanup if needed
    // - Cancel any ongoing background tasks
    // - Save application state
    // - Close database connections gracefully
  }
}
