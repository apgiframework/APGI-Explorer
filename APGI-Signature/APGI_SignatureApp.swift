import SwiftUI
import AppKit

// MARK: - Chart Style Enum
enum ChartStyle: String, CaseIterable, Codable {
    case radar, bar, line
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let newQuizSession = Notification.Name("newQuizSession")
    static let openRecentProfile = Notification.Name("openRecentProfile")
}

@main
struct APGISignatureApp: App {
    @StateObject private var dependencies = AppDependencies.shared
    @State private var chartStyle: ChartStyle = .radar
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withAppDependencies(dependencies)
        }
        .commands {
            // File menu additions
            CommandGroup(replacing: .newItem) {
                Button("New Quiz Session") {
                    NotificationCenter.default.post(name: .newQuizSession, object: nil)
                }
                .keyboardShortcut("n")
                
                Button("Open Recent Profile...") {
                    NotificationCenter.default.post(name: .openRecentProfile, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Export Profile as PDF...") {
                    exportProfileAsPDF()
                }
                .keyboardShortcut("e")
            }
            
            // View menu
            CommandMenu("View") {
                Button("Show Live Tracker") {
                    // Toggle live tracker visibility
                }
                .keyboardShortcut("l", modifiers: [.command])
                
                Button("Fullscreen Visualization") {
                    // Enter fullscreen mode
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
                
                Divider()
                
                Picker("Chart Style", selection: $chartStyle) {
                    Text("Radar").tag(ChartStyle.radar)
                    Text("Bar").tag(ChartStyle.bar)
                    Text("Line").tag(ChartStyle.line)
                }
            }
            
            // Navigation menu
            CommandMenu("Navigate") {
                Button("Previous State") {
                    navigateToPreviousState()
                }
                .keyboardShortcut("[", modifiers: [.command])
                
                Button("Next State") {
                    navigateToNextState()
                }
                .keyboardShortcut("]", modifiers: [.command])
                
                Button("Jump to State...") {
                    showStateJumper()
                }
                .keyboardShortcut("j", modifiers: [.command])
            }
            
            // Quiz menu
            CommandMenu("Quiz") {
                Button("Start New Quiz") {
                    startNewQuiz()
                }
                .keyboardShortcut("q", modifiers: [.command, .shift])
                
                Button("Resume Last Quiz") {
                    resumeLastQuiz()
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Divider()
                
                Button("Skip Question") {
                    skipCurrentQuestion()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                
                Button("Flag Question") {
                    flagCurrentQuestion()
                }
                .keyboardShortcut("'", modifiers: [.command])
            }
            
            // Analysis menu
            CommandMenu("Analysis") {
                Button("Compare with Previous Profile") {
                    compareProfiles()
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
                
                Button("Generate Detailed Report") {
                    generateDetailedReport()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                
                Button("Export Data for Research") {
                    exportResearchData()
                }
            }
        }
        
        // Add dedicated window for state exploration
        WindowGroup("State Explorer", id: "state-explorer") {
            PsychologicalStatesView()
        }
        .defaultSize(width: 1200, height: 800)
        
        // Add window for profile comparison
        WindowGroup("Profile Comparison", id: "profile-comparison") {
            ProfileComparisonView()
        }
        .defaultSize(width: 1000, height: 700)
        
        // Settings window
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Menu Command Actions
extension APGISignatureApp {
    private func exportProfileAsPDF() {
        // Implementation for PDF export
        print("Exporting profile as PDF...")
    }
    
    private func navigateToPreviousState() {
        // Implementation for previous state navigation
        print("Navigating to previous state...")
    }
    
    private func navigateToNextState() {
        // Implementation for next state navigation
        print("Navigating to next state...")
    }
    
    private func showStateJumper() {
        // Implementation for state jumper
        print("Showing state jumper...")
    }
    
    private func startNewQuiz() {
        // Implementation for starting new quiz
        print("Starting new quiz...")
    }
    
    private func resumeLastQuiz() {
        // Implementation for resuming last quiz
        print("Resuming last quiz...")
    }
    
    private func skipCurrentQuestion() {
        // Implementation for skipping current question
        print("Skipping current question...")
    }
    
    private func flagCurrentQuestion() {
        // Implementation for flagging current question
        print("Flagging current question...")
    }
    
    private func compareProfiles() {
        // Implementation for profile comparison
        print("Comparing profiles...")
    }
    
    private func generateDetailedReport() {
        // Implementation for generating detailed report
        print("Generating detailed report...")
    }
    
    private func exportResearchData() {
        // Implementation for exporting research data
        print("Exporting research data...")
    }
}
