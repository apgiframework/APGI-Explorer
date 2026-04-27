import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    self.checkForUpdatesIfConfigured()
  }

  func applicationWillTerminate(_: Notification) {
    // Cleanup if needed
  }

  // MARK: - Updates

  private func checkForUpdatesIfConfigured() {
    guard
      let feedURLString = Bundle.main.object(forInfoDictionaryKey: "AppUpdateFeedURL") as? String,
      let feedURL = URL(string: feedURLString)
    else {
      return
    }

    let request = URLRequest(
      url: feedURL,
      cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
      timeoutInterval: 10
    )

    URLSession.shared.dataTask(with: request) { data, _, error in
      guard error == nil, let data else { return }

      guard
        let versionString = String(data: data, encoding: .utf8)?
          .trimmingCharacters(in: .whitespacesAndNewlines),
        !versionString.isEmpty
      else {
        return
      }

      let currentVersion =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

      guard self.isVersion(versionString, newerThan: currentVersion) else { return }

      DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText =
          "A newer version (\(versionString)) is available. Visit the project site to download the latest build."
        alert.addButton(withTitle: "Open Website")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn,
          let websiteURL = URL(string: "https://lesoto.github.io/APGI-Explorer") {
          NSWorkspace.shared.open(websiteURL)
        }
      }
    }.resume()
  }

  private func isVersion(_ candidate: String, newerThan baseline: String) -> Bool {
    candidate.compare(baseline, options: .numeric) == .orderedDescending
  }
}
