import SwiftUI
import Intents

#if canImport(UIKit)
import UIKit
#endif

struct QuizView: View {
    @StateObject private var quizModel = QuizModel()
    @State private var currentQuestionIndex = 0
    @State private var showExitAlert = false
    @State private var handoffActivity: NSUserActivity?
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        mainContent
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        showExitAlert = true
                    }
                }
            }
            .alert("Exit Quiz?", isPresented: $showExitAlert) {
                Button("Continue Quiz", role: .cancel) { }
                Button("Exit", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your progress will be saved.")
                Text("Your progress will be lost if you exit now.")
            }
            .onAppear {
                setupHandoffActivity()
            }
            .onDisappear {
                handoffActivity?.invalidate()
                handoffActivity = nil
            }
            .onChange(of: currentQuestionIndex) { oldValue, newValue in
                // HIGH-001 Fix: Prevent rapid navigation issues
                guard newValue != oldValue else { return }
                guard newValue >= 0 && newValue < quizModel.questions.count else { return }
                updateHandoffActivity()
            }
            .onChange(of: quizModel.answers) { oldValue, newValue in
                // HIGH-001 Fix: Debounce rapid answer changes
                guard newValue != oldValue else { return }
                updateHandoffActivity()
            }
            .onContinueUserActivity(HandoffActivity.activityType) { userActivity in
                if let restoredAnswers = HandoffActivity.restoreUserActivity(
                    userActivity,
                    currentQuestionIndex: $currentQuestionIndex
                ) {
                    quizModel.restoreAnswers(restoredAnswers)
                    ConsoleAnalyticsService.shared.track(event: .handoffActivityRestored)
                }
            }
            .userActivity(HandoffActivity.activityType) { activity in
                // This ensures the activity is updated in the system
                if let handoffActivity = handoffActivity {
                    activity.userInfo = handoffActivity.userInfo
                }
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            progressBarSection
            progressTextSection
            liveScoreSection
            currentSectionSection
            if currentQuestionIndex < quizModel.questions.count {
                questionSection
                navigationButtonsSection
            }
        }
    }

    private var progressBarSection: some View {
        ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quizModel.questions.count))
            .progressViewStyle(.linear)
            .tint(.blue)
            .padding()
    }

    private var progressTextSection: some View {
        Text("Question \(currentQuestionIndex + 1) of \(quizModel.questions.count)")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private var liveScoreSection: some View {
        LiveScoreTracker(quizModel: quizModel)
            .padding(.horizontal)
    }

    private var currentSectionSection: some View {
        Text(sectionName(for: quizModel.questions[currentQuestionIndex]))
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.vertical, 8)
    }

    private var questionSection: some View {
        QuestionView(
            question: quizModel.questions[currentQuestionIndex],
            selectedAnswer: quizModel.answers[quizModel.questions[currentQuestionIndex].id],
            onAnswer: { answer in
                quizModel.selectAnswer(for: quizModel.questions[currentQuestionIndex].id, answer: answer)
            }
        )
    }

    private var navigationButtonsSection: some View {
        HStack {
            if currentQuestionIndex > 0 {
                Button(
                    action: { currentQuestionIndex -= 1 },
                    label: {
                        Label("Previous", systemImage: "chevron.left")
                    }
                )
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentQuestionIndex < quizModel.questions.count - 1 {
                Button(
                    action: {
                        if quizModel.answers[quizModel.questions[currentQuestionIndex].id] != nil {
                            currentQuestionIndex += 1
                        }
                    },
                    label: {
                        Label("Next", systemImage: "chevron.right")
                    }
                )
                .buttonStyle(.borderedProminent)
                .disabled(quizModel.answers[quizModel.questions[currentQuestionIndex].id] == nil)
            } else {
                NavigationLink(
                    destination: ResultsView(quizModel: quizModel),
                    label: {
                        Label("See Results", systemImage: "chart.bar.fill")
                    }
                )
                .buttonStyle(.borderedProminent)
                .disabled(!quizModel.isComplete)
            }
        }
        .padding()
    }

    private func setupHandoffActivity() {
        handoffActivity = HandoffActivity.createUserActivity(
            quizModel: quizModel,
            currentQuestionIndex: currentQuestionIndex
        )
        handoffActivity?.becomeCurrent()
    }

    private func updateHandoffActivity() {
        handoffActivity?.invalidate()
        handoffActivity = HandoffActivity.createUserActivity(
            quizModel: quizModel,
            currentQuestionIndex: currentQuestionIndex
        )
        handoffActivity?.becomeCurrent()
    }

    private func sectionName(for question: QuizQuestion) -> String {
        switch question.parameter {
        case "epsilon": return "Prediction Error Sensitivity"
        case "precision": return "Precision Allocation"
        case "threshold": return "Ignition Threshold"
        case "somatic": return "Somatic Bias"
        case "interactions": return "Parameter Interactions"
        case "temporal": return "Temporal Stability"
        case "environment": return "Environmental Fit"
        default: return ""
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
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: isSelected ? "circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.text)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(option.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: toggleTooltip) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            if tooltipOptionID == option.id {
                Text(option.tooltip)
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
        tooltipOptionID = tooltipOptionID == option.id ? nil : option.id
    }
}

// Enhanced QuestionView with selection state
struct QuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: Int?
    let onAnswer: (Int) -> Void
    @State private var tooltipOptionID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(question.text)
                    .font(.title2)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(question.options) { option in
                    QuestionOptionRow(
                        option: option,
                        isSelected: selectedAnswer == option.value,
                        tooltipOptionID: $tooltipOptionID,
                        onSelect: {
                            onAnswer(option.value)
                        }
                    )
                }
            }
            .padding()
        }
    }
}
