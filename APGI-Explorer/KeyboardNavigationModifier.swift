// KeyboardNavigationModifier.swift

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct KeyboardNavigationModifier: ViewModifier {
    @FocusState private var focusedField: Field?
    @Binding var currentIndex: Int
    let totalItems: Int
    let onSelect: (Int) -> Void

    enum Field: Hashable {
        case item(Int)
    }

    func body(content: Content) -> some View {
        content
            .focused($focusedField, equals: .item(currentIndex))
            .onKeyPress(.upArrow) {
                navigateUp()
                return .handled
            }
            .onKeyPress(.downArrow) {
                navigateDown()
                return .handled
            }
            .onKeyPress(.return) {
                onSelect(currentIndex)
                return .handled
            }
            .onKeyPress(.space) {
                onSelect(currentIndex)
                return .handled
            }
            .onKeyPress(.tab) {
                navigateUp()
                return .handled
            }
            .onKeyPress(.tab) {
                navigateDown()
                return .handled
            }
            .onKeyPress("j") {
                navigateDown()
                return .handled
            }
            .onKeyPress("k") {
                navigateUp()
                return .handled
            }
            .onAppear {
                focusedField = .item(0)
            }
    }

    private func navigateUp() {
        if currentIndex > 0 {
            currentIndex -= 1
            focusedField = .item(currentIndex)
        }
    }

    private func navigateDown() {
        if currentIndex < totalItems - 1 {
            currentIndex += 1
            focusedField = .item(currentIndex)
        }
    }
}

extension View {
    func keyboardNavigable(currentIndex: Binding<Int>, totalItems: Int, onSelect: @escaping (Int) -> Void) -> some View {
        modifier(KeyboardNavigationModifier(currentIndex: currentIndex, totalItems: totalItems, onSelect: onSelect))
    }
}

// MARK: - Quiz View with Keyboard Navigation

struct QuizViewWithKeyboard: View {
    @StateObject private var quizModel = QuizModel()
    @State private var selectedAnswerIndex = 0
    @FocusState private var focusedAnswer: Int?

    var currentQuestion: QuizQuestion? {
        guard quizModel.currentQuestionIndex < quizModel.questions.count else { return nil }
        return quizModel.questions[quizModel.currentQuestionIndex]
    }

    var body: some View {
        VStack(spacing: 20) {
            questionContent
        }
        .onAppear {
            focusSelectedAnswer()
        }
    }

    @ViewBuilder
    private var questionContent: some View {
        if let question = currentQuestion {
            Text(question.text)
                .font(.title2)
                .padding()

            optionsSection(for: question)

            navigationButtons
        }
    }

    @ViewBuilder
    private func optionsSection(for question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                AnswerButton(
                    text: option.text,
                    isSelected: selectedAnswerIndex == index,
                    index: index
                ) {
                    selectAnswer(index)
                }
                .focused($focusedAnswer, equals: index)
                .onKeyPress(.return) {
                    selectAnswer(index)
                    return .handled
                }
                .onKeyPress(.space) {
                    selectAnswer(index)
                    return .handled
                }
            }
        }
        .onKeyPress(.upArrow) {
            moveSelection(isMovingUp: true, totalOptions: question.options.count)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(isMovingUp: false, totalOptions: question.options.count)
            return .handled
        }
        .onKeyPress("1") {
            handleNumericSelection(0, totalOptions: question.options.count)
            return .handled
        }
        .onKeyPress("2") {
            handleNumericSelection(1, totalOptions: question.options.count)
            return .handled
        }
        .onKeyPress("3") {
            handleNumericSelection(2, totalOptions: question.options.count)
            return .handled
        }
        .onKeyPress("4") {
            handleNumericSelection(3, totalOptions: question.options.count)
            return .handled
        }
        .onKeyPress("5") {
            handleNumericSelection(4, totalOptions: question.options.count)
            return .handled
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 20) {
            Button("Previous") {
                previousQuestion()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)
            .disabled(quizModel.currentQuestionIndex == 0)

            Button("Next") {
                nextQuestion()
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)
            .disabled(!quizModel.hasAnsweredCurrentQuestion)
        }
    }

    private func selectAnswer(_ index: Int) {
        updateSelection(to: index)
        quizModel.selectAnswer(index)
    }

    private func moveSelection(isMovingUp: Bool, totalOptions: Int) {
        if isMovingUp {
            guard selectedAnswerIndex > 0 else { return }
            updateSelection(to: selectedAnswerIndex - 1)
        } else {
            guard selectedAnswerIndex < totalOptions - 1 else { return }
            updateSelection(to: selectedAnswerIndex + 1)
        }
    }

    private func handleNumericSelection(_ index: Int, totalOptions: Int) {
        guard index < totalOptions else { return }
        selectAnswer(index)
    }

    private func updateSelection(to index: Int) {
        selectedAnswerIndex = index
        focusSelectedAnswer()
    }

    private func focusSelectedAnswer() {
        focusedAnswer = selectedAnswerIndex
    }

    private func nextQuestion() {
        quizModel.nextQuestion()
        selectedAnswerIndex = 0
        focusSelectedAnswer()
    }

    private func previousQuestion() {
        quizModel.previousQuestion()
        selectedAnswerIndex = 0
        focusSelectedAnswer()
    }
}

struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let index: Int
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(index + 1).")
                    .fontWeight(.semibold)
                    .frame(width: 30, alignment: .leading)

                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .buttonFocusIndicator(isFocused: $isFocused)
        .accessibilityLabel("Option \(index + 1): \(text)")
        .accessibilityHint(isSelected ? "Selected answer" : "Tap to select this answer")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onTapGesture {
            HapticFeedback.shared.selectionChanged()
            action()
        }
    }
}

// MARK: - Profile List with Keyboard Navigation

struct ProfileListWithKeyboard: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var selectedIndex = 0
    @FocusState private var focusedProfile: UUID?

    var body: some View {
        List(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
            ProfileRow(profile: profile, isSelected: selectedIndex == index)
                .focused($focusedProfile, equals: profile.id)
                .onTapGesture {
                    selectProfile(at: index)
                }
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
                focusProfile()
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < profileManager.profiles.count - 1 {
                selectedIndex += 1
                focusProfile()
            }
            return .handled
        }
        .onKeyPress(.return) {
            openProfile()
            return .handled
        }
        .onKeyPress(.delete) {
            deleteCurrentProfile()
            return .handled
        }
        .onKeyPress(KeyEquivalent("d")) {
            duplicateCurrentProfile()
            return .handled
        }
        .onKeyPress(KeyEquivalent("e")) {
            exportCurrentProfile()
            return .handled
        }
    }

    private func selectProfile(at index: Int) {
        selectedIndex = index
        profileManager.currentProfile = profileManager.profiles[index]
        focusProfile()
    }

    private func focusProfile() {
        if selectedIndex < profileManager.profiles.count {
            focusedProfile = profileManager.profiles[selectedIndex].id
        }
    }

    private func openProfile() {
        if selectedIndex < profileManager.profiles.count {
            profileManager.currentProfile = profileManager.profiles[selectedIndex]
        }
    }

    private func deleteCurrentProfile() {
        guard selectedIndex < profileManager.profiles.count else { return }
        let profile = profileManager.profiles[selectedIndex]

        Task {
            try? await profileManager.deleteProfile(profile)
        }
    }

    private func duplicateCurrentProfile() {
        guard selectedIndex < profileManager.profiles.count else { return }
        let profile = profileManager.profiles[selectedIndex]

        Task {
            _ = try? await profileManager.duplicateProfile(profile)
        }
    }

    private func exportCurrentProfile() {
        guard selectedIndex < profileManager.profiles.count else { return }
        let profile = profileManager.profiles[selectedIndex]

        _ = try? profileManager.exportProfile(profile)
    }
}

struct ProfileRow: View {
    let profile: QuizProfile
    let isSelected: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(profile.name)
                    .font(.headline)
                Text(profile.dateModified, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .cardFocusIndicator(isFocused: $isFocused)
        .accessibilityLabel("Profile: \(profile.name)")
        .accessibilityHint(isSelected ? "Currently selected profile" : "Tap to select this profile")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onTapGesture {
            HapticFeedback.shared.selectionChanged()
        }
    }
}

// MARK: - Global Keyboard Shortcuts

struct GlobalKeyboardShortcuts: ViewModifier {
    @ObservedObject var profileManager: ProfileManager

    func body(content: Content) -> some View {
        content
            .onKeyPress(KeyEquivalent("n")) {
                createNewProfile()
                return .handled
            }
            .onKeyPress(KeyEquivalent("s")) {
                saveCurrentProfile()
                return .handled
            }
            .onKeyPress(KeyEquivalent("f")) {
                focusSearch()
                return .handled
            }
            .onKeyPress(KeyEquivalent(",")) {
                openSettings()
                return .handled
            }
            .onKeyPress(KeyEquivalent("q")) {
                quitApp()
                return .handled
            }
    }

    private func createNewProfile() {
        Task {
            _ = try? await profileManager.createProfile(name: "New Profile", results: [:])
        }
    }

    private func saveCurrentProfile() {
        guard let profile = profileManager.currentProfile else { return }
        Task {
            try? await profileManager.updateProfile(profile)
        }
    }

    private func focusSearch() {
        // Implement search focus
    }

    private func openSettings() {
        #if os(macOS)
        WindowManager.shared.openWindow(type: .settings) {
            SettingsView()
        }
        #endif
    }

    private func quitApp() {
        #if os(macOS)
        NSApplication.shared.terminate(nil)
        #endif
    }
}

extension View {
    func withGlobalKeyboardShortcuts(profileManager: ProfileManager) -> some View {
        modifier(GlobalKeyboardShortcuts(profileManager: profileManager))
    }
}
