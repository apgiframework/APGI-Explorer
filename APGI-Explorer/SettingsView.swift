import SwiftUI
import Foundation
import CoreData
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct SettingsView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                Label("General", systemImage: "gear")
                    .tag(0)
                Label("Appearance", systemImage: "paintbrush")
                    .tag(1)
                Label("Charts", systemImage: "chart.bar")
                    .tag(2)
                Label("Privacy", systemImage: "lock.shield")
                    .tag(3)
                Label("Advanced", systemImage: "wrench.and.screwdriver")
                    .tag(4)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            // Detail view
            Group {
                switch selectedTab {
                case 0:
                    GeneralSettingsView()
                case 1:
                    AppearanceSettingsView()
                case 2:
                    ChartsSettingsView()
                case 3:
                    DataPrivacySettingsView()
                case 4:
                    AdvancedSettingsView()
                default:
                    GeneralSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#Preview {
    SettingsView()
}
