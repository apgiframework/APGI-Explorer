import SwiftUI

struct ExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var profileManager: ProfileManager
    private(set) var profile: QuizProfile
    @State private var exportFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportFileURL: URL?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $exportFormat) {
                        Text("PDF").tag(ExportFormat.pdf)
                        Text("JSON").tag(ExportFormat.json)
                        Text("Text").tag(ExportFormat.text)
                        Text("HTML").tag(ExportFormat.html)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Preview")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile: \(profile.name)")
                            .font(.headline)
                        
                        let profileType = profileManager.determineProfileType(for: profile.results)
                        Text("Type: \(profileType.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text(profileType.description)
                            .font(.body)
                            .padding(.vertical, 4)
                        
                        Divider()
                        
                        // Show a preview of the scores
                        let apgiProfile = profileManager.profile(from: profile.results)
                        VStack(alignment: .leading, spacing: 4) {
                            ScoreRow(parameter: "ε (Epsilon)", value: apgiProfile.epsilon)
                            ScoreRow(parameter: "π (Precision)", value: apgiProfile.precision)
                            ScoreRow(parameter: "θₜ (Threshold)", value: apgiProfile.threshold)
                            ScoreRow(parameter: "β (Somatic Bias)", value: apgiProfile.somaticBias)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Export Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: exportProfile) {
                        if isExporting {
                            ProgressView()
                        } else {
                            Text("Export")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func exportProfile() {
        isExporting = true
        
        Task { @MainActor in
            if let url = profileManager.getExportURL(for: profile, format: exportFormat) {
                exportFileURL = url
                showShareSheet = true
            }
            isExporting = false
        }
    }
}

struct ScoreRow: View {
    let parameter: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(parameter)
                .font(.subheadline)
            Spacer()
            Text("\(Int(value))")
                .font(.body.monospacedDigit())
                .foregroundColor(scoreColor)
        }
    }
    
    private var scoreColor: Color {
        switch value {
        case 0..<25: return .red
        case 25..<40: return .orange
        case 40..<60: return .yellow
        case 60..<75: return .green
        case 75...100: return .blue
        default: return .primary
        }
    }
}

// MARK: - Preview

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        let profileManager = ProfileManager()
        let testProfile = QuizProfile(
            id: UUID(),
            name: "Test Profile",
            dateCreated: Date(),
            dateModified: Date(),
            results: ["epsilon": 75, "precision": 60, "threshold": 45, "somatic": 30]
        )
        
        return ExportView(profileManager: profileManager, profile: testProfile)
    }
}
