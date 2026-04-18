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
      .focused(self.$focusedField, equals: .item(self.currentIndex))
      .onKeyPress(.upArrow) {
        self.navigateUp()
        return .handled
      }
      .onKeyPress(.downArrow) {
        self.navigateDown()
        return .handled
      }
      .onKeyPress(.return) {
        self.onSelect(self.currentIndex)
        return .handled
      }
      .onKeyPress(.space) {
        self.onSelect(self.currentIndex)
        return .handled
      }
      .onKeyPress(.tab) {
        self.navigateUp()
        return .handled
      }
      .onKeyPress(.tab) {
        self.navigateDown()
        return .handled
      }
      .onKeyPress("j") {
        self.navigateDown()
        return .handled
      }
      .onKeyPress("k") {
        self.navigateUp()
        return .handled
      }
      .onAppear {
        self.focusedField = .item(0)
      }
  }

  private func navigateUp() {
    if self.currentIndex > 0 {
      self.currentIndex -= 1
      self.focusedField = .item(self.currentIndex)
    }
  }

  private func navigateDown() {
    if self.currentIndex < self.totalItems - 1 {
      self.currentIndex += 1
      self.focusedField = .item(self.currentIndex)
    }
  }
}

extension View {
  func keyboardNavigable(
    currentIndex: Binding<Int>, totalItems: Int, onSelect: @escaping (Int) -> Void
  ) -> some View {
    modifier(
      KeyboardNavigationModifier(
        currentIndex: currentIndex, totalItems: totalItems, onSelect: onSelect))
  }
}

// MARK: - Quiz View with Keyboard Navigation

struct QuizViewWithKeyboard: View {
  @StateObject private var quizModel = QuizModel()
  @State private var selectedAnswerIndex = 0
  @FocusState private var focusedAnswer: Int?

  var currentQuestion: QuizQuestion? {
    guard self.quizModel.currentQuestionIndex < self.quizModel.questions.count else { return nil }
    return self.quizModel.questions[self.quizModel.currentQuestionIndex]
  }

  var body: some View {
    VStack(spacing: 20) {
      self.questionContent
    }
    .onAppear {
      self.focusSelectedAnswer()
    }
  }

  @ViewBuilder
  private var questionContent: some View {
    if let question = currentQuestion {
      Text(question.text)
        .font(.title2)
        .padding()

      self.optionsSection(for: question)

      self.navigationButtons
    }
  }

  private func optionsSection(for question: QuizQuestion) -> some View {
    VStack(spacing: 12) {
      ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
        AnswerButton(
          text: option.text,
          isSelected: self.selectedAnswerIndex == index,
          index: index
        ) {
          self.selectAnswer(index)
        }
        .focused(self.$focusedAnswer, equals: index)
        .onKeyPress(.return) {
          self.selectAnswer(index)
          return .handled
        }
        .onKeyPress(.space) {
          self.selectAnswer(index)
          return .handled
        }
      }
    }
    .onKeyPress(.upArrow) {
      self.moveSelection(isMovingUp: true, totalOptions: question.options.count)
      return .handled
    }
    .onKeyPress(.downArrow) {
      self.moveSelection(isMovingUp: false, totalOptions: question.options.count)
      return .handled
    }
    .onKeyPress("1") {
      self.handleNumericSelection(0, totalOptions: question.options.count)
      return .handled
    }
    .onKeyPress("2") {
      self.handleNumericSelection(1, totalOptions: question.options.count)
      return .handled
    }
    .onKeyPress("3") {
      self.handleNumericSelection(2, totalOptions: question.options.count)
      return .handled
    }
    .onKeyPress("4") {
      self.handleNumericSelection(3, totalOptions: question.options.count)
      return .handled
    }
    .onKeyPress("5") {
      self.handleNumericSelection(4, totalOptions: question.options.count)
      return .handled
    }
  }

  private var navigationButtons: some View {
    HStack(spacing: 20) {
      Button("Previous") {
        self.previousQuestion()
      }
      .keyboardShortcut(.leftArrow, modifiers: .command)
      .disabled(self.quizModel.currentQuestionIndex == 0)

      Button("Next") {
        self.nextQuestion()
      }
      .keyboardShortcut(.rightArrow, modifiers: .command)
      .disabled(!self.quizModel.hasAnsweredCurrentQuestion)
    }
  }

  private func selectAnswer(_ index: Int) {
    self.updateSelection(to: index)
    self.quizModel.selectAnswer(index)
  }

  private func moveSelection(isMovingUp: Bool, totalOptions: Int) {
    if isMovingUp {
      guard self.selectedAnswerIndex > 0 else { return }
      self.updateSelection(to: self.selectedAnswerIndex - 1)
    } else {
      guard self.selectedAnswerIndex < totalOptions - 1 else { return }
      self.updateSelection(to: self.selectedAnswerIndex + 1)
    }
  }

  private func handleNumericSelection(_ index: Int, totalOptions: Int) {
    guard index < totalOptions else { return }
    self.selectAnswer(index)
  }

  private func updateSelection(to index: Int) {
    self.selectedAnswerIndex = index
    self.focusSelectedAnswer()
  }

  private func focusSelectedAnswer() {
    self.focusedAnswer = self.selectedAnswerIndex
  }

  private func nextQuestion() {
    self.quizModel.nextQuestion()
    self.selectedAnswerIndex = 0
    self.focusSelectedAnswer()
  }

  private func previousQuestion() {
    self.quizModel.previousQuestion()
    self.selectedAnswerIndex = 0
    self.focusSelectedAnswer()
  }
}

struct AnswerButton: View {
  let text: String
  let isSelected: Bool
  let index: Int
  let action: () -> Void
  @FocusState private var isFocused: Bool

  var body: some View {
    Button(action: self.action) {
      HStack {
        Text("\(self.index + 1).")
          .fontWeight(.semibold)
          .frame(width: 30, alignment: .leading)

        Text(self.text)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(self.isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
      )
    }
    .buttonStyle(.plain)
    .buttonFocusIndicator(isFocused: self.$isFocused)
    .accessibilityLabel("Option \(self.index + 1): \(self.text)")
    .accessibilityHint(self.isSelected ? "Selected answer" : "Tap to select this answer")
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    .onTapGesture {
      HapticFeedback.shared.selectionChanged()
      self.action()
    }
  }
}

// MARK: - Profile List with Keyboard Navigation

struct ProfileListWithKeyboard: View {
  @ObservedObject var profileManager: ProfileManager
  @State private var selectedIndex = 0
  @FocusState private var focusedProfile: UUID?

  var body: some View {
    List(Array(self.profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
      ProfileRow(profile: profile, isSelected: self.selectedIndex == index)
        .focused(self.$focusedProfile, equals: profile.id)
        .onTapGesture {
          self.selectProfile(at: index)
        }
    }
    .onKeyPress(.upArrow) {
      if self.selectedIndex > 0 {
        self.selectedIndex -= 1
        self.focusProfile()
      }
      return .handled
    }
    .onKeyPress(.downArrow) {
      if self.selectedIndex < self.profileManager.profiles.count - 1 {
        self.selectedIndex += 1
        self.focusProfile()
      }
      return .handled
    }
    .onKeyPress(.return) {
      self.openProfile()
      return .handled
    }
    .onKeyPress(.delete) {
      self.deleteCurrentProfile()
      return .handled
    }
    .onKeyPress(KeyEquivalent("d")) {
      self.duplicateCurrentProfile()
      return .handled
    }
    .onKeyPress(KeyEquivalent("e")) {
      self.exportCurrentProfile()
      return .handled
    }
  }

  private func selectProfile(at index: Int) {
    self.selectedIndex = index
    self.profileManager.currentProfile = self.profileManager.profiles[index]
    self.focusProfile()
  }

  private func focusProfile() {
    if self.selectedIndex < self.profileManager.profiles.count {
      self.focusedProfile = self.profileManager.profiles[self.selectedIndex].id
    }
  }

  private func openProfile() {
    if self.selectedIndex < self.profileManager.profiles.count {
      self.profileManager.currentProfile = self.profileManager.profiles[self.selectedIndex]
    }
  }

  private func deleteCurrentProfile() {
    guard self.selectedIndex < self.profileManager.profiles.count else { return }
    let profile = self.profileManager.profiles[self.selectedIndex]

    Task {
      try? await self.profileManager.deleteProfile(profile)
    }
  }

  private func duplicateCurrentProfile() {
    guard self.selectedIndex < self.profileManager.profiles.count else { return }
    let profile = self.profileManager.profiles[self.selectedIndex]

    Task {
      _ = try? await self.profileManager.duplicateProfile(profile)
    }
  }

  private func exportCurrentProfile() {
    guard self.selectedIndex < self.profileManager.profiles.count else { return }
    let profile = self.profileManager.profiles[self.selectedIndex]

    _ = try? self.profileManager.exportProfile(profile)
  }
}

struct ProfileRow: View {
  let profile: QuizProfile
  let isSelected: Bool
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(self.profile.name)
          .font(.headline)
        Text(self.profile.dateModified, style: .date)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      if self.isSelected {
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.accentColor)
      }
    }
    .padding()
    .background(self.isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    .cornerRadius(8)
    .cardFocusIndicator(isFocused: self.$isFocused)
    .accessibilityLabel("Profile: \(self.profile.name)")
    .accessibilityHint(
      self.isSelected ? "Currently selected profile" : "Tap to select this profile"
    )
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
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
        self.createNewProfile()
        return .handled
      }
      .onKeyPress(KeyEquivalent("s")) {
        self.saveCurrentProfile()
        return .handled
      }
      .onKeyPress(KeyEquivalent("f")) {
        self.focusSearch()
        return .handled
      }
      .onKeyPress(KeyEquivalent(",")) {
        self.openSettings()
        return .handled
      }
      .onKeyPress(KeyEquivalent("q")) {
        self.quitApp()
        return .handled
      }
  }

  private func createNewProfile() {
    Task {
      _ = try? await self.profileManager.createProfile(name: "New Profile", results: [:])
    }
  }

  private func saveCurrentProfile() {
    guard let profile = profileManager.currentProfile else { return }
    Task {
      try? await self.profileManager.updateProfile(profile)
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
