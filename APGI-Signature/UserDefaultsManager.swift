import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastActiveProfileID = "lastActiveProfileID"
        static let preferredChartStyle = "preferredChartStyle"
        static let showConfidenceIndicators = "showConfidenceIndicators"
        static let autoSaveEnabled = "autoSaveEnabled"
        static let defaultProfileName = "defaultProfileName"
        static let theme = "theme"
        static let quizReminderEnabled = "quizReminderEnabled"
        static let lastQuizDate = "lastQuizDate"
        static let totalQuizzesCompleted = "totalQuizzesCompleted"
        static let analyticsEnabled = "analyticsEnabled"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let hapticsEnabled = "hapticsEnabled"
    }
    
    // MARK: - Onboarding
    
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    // MARK: - Profile Settings
    
    var lastActiveProfileID: UUID? {
        get {
            guard let string = defaults.string(forKey: Keys.lastActiveProfileID) else { return nil }
            return UUID(uuidString: string)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Keys.lastActiveProfileID)
        }
    }
    
    var defaultProfileName: String {
        get { defaults.string(forKey: Keys.defaultProfileName) ?? "My Profile" }
        set { defaults.set(newValue, forKey: Keys.defaultProfileName) }
    }
    
    // MARK: - UI Preferences
    
    var preferredChartStyle: ChartStyle {
        get {
            guard let rawValue = defaults.string(forKey: Keys.preferredChartStyle),
                  let style = ChartStyle(rawValue: rawValue) else {
                return .radar
            }
            return style
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.preferredChartStyle) }
    }
    
    var theme: AppTheme {
        get {
            guard let rawValue = defaults.string(forKey: Keys.theme),
                  let theme = AppTheme(rawValue: rawValue) else {
                return .system
            }
            return theme
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.theme) }
    }
    
    var showConfidenceIndicators: Bool {
        get { defaults.bool(forKey: Keys.showConfidenceIndicators) }
        set { defaults.set(newValue, forKey: Keys.showConfidenceIndicators) }
    }
    
    // MARK: - Feature Flags
    
    var autoSaveEnabled: Bool {
        get { defaults.object(forKey: Keys.autoSaveEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.autoSaveEnabled) }
    }
    
    var quizReminderEnabled: Bool {
        get { defaults.bool(forKey: Keys.quizReminderEnabled) }
        set { defaults.set(newValue, forKey: Keys.quizReminderEnabled) }
    }
    
    var analyticsEnabled: Bool {
        get { defaults.object(forKey: Keys.analyticsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.analyticsEnabled) }
    }
    
    var soundEffectsEnabled: Bool {
        get { defaults.object(forKey: Keys.soundEffectsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.soundEffectsEnabled) }
    }
    
    var hapticsEnabled: Bool {
        get { defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.hapticsEnabled) }
    }
    
    // MARK: - Statistics
    
    var lastQuizDate: Date? {
        get { defaults.object(forKey: Keys.lastQuizDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastQuizDate) }
    }
    
    var totalQuizzesCompleted: Int {
        get { defaults.integer(forKey: Keys.totalQuizzesCompleted) }
        set { defaults.set(newValue, forKey: Keys.totalQuizzesCompleted) }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }
}

enum ChartStyle: String, CaseIterable {
    case radar = "radar"
    case bar = "bar"
    case line = "line"
    case area = "area"
}

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
}
