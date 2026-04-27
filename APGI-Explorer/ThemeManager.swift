import Combine
import QuartzCore
import SwiftUI

@MainActor
class ThemeManager: ObservableObject {
  static let shared = ThemeManager()

  @Published var currentTheme: AppTheme = .system {
    didSet {
      self.themeChangeCancellable?.cancel()
      self.themeChangeCancellable = Just(self.currentTheme)
        .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
          self?.applyTheme()
          self?.saveTheme()
        }
    }
  }

  private let userDefaults = UserDefaults.standard
  private let themeKey = "theme"
  private var themeChangeCancellable: AnyCancellable?

  private init() {
    self.loadTheme()
    self.applyTheme()
  }

  private func loadTheme() {
    if let rawValue = userDefaults.string(forKey: themeKey),
      let theme = AppTheme(rawValue: rawValue) {
      self.currentTheme = theme
    } else {
      self.currentTheme = .system
    }
  }

  private func saveTheme() {
    self.userDefaults.set(self.currentTheme.rawValue, forKey: self.themeKey)
  }

  private func applyTheme() {
    DispatchQueue.main.async {
      // Apply theme changes smoothly to prevent visual artifacts
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.15
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        context.allowsImplicitAnimation = true

        if let window = NSApp.keyWindow {
          self.applyThemeToWindow(window)
        }

        // Apply to all windows
        for window in NSApp.windows {
          self.applyThemeToWindow(window)
        }
      }
    }
  }

  private func applyThemeToWindow(_ window: NSWindow) {
    switch self.currentTheme {
    case .system:
      window.appearance = nil
    case .light:
      window.appearance = NSAppearance(named: .aqua)
    case .dark:
      window.appearance = NSAppearance(named: .darkAqua)
    }
  }

  func setTheme(_ theme: AppTheme) {
    self.currentTheme = theme
  }

  func getColorScheme() -> ColorScheme? {
    switch self.currentTheme {
    case .system:
      nil
    case .light:
      .light
    case .dark:
      .dark
    }
  }
}

/// SwiftUI Environment key for theme
struct ThemeEnvironmentKey: EnvironmentKey {
  static let defaultValue: AppTheme = .system
}

extension EnvironmentValues {
  var currentTheme: AppTheme {
    get { self[ThemeEnvironmentKey.self] }
    set { self[ThemeEnvironmentKey.self] = newValue }
  }
}

/// View modifier for applying theme
struct ThemedView: ViewModifier {
  let theme: AppTheme

  func body(content: Content) -> some View {
    content
      .preferredColorScheme(self.theme.getColorScheme())
      .environment(\.currentTheme, self.theme)
  }
}

extension View {
  func themed(_ theme: AppTheme) -> some View {
    self.modifier(ThemedView(theme: theme))
  }
}

extension AppTheme {
  func getColorScheme() -> ColorScheme? {
    switch self {
    case .system:
      nil
    case .light:
      .light
    case .dark:
      .dark
    }
  }
}
