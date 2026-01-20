import SwiftUI
import Combine
import QuartzCore

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme = .system {
        didSet {
            // Debounce rapid theme changes to prevent visual artifacts
            themeChangeCancellable?.cancel()
            themeChangeCancellable = Just(currentTheme)
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
        loadTheme()
        applyTheme()
    }

    private func loadTheme() {
        if let rawValue = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: rawValue) {
            currentTheme = theme
        } else {
            currentTheme = .system
        }
    }

    private func saveTheme() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
        userDefaults.synchronize()
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
        switch currentTheme {
        case .system:
            window.appearance = nil
        case .light:
            window.appearance = NSAppearance(named: .aqua)
        case .dark:
            window.appearance = NSAppearance(named: .darkAqua)
        }
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }

    func getColorScheme() -> ColorScheme? {
        switch currentTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// SwiftUI Environment key for theme
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme = .system
}

extension EnvironmentValues {
    var currentTheme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// View modifier for applying theme
struct ThemedView: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(theme.getColorScheme())
            .environment(\.currentTheme, theme)
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
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
