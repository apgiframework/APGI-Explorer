import Intents
import OSLog
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

struct QuizView: View {
  @StateObject private var quizModel = QuizModel()
  @State private var currentQuestionIndex = 0
  @State private var isNavigatingToResults = false
  @State private var handoffActivity: NSUserActivity?
  @State private var isPaused = false
  @State private var draftSaveError: String?

  private let savedQuizKey = "savedQuizState"

  var body: some View {
    self.mainContent
      .navigationBarBackButtonHidden(true)
      .alert("Session could not be saved", isPresented: Binding(
        get: { draftSaveError != nil }, set: { if !$0 { draftSaveError = nil } })) {
        Button("OK", role: .cancel) {}
      } message: { Text(draftSaveError ?? "") }
      .onAppear {
        self.loadQuizState()
        self.quizModel.presentQuestion(at: self.currentQuestionIndex)
        self.setupHandoffActivity()
      }
      .onDisappear {
        self.saveQuizState()
        self.handoffActivity?.invalidate()
        self.handoffActivity = nil
      }
      .onChange(of: self.isNavigatingToResults) { _, isNavigating in
        if isNavigating {
          self.handoffActivity?.invalidate()
          self.handoffActivity = nil
        }
      }
      .onChange(of: self.currentQuestionIndex) { oldValue, newValue in
        // HIGH-001 Fix: Prevent rapid navigation issues
        guard newValue != oldValue else { return }
        guard newValue >= 0, newValue < self.quizModel.questions.count else { return }
        self.quizModel.presentQuestion(at: newValue)
        self.saveQuizState()
        self.updateHandoffActivity()
      }
      .onChange(of: self.quizModel.answers) { oldValue, newValue in
        // HIGH-001 Fix: Debounce rapid answer changes
        guard newValue != oldValue else { return }
        self.saveQuizState()
        self.updateHandoffActivity()
      }
      .onContinueUserActivity(HandoffActivity.activityType) { userActivity in
        if let restoredAnswers = HandoffActivity.restoreUserActivity(
          userActivity,
          currentQuestionIndex: $currentQuestionIndex
        ) {
          self.quizModel.restoreAnswers(restoredAnswers)
          ConsoleAnalyticsService.shared.track(event: .handoffActivityRestored)
        }
      }
      .userActivity(HandoffActivity.activityType) { activity in
        activity.isEligibleForSearch = false
        activity.isEligibleForPublicIndexing = false
        // This ensures the activity is updated in the system
        if let handoffActivity {
          activity.userInfo = handoffActivity.userInfo
        }
      }
  }

  @ViewBuilder
  private var mainContent: some View {
    if self.isPaused {
      self.pausedContent
    } else {
      self.quizContent
    }
  }

  private var quizContent: some View {
    VStack(spacing: 0) {
      self.progressBarSection
      self.progressTextSection

      if self.currentQuestionIndex < self.quizModel.questions.count {
        self.currentSectionSection
        self.questionSection
        self.navigationButtonsSection
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: self.pauseQuiz) {
          Label("Pause", systemImage: "pause.fill")
        }
      }
    }
  }

  private var pausedContent: some View {
    VStack {
      Spacer()
      Text("Quiz Paused")
        .font(.largeTitle)
        .padding()
      Text("Your progress has been saved.")
        .font(.body)
        .foregroundColor(.secondary)
        .padding()
      Button(action: self.resumeQuiz) {
        Label("Resume Quiz", systemImage: "play.fill")
          .font(.title)
          .padding()
      }
      .buttonStyle(PrimaryButtonStyle())
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
  }

  private var progressBarSection: some View {
    ProgressView(
      value: Double(self.currentQuestionIndex + 1), total: Double(self.quizModel.questions.count)
    )
    .progressViewStyle(.linear)
    .tint(.blue)
    .padding(.horizontal)
    .padding(.top, 8)
  }

  private var progressTextSection: some View {
    Text("Question \(self.currentQuestionIndex + 1) of \(self.quizModel.questions.count)")
      .font(.caption)
      .foregroundColor(.secondary)
  }

  private var liveScoreSection: some View {
    LiveScoreTracker(quizModel: self.quizModel)
      .padding(.horizontal)
  }

  private var currentSectionSection: some View {
    Text(self.sectionName(for: self.quizModel.questions[self.currentQuestionIndex]))
      .font(.caption)
      .foregroundColor(.blue)
      .padding(.vertical, 4)
  }

  private var questionSection: some View {
    QuestionView(
      question: self.quizModel.questions[self.currentQuestionIndex],
      selectedAnswer: self.quizModel.answers[
        self.quizModel.questions[self.currentQuestionIndex].id],
      onAnswer: { answer in
        self.quizModel.selectAnswer(
          for: self.quizModel.questions[self.currentQuestionIndex].id, answer: answer)
      }
    )
  }

  private var navigationButtonsSection: some View {
    HStack {
      if self.currentQuestionIndex > 0 {
        Button(
          action: { self.currentQuestionIndex -= 1 },
          label: {
            Label("Previous", systemImage: "chevron.left")
          }
        )
        .buttonStyle(SecondaryButtonStyle())
      }

      Spacer()

      if self.currentQuestionIndex < self.quizModel.questions.count - 1 {
        Button(
          action: {
            if self.quizModel.answers[self.quizModel.questions[self.currentQuestionIndex].id] != nil {
              self.currentQuestionIndex += 1
            }
          },
          label: {
            Label("Next", systemImage: "chevron.right")
          }
        )
        .buttonStyle(PrimaryButtonStyle())
        .disabled(
          self.quizModel.answers[self.quizModel.questions[self.currentQuestionIndex].id] == nil)
      } else {
        NavigationLink(
          destination: ResultsView(quizModel: self.quizModel),
          label: {
            Label("See Results", systemImage: "chart.bar.fill")
          }
        )
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!self.quizModel.isComplete)
        .onTapGesture {
          self.isNavigatingToResults = true
        }
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }

  private func setupHandoffActivity() {
    self.handoffActivity = HandoffActivity.createUserActivity(
      quizModel: self.quizModel,
      currentQuestionIndex: self.currentQuestionIndex
    )
    self.handoffActivity?.becomeCurrent()
  }

  private func updateHandoffActivity() {
    self.handoffActivity?.invalidate()
    self.handoffActivity = HandoffActivity.createUserActivity(
      quizModel: self.quizModel,
      currentQuestionIndex: self.currentQuestionIndex
    )
    self.handoffActivity?.becomeCurrent()
  }

  private func pauseQuiz() {
    self.saveQuizState()
    self.isPaused = true
  }

  private func resumeQuiz() {
    self.quizModel.presentQuestion(at: self.currentQuestionIndex)
    self.isPaused = false
  }

  private func saveQuizState() {
    do {
      let state = quizModel.snapshot(at: currentQuestionIndex)
      let data = try JSONEncoder().encode(state)
      try PersistenceController.shared.savePersonalSession(state)
      if quizModel.isComplete && isNavigatingToResults { clearQuizState() } else { UserDefaults.standard.set(data, forKey: self.savedQuizKey) }
    } catch {
      draftSaveError = error.localizedDescription
      os_log("Could not save local session: %{public}@", error.localizedDescription)
    }
  }

  private func loadQuizState() {
    guard let data = UserDefaults.standard.data(forKey: savedQuizKey) else { return }
    do {
      let state = try JSONDecoder().decode(QuizModel.Snapshot.self, from: data)
      quizModel.restore(state)
      currentQuestionIndex = quizModel.currentQuestionIndex
    } catch {
      // Legacy drafts lack item-event provenance and are not research sessions.
      clearQuizState()
    }
  }

  private func clearQuizState() {
    UserDefaults.standard.removeObject(forKey: self.savedQuizKey)
  }

  private func sectionName(for question: QuizQuestion) -> String {
    switch question.parameter {
    case "epsilon": ScoreLabels.reactivity
    case "precision": ScoreLabels.prioritisation
    case "threshold": ScoreLabels.threshold
    case "somatic": ScoreLabels.bodySignal
    case "interactions": "Parameter Interactions"
    case "temporal": "Temporal Stability"
    case "environment": "Environmental Fit"
    default: ""
    }
  }
}

private var toolTipBackground: Color {
  #if os(macOS)
    Color(NSColor.windowBackgroundColor).opacity(0.9)
  #else
    Color(uiColor: .systemGray6)
  #endif
}

private struct QuestionOptionRow: View {
  let option: QuizOption
  let isSelected: Bool
  @Binding var tooltipOptionID: UUID?
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
          .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        Text(option.text).foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)
        Spacer()
      }
      .padding(12)
      .background(RoundedRectangle(cornerRadius: 10)
        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05)))
    }
    .buttonStyle(AppPlainButtonStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

/// Enhanced QuestionView with selection state
struct QuestionView: View {
  let question: QuizQuestion
  let selectedAnswer: Int?
  let onAnswer: (Int) -> Void
  @State private var tooltipOptionID: UUID?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(self.question.text)
        .font(.title3)
        .fontWeight(.medium)
        .fixedSize(horizontal: false, vertical: true)

      ForEach(self.question.options) { option in
        QuestionOptionRow(
          option: option,
          isSelected: self.selectedAnswer == option.value,
          tooltipOptionID: self.$tooltipOptionID,
          onSelect: {
            self.onAnswer(option.value)
          }
        )
      }
    }
    .padding(.horizontal)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
