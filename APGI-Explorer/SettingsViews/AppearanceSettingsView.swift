import SwiftUI

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
  @AppStorage("preferredChartStyle") private var defaultChartStyle: ChartStyle = .radar
  @AppStorage("exportQuality") private var exportQuality: ExportQuality = .high
  @AppStorage("fontSize") private var fontSize: Double = 16.0

  @EnvironmentObject private var themeManager: ThemeManager
  @Environment(\.showTooltips) private var tooltipsEnabled

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Export Quality Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Export Quality")
            .font(.headline)
            .fontWeight(.semibold)

          Picker("Export Quality", selection: self.$exportQuality) {
            Text("Low").tag(ExportQuality.low)
            Text("Medium").tag(ExportQuality.medium)
            Text("High").tag(ExportQuality.high)
          }
          .pickerStyle(SegmentedPickerStyle())
          .conditionalHelp("Default quality for exported images and documents", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Theme Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Theme")
            .font(.headline)
            .fontWeight(.semibold)

          Picker("Color Scheme", selection: self.$themeManager.currentTheme) {
            Text("System").tag(AppTheme.system)
            Text("Light").tag(AppTheme.light)
            Text("Dark").tag(AppTheme.dark)
          }
          .pickerStyle(SegmentedPickerStyle())
          .conditionalHelp("Choose your preferred color scheme", when: tooltipsEnabled)

          HStack {
            Text("Font Size")
            Spacer()
            Text("\(self.fontSize, specifier: "%.0f")pt")
              .foregroundColor(.secondary)
          }

          Slider(value: self.$fontSize, in: 12...20, step: 1)
            .conditionalHelp("Adjust the base font size throughout the app", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
      }
      .padding()
    }
    .navigationTitle("Appearance")
  }
}
