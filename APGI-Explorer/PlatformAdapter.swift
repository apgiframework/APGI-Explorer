import SwiftUI

// MARK: - Platform Abstraction Layer

enum PlatformAdapter {
  // MARK: - Platform Detection

  static var isMacOS: Bool {
    #if os(macOS)
      return true
    #else
      return false
    #endif
  }

  static var isiOS: Bool {
    #if os(iOS)
      return true
    #else
      return false
    #endif
  }

  static var currentPlatform: Platform {
    #if os(macOS)
      return .macOS
    #elseif os(iOS)
      return .iOS
    #else
      return .unknown
    #endif
  }

  enum Platform {
    case macOS
    case iOS
    case unknown

    var name: String {
      switch self {
      case .macOS: "macOS"
      case .iOS: "iOS"
      case .unknown: "Unknown"
      }
    }
  }

  // MARK: - Window Management

  static func openWindow(type: WindowManager.WindowType, content: @escaping () -> some View) {
    #if os(macOS)
      WindowManager.shared.openWindow(type: type, content: content)
    #else
      // On iOS, we navigate instead of opening new windows
      NotificationCenter.default.post(
        name: .navigateToView,
        object: type,
        userInfo: ["content": content()]
      )
    #endif
  }

  static func minimizeWindow() {
    #if os(macOS)
      NSApp.keyWindow?.miniaturize(nil)
    #endif
  }

  static func zoomWindow() {
    #if os(macOS)
      NSApp.keyWindow?.zoom(nil)
    #endif
  }

  static func toggleFullScreen() {
    #if os(macOS)
      NSApp.keyWindow?.toggleFullScreen(nil)
    #endif
  }

  static func toggleSidebar() {
    #if os(macOS)
      NSApp.keyWindow?.firstResponder?.tryToPerform(
        #selector(NSSplitViewController.toggleSidebar(_:)),
        with: nil
      )
    #endif
  }

  static func quitApp() {
    #if os(macOS)
      NSApplication.shared.terminate(nil)
    #endif
  }

  // MARK: - Navigation

  static var navigationTitleDisplayMode: Int {
    #if os(iOS)
      return 1  // .inline
    #else
      return 0  // .large
    #endif
  }

  // MARK: - Share Functionality

  static func share(items: [Any]) -> some View {
    #if os(macOS)
      return ShareSheet(items: items)
    #else
      return ShareSheet(items: items)
    #endif
  }

  // MARK: - Keyboard Shortcuts

  static func setupKeyboardShortcuts() {
    #if os(macOS)
      // macOS-specific keyboard shortcuts are handled in MenuCommands
    #else
      // iOS-specific keyboard shortcuts can be set up here if needed
    #endif
  }

  // MARK: - Toolbar Configuration

  static func toolbarPlacement() -> ToolbarItemPlacement {
    #if os(macOS)
      return .automatic
    #else
      return .navigationBarTrailing
    #endif
  }

  // MARK: - File Operations

  static func exportToFile(data: Data, filename: String) -> URL? {
    #if os(macOS)
      let panel = NSSavePanel()
      panel.allowedContentTypes = [.pdf, .text, .json]
      panel.nameFieldStringValue = filename

      if panel.runModal() == .OK, let url = panel.url {
        try? data.write(to: url)
        return url
      }
    #else
      let tempDir = FileManager.default.temporaryDirectory
      let fileURL = tempDir.appendingPathComponent(filename)

      try? data.write(to: fileURL)

      let activityViewController = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
      )

      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first
      {
        window.rootViewController?.present(activityViewController, animated: true)
      }

      return fileURL
    #endif

    return nil
  }

  // MARK: - System Integration

  static func openURL(_ url: URL) {
    #if os(macOS)
      NSWorkspace.shared.open(url)
    #else
      UIApplication.shared.open(url)
    #endif
  }

  static func showSettings() {
    #if os(macOS)
      WindowManager.shared.openWindow(type: .settings) {
        SettingsView()
      }
    #else
      // On iOS, navigate to settings
      NotificationCenter.default.post(name: .navigateToSettings, object: nil)
    #endif
  }

  // MARK: - Accessibility

  static func setAccessibilityFocus(to identifier: String) {
    #if canImport(UIKit)
      UIAccessibility.post(notification: .screenChanged, argument: identifier)
    #endif
  }

  // MARK: - Performance Optimizations

  static var preferredCacheSize: Int {
    switch currentPlatform {
    case .macOS:
      200  // More memory available on macOS
    case .iOS:
      50  // Conservative on iOS
    case .unknown:
      100
    }
  }

  static var maxConcurrentOperations: Int {
    switch currentPlatform {
    case .macOS:
      ProcessInfo.processInfo.processorCount
    case .iOS:
      min(4, ProcessInfo.processInfo.processorCount)
    case .unknown:
      2
    }
  }

  // MARK: - UI Adaptations

  static var defaultPadding: EdgeInsets {
    switch currentPlatform {
    case .macOS:
      EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    case .iOS:
      EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    case .unknown:
      EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }
  }

  static var cornerRadius: CGFloat {
    switch currentPlatform {
    case .macOS:
      8
    case .iOS:
      12
    case .unknown:
      8
    }
  }

  static var shadowRadius: CGFloat {
    switch currentPlatform {
    case .macOS:
      2
    case .iOS:
      4
    case .unknown:
      2
    }
  }
}

// MARK: - Platform-Aware Colors

extension Color {
  static var adaptiveBackground: Color {
    PlatformColor.adaptiveBackground
  }

  static var adaptiveSecondaryBackground: Color {
    PlatformColor.adaptiveSecondaryBackground
  }

  static var adaptiveTertiaryBackground: Color {
    PlatformColor.adaptiveTertiaryBackground
  }

  static var adaptivePrimaryText: Color {
    PlatformColor.adaptivePrimaryText
  }

  static var adaptiveSecondaryText: Color {
    PlatformColor.adaptiveSecondaryText
  }

  static var adaptiveGray: Color {
    PlatformColor.adaptiveGray
  }

  static var adaptiveGray2: Color {
    PlatformColor.adaptiveGray2
  }

  static var adaptiveGray3: Color {
    PlatformColor.adaptiveGray3
  }

  static var adaptiveGray4: Color {
    PlatformColor.adaptiveGray4
  }

  static var adaptiveGray5: Color {
    PlatformColor.adaptiveGray5
  }

  static var adaptiveGray6: Color {
    PlatformColor.adaptiveGray6
  }
}

// MARK: - Platform Color Implementation

enum PlatformColor {
  static var adaptiveBackground: Color {
    #if os(macOS)
      Color(NSColor.windowBackgroundColor)
    #else
      Color(.systemBackground)
    #endif
  }

  static var adaptiveSecondaryBackground: Color {
    #if os(macOS)
      Color(NSColor.controlBackgroundColor)
    #else
      Color(.secondarySystemBackground)
    #endif
  }

  static var adaptiveTertiaryBackground: Color {
    #if os(macOS)
      Color(
        NSColor.windowBackgroundColor.blended(withFraction: 0.7, of: NSColor.controlBackgroundColor)
          ?? NSColor.controlBackgroundColor)
    #else
      Color(.tertiarySystemBackground)
    #endif
  }

  static var adaptivePrimaryText: Color {
    #if os(macOS)
      Color(NSColor.labelColor)
    #else
      Color(.label)
    #endif
  }

  static var adaptiveSecondaryText: Color {
    #if os(macOS)
      Color(NSColor.secondaryLabelColor)
    #else
      Color(.secondaryLabel)
    #endif
  }

  static var adaptiveGray: Color {
    #if os(macOS)
      Color(NSColor.systemGray)
    #else
      Color(.systemGray)
    #endif
  }

  static var adaptiveGray2: Color {
    #if os(macOS)
      Color(NSColor.systemGray.withAlphaComponent(0.8))
    #else
      Color(.systemGray2)
    #endif
  }

  static var adaptiveGray3: Color {
    #if os(macOS)
      Color(NSColor.systemGray.withAlphaComponent(0.6))
    #else
      Color(.systemGray3)
    #endif
  }

  static var adaptiveGray4: Color {
    #if os(macOS)
      Color(NSColor.systemGray.withAlphaComponent(0.4))
    #else
      Color(.systemGray4)
    #endif
  }

  static var adaptiveGray5: Color {
    #if os(macOS)
      Color(NSColor.systemGray.withAlphaComponent(0.3))
    #else
      Color(.systemGray5)
    #endif
  }

  static var adaptiveGray6: Color {
    #if os(macOS)
      Color(NSColor.systemGray.withAlphaComponent(0.2))
    #else
      Color(.systemGray6)
    #endif
  }
}

// MARK: - Platform-Aware View Modifiers

struct PlatformNavigationTitle: ViewModifier {
  let title: String

  func body(content: Content) -> some View {
    content
      .navigationTitle(self.title)
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
  }
}

struct PlatformToolbar<ToolbarContent: View>: ViewModifier {
  let content: ToolbarContent

  func body(content: Content) -> some View {
    #if os(macOS)
      content
        .toolbar {
          ToolbarItem(placement: .automatic) {
            self.content
          }
        }
    #else
      content
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            self.content
          }
        }
    #endif
  }
}

struct PlatformPadding: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(PlatformAdapter.defaultPadding)
  }
}

struct PlatformCornerRadius: ViewModifier {
  func body(content: Content) -> some View {
    content
      .cornerRadius(PlatformAdapter.cornerRadius)
  }
}

struct PlatformShadow: ViewModifier {
  func body(content: Content) -> some View {
    content
      .shadow(color: .black.opacity(0.1), radius: PlatformAdapter.shadowRadius, x: 0, y: 2)
  }
}

// MARK: - View Extensions

extension View {
  func platformNavigationTitle(_ title: String) -> some View {
    modifier(PlatformNavigationTitle(title: title))
  }

  func platformToolbar(@ViewBuilder content: () -> some View) -> some View {
    modifier(PlatformToolbar(content: content()))
  }

  func platformPadding() -> some View {
    modifier(PlatformPadding())
  }

  func platformCornerRadius() -> some View {
    modifier(PlatformCornerRadius())
  }

  func platformShadow() -> some View {
    modifier(PlatformShadow())
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let navigateToView = Notification.Name("navigateToView")
  static let navigateToSettings = Notification.Name("navigateToSettings")
}

// MARK: - Required Imports

#if os(macOS)
  import AppKit
  import UniformTypeIdentifiers
#else
  import UIKit
  import UniformTypeIdentifiers
#endif
