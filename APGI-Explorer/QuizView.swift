import Intents
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct QuizView: View {
    @StateObject private var quizModel = QuizModel()
    @State private var currentQuestionIndex = 0
    @State private var isNavigatingToResults = false
    @State private var handoffActivity: NSUserActivity?

    var body: some View {
        self.mainContent
            .navigationBarBackButtonHidden(true)
            .onAppear {
                self.setupHandoffActivity()
            }
            .onDisappear {
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
                self.updateHandoffActivity()
            }
            .onChange(of: self.quizModel.answers) { oldValue, newValue in
                // HIGH-001 Fix: Debounce rapid answer changes
                guard newValue != oldValue else { return }
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
                // This ensures the activity is updated in the system
                if let handoffActivity {
                    activity.userInfo = handoffActivity.userInfo
                }
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            self.progressBarSection
            self.progressTextSection
            self.liveScoreSection
            self.currentSectionSection
            if self.currentQuestionIndex < self.quizModel.questions.count {
                self.questionSection
                self.navigationButtonsSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var progressBarSection: some View {
        ProgressView(value: Double(self.currentQuestionIndex + 1), total: Double(self.quizModel.questions.count))
            .progressViewStyle(.linear)
            .tint(.blue)
            .padding()
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
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.vertical, 8)
    }

    private var questionSection: some View {
        QuestionView(
            question: self.quizModel.questions[self.currentQuestionIndex],
            selectedAnswer: self.quizModel.answers[self.quizModel.questions[self.currentQuestionIndex].id],
            onAnswer: { answer in
                self.quizModel.selectAnswer(for: self.quizModel.questions[self.currentQuestionIndex].id, answer: answer)
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
                .disabled(self.quizModel.answers[self.quizModel.questions[self.currentQuestionIndex].id] == nil)
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
        .padding()
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

    private func sectionName(for question: QuizQuestion) -> String {
        switch question.parameter {
        case "epsilon": "Prediction Error Sensitivity"
        case "precision": "Precision Allocation"
        case "threshold": "Ignition Threshold"
        case "somatic": "Somatic Bias"
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
        VStack(alignment: .leading, spacing: 6) {
            Button(action: self.onSelect) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: self.isSelected ? "circle.fill" : "circle")
                        .foregroundColor(self.isSelected ? .blue : .gray)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(self.option.text)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(self.option.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: self.toggleTooltip) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                    .buttonStyle(AppPlainButtonStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(self.isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(self.isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(AppPlainButtonStyle())

            if self.tooltipOptionID == self.option.id {
                Text(self.option.tooltip)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(toolTipBackground)
                    )
            }
        }
    }

    private func toggleTooltip() {
        self.tooltipOptionID = self.tooltipOptionID == self.option.id ? nil : self.option.id
    }
}

/// Enhanced QuestionView with selection state
struct QuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: Int?
    let onAnswer: (Int) -> Void
    @State private var tooltipOptionID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(self.question.text)
                    .font(.title2)
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
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
