// MenuCommands.swift

import SwiftUI
import UniformTypeIdentifiers

struct MenuCommands: Commands {
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var stateModel: StateModel

    @State private var showingExportPanel = false
    @State private var showingImportPanel = false

    var body: some Commands {
        // MARK: - File Menu

        CommandGroup(replacing: .newItem) {
            Button("New Profile...") {
                Task {
                    if let newProfile = try? await profileManager.createProfile(
                        name: "New Profile",
                        results: [:]
                    ) {
                        await MainActor.run {
                            profileManager.currentProfile = newProfile
                        }
                    }
                }
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Quiz Session") {
                #if os(macOS)
                WindowManager.shared.openWindow(type: .quiz) {
                    IntroView()
                }
                #endif
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Button("Open Recent Profile") {
                // Show recent profiles submenu
            }
            .disabled(profileManager.profiles.isEmpty)
        }

        CommandGroup(after: .newItem) {
            Button("Import Profile...") {
                showImportPanel()
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])

            Button("Export Profile...") {
                showExportPanel()
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(profileManager.currentProfile == nil)

            Divider()

            Button("Export All Profiles...") {
                Task {
                    _ = try? await profileManager.exportAllProfiles()
                }
            }
            .keyboardShortcut("e", modifiers: [.command, .option])

            Button("Create Backup...") {
                Task {
                    _ = try? await FileStorageManager.shared.createBackup()
                }
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
        }

        // MARK: - Edit Menu

        CommandGroup(after: .pasteboard) {
            Divider()

            Button("Duplicate Profile") {
                Task {
                    if let current = profileManager.currentProfile {
                        _ = try? await profileManager.duplicateProfile(current)
                    }
                }
            }
            .keyboardShortcut("d", modifiers: .command)
            .disabled(profileManager.currentProfile == nil)

            Button("Delete Profile") {
                Task {
                    if let current = profileManager.currentProfile {
                        try? await profileManager.deleteProfile(current)
                    }
                }
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(profileManager.currentProfile == nil)
        }

        // MARK: - View Menu

        CommandMenu("View") {
            Button("Show State Explorer") {
                #if os(macOS)
                WindowManager.shared.openWindow(type: .stateExplorer) {
                    PsychologicalStatesView()
                        .environmentObject(stateModel)
                }
                #endif
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Show Profile Comparison") {
                #if os(macOS)
                WindowManager.shared.openWindow(type: .profileComparison) {
                    ProfileComparisonView()
                        .environmentObject(profileManager)
                }
                #endif
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Show Reports") {
                #if os(macOS)
                WindowManager.shared.openWindow(type: .reports) {
                    ResultsView(quizModel: QuizModel())
                        .environmentObject(profileManager)
                }
                #endif
            }
            .keyboardShortcut("3", modifiers: .command)

            Divider()

            Button("Toggle Sidebar") {
                #if os(macOS)
                NSApp.keyWindow?.firstResponder?.tryToPerform(
                    #selector(NSSplitViewController.toggleSidebar(_:)),
                    with: nil
                )
                #endif
            }
            .keyboardShortcut("s", modifiers: [.command, .control])

            Button("Enter Full Screen") {
                #if os(macOS)
                NSApp.keyWindow?.toggleFullScreen(nil)
                #endif
            }
            .keyboardShortcut("f", modifiers: [.command, .control])

            Divider()

            Menu("Chart Style") {
                Button("Radar Chart") {
                    UserDefaultsManager.shared.preferredChartStyle = .radar
                }
                .keyboardShortcut("r", modifiers: [.command, .option])

                Button("Bar Chart") {
                    UserDefaultsManager.shared.preferredChartStyle = .bar
                }
                .keyboardShortcut("b", modifiers: [.command, .option])

                Button("Line Chart") {
                    UserDefaultsManager.shared.preferredChartStyle = .line
                }
                .keyboardShortcut("l", modifiers: [.command, .option])
            }

            Divider()

            Button("Refresh Data") {
                Task {
                    await profileManager.loadProfiles()
                    await stateModel.loadStates()
                }
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        // MARK: - Navigate Menu

        CommandMenu("Navigate") {
            Button("Previous Profile") {
                if let currentIndex = profileManager.profiles.firstIndex(where: { $0.id == profileManager.currentProfile?.id }),
                   currentIndex > 0 {
                    profileManager.currentProfile = profileManager.profiles[currentIndex - 1]
                }
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(profileManager.profiles.isEmpty)

            Button("Next Profile") {
                if let currentIndex = profileManager.profiles.firstIndex(where: { $0.id == profileManager.currentProfile?.id }),
                   currentIndex < profileManager.profiles.count - 1 {
                    profileManager.currentProfile = profileManager.profiles[currentIndex + 1]
                }
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(profileManager.profiles.isEmpty)

            Divider()

            Button("Go to Profile...") {
                // Show profile selection dialog
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            Button("Go to State...") {
                // Show state selection dialog
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
        }

        // MARK: - Quiz Menu

        CommandMenu("Quiz") {
            Button("Start New Quiz") {
                #if os(macOS)
                WindowManager.shared.openWindow(type: .quiz) {
                    IntroView()
                }
                #endif
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])

            Button("Resume Last Quiz") {
                // Resume quiz logic
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Divider()

            Button("View Quiz History") {
                // Show history
            }

            Button("Quiz Statistics") {
                // Show stats
            }
        }

        // MARK: - Window Menu

        CommandGroup(replacing: .windowArrangement) {
            Button("Minimize") {
                #if os(macOS)
                NSApp.keyWindow?.miniaturize(nil)
                #endif
            }
            .keyboardShortcut("m", modifiers: .command)

            Button("Zoom") {
                #if os(macOS)
                NSApp.keyWindow?.zoom(nil)
                #endif
            }

            Divider()

            Button("Close Window") {
                #if os(macOS)
                NSApp.keyWindow?.close()
                #endif
            }
            .keyboardShortcut("w", modifiers: .command)

            Button("Close All Windows") {
                #if os(macOS)
                WindowManager.shared.closeAllWindows()
                #endif
            }
            .keyboardShortcut("w", modifiers: [.command, .option])
        }

        // MARK: - Help Menu

        CommandGroup(replacing: .help) {
            Button("APGI Explorer Help") {
                #if os(macOS)
                NSWorkspace.shared.open(URL(string: "https://apgi-explorer.com/help")!)
                #endif
            }
            .keyboardShortcut("?", modifiers: .command)

            Button("What's New") {
                // Show what's new
            }

            Divider()

            Button("Report a Bug") {
                #if os(macOS)
                NSWorkspace.shared.open(URL(string: "https://github.com/yourrepo/issues")!)
                #endif
            }

            Button("Contact Support") {
                #if os(macOS)
                NSWorkspace.shared.open(URL(string: "mailto:support@apgi-explorer.com")!)
                #endif
            }
        }
    }

    // MARK: - Helper Methods

    private func showExportPanel() {
        #if os(macOS)
        guard let profile = profileManager.currentProfile else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(profile.name).json"
        panel.title = "Export Profile"
        panel.message = "Choose a location to save the profile"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    _ = try FileStorageManager.shared.exportProfile(profile, to: url)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
        #endif
    }

    private func showImportPanel() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Import Profile"
        panel.message = "Select a profile file to import"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    try? await profileManager.importProfile(from: url)
                }
            }
        }
        #endif
    }
}
