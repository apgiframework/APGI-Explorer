import Combine
import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
  static let shared = LocalizationManager()

  @Published var currentLanguage: SupportedLanguage = .english

  private init() {
    self.loadSavedLanguage()
    // Ensure bundle is set for the current language
    Bundle.setLanguage(self.currentLanguage.rawValue)
  }

  enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case russian = "ru"

    var id: String {
      rawValue
    }

    var displayName: String {
      switch self {
      case .english:
        NSLocalizedString("English", comment: "Language name")
      case .spanish:
        NSLocalizedString("Español", comment: "Language name")
      case .french:
        NSLocalizedString("Français", comment: "Language name")
      case .german:
        NSLocalizedString("Deutsch", comment: "Language name")
      case .russian:
        NSLocalizedString("Русский", comment: "Language name")
      }
    }

    var nativeName: String {
      switch self {
      case .english:
        "English"
      case .spanish:
        "Español"
      case .french:
        "Français"
      case .german:
        "Deutsch"
      case .russian:
        "Русский"
      }
    }

    var localeIdentifier: String {
      switch self {
      case .english:
        "en_US"
      case .spanish:
        "es_ES"
      case .french:
        "fr_FR"
      case .german:
        "de_DE"
      case .russian:
        "ru_RU"
      }
    }
  }

  func setLanguage(_ language: SupportedLanguage) {
    self.currentLanguage = language
    UserDefaults.standard.set(language.rawValue, forKey: "selected_language")
    UserDefaults.standard.synchronize()

    Bundle.setLanguage(language.rawValue)
    objectWillChange.send()
  }

  private func loadSavedLanguage() {
    if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language"),
      let language = SupportedLanguage(rawValue: savedLanguage)
    {
      self.currentLanguage = language
      Bundle.setLanguage(language.rawValue)
    }
  }

  func localizedString(for key: String) -> String {
    NSLocalizedString(key, comment: "")
  }

  func localizedString(for key: String, arguments: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, arguments: arguments)
  }
}

extension Bundle {
  private static var currentLanguageBundle: Bundle?

  static func setLanguage(_ language: String) {
    guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
      let bundle = Bundle(path: path)
    else {
      return
    }

    self.currentLanguageBundle = bundle
  }

  func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
    if let bundle = Bundle.currentLanguageBundle {
      return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
    return NSLocalizedString(
      key, tableName: tableName, bundle: self, value: value ?? "", comment: "")
  }
}

// MARK: - SwiftUI Integration

extension View {
  func localized(_ key: String) -> some View {
    self.modifier(LocalizationModifier(key: key))
  }
}

struct LocalizationModifier: ViewModifier {
  let key: String

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) {
        _ in
        // Trigger view update when language changes
      }
  }
}

// MARK: - String Extension

extension String {
  var localized: String {
    LocalizationManager.shared.localizedString(for: self)
  }

  func localized(arguments: CVarArg...) -> String {
    LocalizationManager.shared.localizedString(for: self, arguments: arguments)
  }
}

// MARK: - Text Extension

extension Text {
  init(localized key: String) {
    self.init(LocalizationManager.shared.localizedString(for: key))
  }

  init(localized key: String, arguments: CVarArg...) {
    let localizedString = LocalizationManager.shared.localizedString(for: key, arguments: arguments)
    self.init(localizedString)
  }
}

// MARK: - Localization Settings View

struct LocalizationSettingsView: View {
  @StateObject private var localizationManager = LocalizationManager.shared

  var body: some View {
    Form {
      Section {
        Picker("Language".localized, selection: self.$localizationManager.currentLanguage) {
          ForEach(LocalizationManager.SupportedLanguage.allCases) { language in
            HStack {
              Text(language.nativeName)
              Spacer()
              Text("(\(language.displayName))")
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .tag(language)
          }
        }
        .pickerStyle(MenuPickerStyle())

        Text("Changing the language will restart the application.".localized)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Section("About Localization".localized) {
        Text(
          "APGI Explorer supports multiple languages to make psychological assessment accessible to users worldwide."
            .localized
        )
        .font(.body)

        Text("Contributions for additional translations are welcome on GitHub.".localized)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .navigationTitle("Language".localized)
  }
}

// MARK: - Localization Utilities

enum LocalizationUtils {
  static func formatRelativeTime(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = Locale.current
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
  }

  static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = style
    formatter.locale = Locale.current
    return formatter.string(from: date)
  }

  static func formatNumber(_ number: Double, style: NumberFormatter.Style = .decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = style
    formatter.locale = Locale.current
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
  }

  static func formatPercentage(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.locale = Locale.current
    formatter.maximumFractionDigits = 1
    return formatter.string(from: NSNumber(value: value / 100.0)) ?? "\(value)%"
  }
}

// MARK: - Localization Preview Helper

#if DEBUG
  extension LocalizationManager.SupportedLanguage {
    static var previewLanguages: [LocalizationManager.SupportedLanguage] {
      [.english, .spanish, .french, .german, .russian]
    }
  }

  struct LocalizationPreview: View {
    let language: LocalizationManager.SupportedLanguage

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        Text("app_name".localized)
        Text("tab_profiles".localized)
        Text("quiz_title".localized)
        Text("settings_title".localized)
        Text("export_title".localized)
      }
      .onAppear {
        LocalizationManager.shared.setLanguage(self.language)
      }
    }
  }
#endif
