import SwiftUI

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @AppStorage("preferredChartStyle") private var defaultChartStyle: ChartStyle = .radar
    @AppStorage("exportQuality") private var exportQuality: ExportQuality = .high
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("fontSize") private var fontSize: Double = 16.0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chart Style Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Charts")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Picker("Default Chart Style", selection: self.$defaultChartStyle) {
                        Text("Radar").tag(ChartStyle.radar)
                        Text("Bar").tag(ChartStyle.bar)
                        Text("Line").tag(ChartStyle.line)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .help("Default chart style for profile visualization")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

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
                    .help("Default quality for exported images and documents")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Theme Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Picker("Color Scheme", selection: self.$colorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .help("Choose your preferred color scheme")

                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(self.fontSize, specifier: "%.0f")pt")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: self.$fontSize, in: 12 ... 20, step: 1)
                        .help("Adjust the base font size throughout the app")
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
