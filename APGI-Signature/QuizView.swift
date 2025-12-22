import SwiftUI

struct QuizView: View {
    @StateObject private var quizModel = QuizModel()
    @State private var currentQuestionIndex = 0
    @State private var showExitAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quizModel.questions.count))
                .progressViewStyle(.linear)
                .tint(.blue)
                .padding()
            
            // Progress Text
            Text("Question \(currentQuestionIndex + 1) of \(quizModel.questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Current Section
            Text(sectionName(for: quizModel.questions[currentQuestionIndex]))
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.vertical, 8)
            
            if currentQuestionIndex < quizModel.questions.count {
                QuestionView(
                    question: quizModel.questions[currentQuestionIndex],
                    selectedAnswer: quizModel.answers[quizModel.questions[currentQuestionIndex].id]
                ) { answer in
                    quizModel.selectAnswer(for: quizModel.questions[currentQuestionIndex].id, answer: answer)
                }
                
                // Navigation Buttons
                HStack {
                    if currentQuestionIndex > 0 {
                        Button(action: { currentQuestionIndex -= 1 }) {
                            Label("Previous", systemImage: "chevron.left")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentQuestionIndex < quizModel.questions.count - 1 {
                        Button(action: {
                            if quizModel.answers[quizModel.questions[currentQuestionIndex].id] != nil {
                                currentQuestionIndex += 1
                            }
                        }) {
                            Label("Next", systemImage: "chevron.right")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(quizModel.answers[quizModel.questions[currentQuestionIndex].id] == nil)
                    } else {
                        NavigationLink(destination: ResultsView(quizModel: quizModel)) {
                            Label("See Results", systemImage: "chart.bar.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!quizModel.isComplete)
                    }
                }
                .padding()
            }
        }
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
                // Navigate back
            }
        } message: {
            Text("Your progress will be lost if you exit now.")
        }
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

// Enhanced QuestionView with selection state
struct QuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: Int?
    let onAnswer: (Int) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(question.text)
                    .font(.title2)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
                
                ForEach(question.options) { option in
                    Button(action: { onAnswer(option.value) }) {
                        HStack(alignment: .top, spacing: 12) {
                            // Radio button
                            Image(systemName: selectedAnswer == option.value ? "circle.fill" : "circle")
                                .foregroundColor(selectedAnswer == option.value ? .blue : .gray)
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
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedAnswer == option.value ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedAnswer == option.value ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}
