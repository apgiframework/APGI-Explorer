import os.log
import SwiftUI

struct ExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var profileManager: ProfileManager
    private(set) var profile: QuizProfile
    @AppStorage("exportFormat") private var exportFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportFileURL: URL?
    @State private var toast: ToastMessage?

    private var previewSection: some View {
        Section(header: Text("Preview")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Profile: \(self.profile.name)")
                    .font(.headline)

                let profileType = self.profileManager.determineProfileType(for: self.profile.results)
                Text("Type: \(profileType.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                Text(profileType.description)
                    .font(.body)
                    .padding(.vertical, 4)

                Divider()

                // Show a preview of the scores
                let apgiProfile = (try? self.profileManager.profile(from: self.profile.results)) ?? APGIProfile(epsilon: 0, precision: 0, threshold: 0, somaticBias: 0, interactionScore: 0, temporalStability: 0, environmentalFit: 0)
                VStack(alignment: .leading, spacing: 4) {
                    ScoreRow(parameter: "ε (Epsilon)", value: apgiProfile.epsilon)
                    ScoreRow(parameter: "π (Precision)", value: apgiProfile.precision)
                    ScoreRow(parameter: "θₜ (Threshold)", value: apgiProfile.threshold)
                    ScoreRow(parameter: "β (Somatic Bias)", value: apgiProfile.somaticBias)
                    ScoreRow(parameter: "ι (Interaction Score)", value: apgiProfile.interactionScore)
                    ScoreRow(parameter: "τ (Temporal Stability)", value: apgiProfile.temporalStability)
                    ScoreRow(parameter: "φ (Environmental Fit)", value: apgiProfile.environmentalFit)
                }
            }
            .padding(.vertical, 8)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: self.$exportFormat) {
                        ForEach(ExportCategory.allCases, id: \.self) { category in
                            Section(header: Text(category.rawValue)) {
                                ForEach(category.formats, id: \.self) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Text(self.exportFormat.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                self.previewSection
            }
            .navigationTitle("Export Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    LoadingButton(title: "Export", isLoading: self.isExporting, action: self.exportProfile)
                }
            }
            .sheet(isPresented: self.$showShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(items: [url])
                }
            }
            .toast(self.$toast)
        }
    }

    private func exportProfile() {
        self.isExporting = true

        Task { @MainActor in
            do {
                let startTime = Date()
                var url: URL?

                // Use ResearchExportManager for specialized formats
                if self.exportFormat.category == .statistical || self.exportFormat.category == .bibliography || self.exportFormat.category == .academic {
                    let apgiScores = try self.profileManager.profile(from: self.profile.results)
                    let profileExport = ProfileExport(
                        version: "1.0",
                        timestamp: Date(),
                        profile: profile,
                        apgiScores: apgiScores
                    )

                    let exportData = try ResearchExportManager.shared.exportProfile(profileExport, format: self.exportFormat)
                    let filename = ExportUtilities.generateExportFilename(profile: self.profile, format: self.exportFormat)
                    let tempDir = ExportUtilities.getTemporaryDirectory()
                    let url = tempDir.appendingPathComponent(filename)

                    try exportData.write(to: url)
                } else {
                    // Use existing ProfileManager for basic formats
                    url = self.profileManager.getExportURL(for: self.profile, format: self.exportFormat)
                }

                if let exportURL = url {
                    self.exportFileURL = exportURL
                    self.showShareSheet = true

                    let duration = Date().timeIntervalSince(startTime)
                    if duration > 2.0 {
                        os_log("Export completed in %.2f seconds", duration)
                    }

                    self.toast = .success("Profile exported successfully as \(self.exportFormat.rawValue)")
                } else {
                    throw AppError.exportFailed(underlying: NSError(domain: "ExportError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to generate export file",
                    ]))
                }
            } catch {
                self.toast = .error("Export failed: \(error.localizedDescription)")
            }

            self.isExporting = false
        }
    }
}

struct ScoreRow: View {
    let parameter: String
    let value: Double

    var body: some View {
        HStack {
            Text(self.parameter)
                .font(.subheadline)
            Spacer()
            Text("\(Int(self.value))")
                .font(.body.monospacedDigit())
                .foregroundColor(self.scoreColor)
        }
    }

    private var scoreColor: Color {
        switch self.value {
        case 0 ..< 25: Color(NSColor.systemRed)
        case 25 ..< 40: Color(NSColor.systemOrange)
        case 40 ..< 60: Color(NSColor.systemYellow)
        case 60 ..< 75: Color(NSColor.systemGreen)
        case 75 ... 100: Color(NSColor.systemBlue)
        default: .primary
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
