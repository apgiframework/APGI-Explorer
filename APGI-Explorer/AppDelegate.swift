import Cocoa

// import Sparkle  // TODO: Add Sparkle framework dependency for auto-updates

class AppDelegate: NSObject, NSApplicationDelegate {
    // var updaterController: SPUStandardUpdaterController?  // TODO: Enable when Sparkle is added

    func applicationDidFinishLaunching(_: Notification) {
        // TODO: Initialize Sparkle updater when dependency is added
        // self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    func applicationWillTerminate(_: Notification) {
        // Cleanup if needed
    }
}
