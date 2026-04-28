import SwiftUI

// MARK: - Charts Settings View

struct ChartsSettingsView: View {
  @AppStorage("preferredChartStyle") private var defaultChartStyle: ChartStyle = .radar
  @AppStorage("showChartGrid") private var showChartGrid: Bool = true
  @AppStorage("animateCharts") private var animateCharts: Bool = true
  @AppStorage("chartColorScheme") private var chartColorScheme: String = "default"

  @Environment(\.showTooltips) private var tooltipsEnabled

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Chart Display Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Chart Display")
            .font(.headline)
            .fontWeight(.semibold)

          Toggle("Show Grid", isOn: self.$showChartGrid)
            .conditionalHelp("Display grid lines on charts", when: tooltipsEnabled)

          Toggle("Animate Charts", isOn: self.$animateCharts)
            .conditionalHelp("Show smooth animations when chart data changes", when: tooltipsEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)

        // Chart Style Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Chart Style")
            .font(.headline)
            .fontWeight(.semibold)

          Picker("Default Chart Style", selection: self.$defaultChartStyle) {
            Text("Radar").tag(ChartStyle.radar)
            Text("Bar").tag(ChartStyle.bar)
            Text("Line").tag(ChartStyle.line)
          }
          .pickerStyle(SegmentedPickerStyle())

          Picker("Color Scheme", selection: self.$chartColorScheme) {
            Text("Default").tag("default")
            Text("Colorful").tag("colorful")
            Text("Monochrome").tag("monochrome")
          }
          .pickerStyle(MenuPickerStyle())
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
      }
      .padding()
    }
    .navigationTitle("Charts")
  }
}
