import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Button("Open Main Window") {
            // Bring main window to front
            if let mainWindow = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                mainWindow.makeKeyAndOrderFront(nil)
            }
        }
        Button("New Profile") {
            // TODO: Implement new profile action
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
