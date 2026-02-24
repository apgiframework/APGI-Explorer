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
        static let backupFrequency = "backupFrequency"
        static let lastBackupDate = "lastBackupDate"
        static let statesDisplayMode = "statesDisplayMode"
        static let defaultComparisonMode = "defaultComparisonMode"
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { self.defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { self.defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: - Profile Settings

    var lastActiveProfileID: UUID? {
        get {
            guard let string = defaults.string(forKey: Keys.lastActiveProfileID) else { return nil }
            return UUID(uuidString: string)
        }
        set {
            self.defaults.set(newValue?.uuidString, forKey: Keys.lastActiveProfileID)
        }
    }

    var defaultProfileName: String {
        get { self.defaults.string(forKey: Keys.defaultProfileName) ?? "My Profile" }
        set { self.defaults.set(newValue, forKey: Keys.defaultProfileName) }
    }

    // MARK: - UI Preferences

    var preferredChartStyle: ChartStyle {
        get {
            guard let rawValue = defaults.string(forKey: Keys.preferredChartStyle),
                  let style = ChartStyle(rawValue: rawValue)
            else {
                return .radar
            }
            return style
        }
        set { self.defaults.set(newValue.rawValue, forKey: Keys.preferredChartStyle) }
    }

    var theme: AppTheme {
        get {
            guard let rawValue = defaults.string(forKey: Keys.theme),
                  let theme = AppTheme(rawValue: rawValue)
            else {
                return .system
            }
            return theme
        }
        set { self.defaults.set(newValue.rawValue, forKey: Keys.theme) }
    }

    var showConfidenceIndicators: Bool {
        get { self.defaults.bool(forKey: Keys.showConfidenceIndicators) }
        set { self.defaults.set(newValue, forKey: Keys.showConfidenceIndicators) }
    }

    // MARK: - Feature Flags

    var autoSaveEnabled: Bool {
        get { self.defaults.object(forKey: Keys.autoSaveEnabled) as? Bool ?? true }
        set { self.defaults.set(newValue, forKey: Keys.autoSaveEnabled) }
    }

    var quizReminderEnabled: Bool {
        get { self.defaults.bool(forKey: Keys.quizReminderEnabled) }
        set { self.defaults.set(newValue, forKey: Keys.quizReminderEnabled) }
    }

    var analyticsEnabled: Bool {
        get { self.defaults.object(forKey: Keys.analyticsEnabled) as? Bool ?? false }
        set { self.defaults.set(newValue, forKey: Keys.analyticsEnabled) }
    }

    var soundEffectsEnabled: Bool {
        get { self.defaults.object(forKey: Keys.soundEffectsEnabled) as? Bool ?? true }
        set { self.defaults.set(newValue, forKey: Keys.soundEffectsEnabled) }
    }

    var hapticsEnabled: Bool {
        get { self.defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true }
        set { self.defaults.set(newValue, forKey: Keys.hapticsEnabled) }
    }

    // MARK: - Backup Settings

    var backupFrequency: BackupFrequency {
        get {
            guard let rawValue = defaults.string(forKey: Keys.backupFrequency),
                  let frequency = BackupFrequency(rawValue: rawValue)
            else {
                return .weekly
            }
            return frequency
        }
        set { self.defaults.set(newValue.rawValue, forKey: Keys.backupFrequency) }
    }

    var lastBackupDate: Date? {
        get { self.defaults.object(forKey: Keys.lastBackupDate) as? Date }
        set { self.defaults.set(newValue, forKey: Keys.lastBackupDate) }
    }

    var statesDisplayMode: DisplayMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.statesDisplayMode),
                  let mode = DisplayMode(rawValue: rawValue)
            else {
                return .list
            }
            return mode
        }
        set { self.defaults.set(newValue.rawValue, forKey: Keys.statesDisplayMode) }
    }

    var defaultComparisonMode: ComparisonMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.defaultComparisonMode),
                  let mode = ComparisonMode(rawValue: rawValue)
            else {
                return .radar
            }
            return mode
        }
        set { self.defaults.set(newValue.rawValue, forKey: Keys.defaultComparisonMode) }
    }

    // MARK: - Statistics

    var lastQuizDate: Date? {
        get { self.defaults.object(forKey: Keys.lastQuizDate) as? Date }
        set { self.defaults.set(newValue, forKey: Keys.lastQuizDate) }
    }

    var totalQuizzesCompleted: Int {
        get { self.defaults.integer(forKey: Keys.totalQuizzesCompleted) }
        set { self.defaults.set(newValue, forKey: Keys.totalQuizzesCompleted) }
    }

    // MARK: - Reset

    func resetToDefaults() {
        guard let domain = Bundle.main.bundleIdentifier else {
            print("Warning: Unable to get bundle identifier for reset")
            return
        }
        self.defaults.removePersistentDomain(forName: domain)
        self.defaults.synchronize()
    }
}

enum ChartStyle: String, CaseIterable {
    case radar
    case bar
    case line
    case area
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
}

enum BackupFrequency: String, CaseIterable {
    case daily
    case weekly
    case monthly
    case never
    case manual

    var timeInterval: TimeInterval {
        switch self {
        case .daily: 24 * 60 * 60 // 1 day
        case .weekly: 7 * 24 * 60 * 60 // 7 days
        case .monthly: 30 * 24 * 60 * 60 // 30 days
        case .never: 0 // No automatic backup
        case .manual: 0 // No automatic backup
        }
    }
}

enum ExportQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case ultra = "Ultra"
}

enum DisplayMode: String, CaseIterable, Identifiable {
    case list = "List"
    case grid = "Grid"
    var id: Self {
        self
    }

    var icon: String {
        switch self {
        case .list: "list.bullet"
        case .grid: "square.grid.2x2"
        }
    }
}

enum ComparisonMode: String, CaseIterable, Identifiable {
    case radar = "Radar"
    case bar = "Bar"
    case table = "Table"
    case line = "Line"

    var id: String {
        self.rawValue
    }

    var icon: String {
        switch self {
        case .radar: "chart.radar"
        case .bar: "chart.bar"
        case .table: "tablecells"
        case .line: "chart.line.uptrend.xyaxis"
        }
    }
}
