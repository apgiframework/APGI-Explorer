import SwiftUI

// MARK: - View Extensions
extension View {
    func quizKeyboardShortcuts() -> some View {
        self
            .keyboardShortcut("1", modifiers: [])
            .keyboardShortcut("2", modifiers: [])
            .keyboardShortcut("3", modifiers: [])
            .keyboardShortcut("4", modifiers: [])
            .keyboardShortcut("5", modifiers: [])
            .keyboardShortcut(.rightArrow, modifiers: [.command])
            .keyboardShortcut(.leftArrow, modifiers: [.command])
    }
}
