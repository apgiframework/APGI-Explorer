import SwiftUI
import Charts

struct ProfileComparisonView: View {
    @State private var selectedProfile1: String = ""
    @State private var selectedProfile2: String = ""
    @State private var comparisonMode: ComparisonMode = .radar
    
    private enum ComparisonMode: String, CaseIterable {
        case radar = "Radar"
        case bar = "Bar"
        case line = "Line"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Selection
                HStack {
                    VStack(alignment: .leading) {
                        Text("Profile 1")
                            .font(.headline)
                        Picker("Profile 1", selection: $selectedProfile1) {
                            Text("Select Profile...").tag("")
                            ForEach(getAvailableProfiles(), id: \.self) { profile in
                                Text(profile).tag(profile)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Profile 2")
                            .font(.headline)
                        Picker("Profile 2", selection: $selectedProfile2) {
                            Text("Select Profile...").tag("")
                            ForEach(getAvailableProfiles(), id: \.self) { profile in
                                Text(profile).tag(profile)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                
                // Comparison Mode Selection
                Picker("Comparison Mode", selection: $comparisonMode) {
                    ForEach(ComparisonMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Comparison Chart
                if !selectedProfile1.isEmpty && !selectedProfile2.isEmpty {
                    comparisonChart
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
            .navigationTitle("Profile Comparison")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Compare") {
                        performComparison()
                    }
                    .disabled(selectedProfile1.isEmpty || selectedProfile2.isEmpty)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Export") {
                        exportComparison()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var comparisonChart: some View {
        VStack {
            switch comparisonMode {
            case .radar:
                RadarComparisonChart(profile1: selectedProfile1, profile2: selectedProfile2)
            case .bar:
                BarComparisonChart(profile1: selectedProfile1, profile2: selectedProfile2)
            case .line:
                LineComparisonChart(profile1: selectedProfile1, profile2: selectedProfile2)
            }
        }
        .frame(height: 400)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Select two profiles to compare")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Choose profiles from the dropdown menus above to see their psychological parameters compared side by side.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func getAvailableProfiles() -> [String] {
        // This would typically fetch from your data store
        return ["Profile A", "Profile B", "Profile C", "Baseline Profile"]
    }
    
    private func performComparison() {
        print("Comparing \(selectedProfile1) with \(selectedProfile2)")
    }
    
    private func exportComparison() {
        print("Exporting comparison...")
    }
}

// MARK: - Comparison Chart Views
struct RadarComparisonChart: View {
    let profile1: String
    let profile2: String
    
    var body: some View {
        Text("Radar Chart for \(profile1) vs \(profile2)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
    }
}

struct BarComparisonChart: View {
    let profile1: String
    let profile2: String
    
    var body: some View {
        Text("Bar Chart for \(profile1) vs \(profile2)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
    }
}

struct LineComparisonChart: View {
    let profile1: String
    let profile2: String
    
    var body: some View {
        Text("Line Chart for \(profile1) vs \(profile2)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
    }
}
