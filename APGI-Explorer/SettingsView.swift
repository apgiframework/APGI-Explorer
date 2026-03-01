import CoreData
import Foundation
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: self.$selectedTab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            // Detail view
            Group {
                switch self.selectedTab {
                case .general:
                    GeneralSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .charts:
                    ChartsSettingsView()
                case .privacy:
                    DataPrivacySettingsView()
                case .advanced:
                    AdvancedSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - Settings Tab Enum

enum SettingsTab: CaseIterable {
    case general, appearance, charts, privacy, advanced

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .charts: "Charts"
        case .privacy: "Privacy"
        case .advanced: "Advanced"
        }
    }

    var icon: String {
        switch self {
        case .general: "gear"
        case .appearance: "paintbrush"
        case .charts: "chart.bar"
        case .privacy: "lock.shield"
        case .advanced: "wrench.and.screwdriver"
        }
    }
}

#Preview {
    SettingsView()
}
