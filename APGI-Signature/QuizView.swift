import SwiftUI

struct QuizView: View {
    @StateObject private var quizModel = QuizModel()
    @State private var currentQuestionIndex = 0

    var body: some View {
        VStack {
            if currentQuestionIndex < quizModel.questions.count {
                QuestionView(question: quizModel.questions[currentQuestionIndex]) { answer in
                    quizModel.selectAnswer(for: quizModel.questions[currentQuestionIndex].id, answer: answer)
                    currentQuestionIndex += 1
                }
            } else {
                NavigationLink("See Results") {
                    ResultsView(quizModel: quizModel)
                }
            }
        }
        .padding()
        .navigationTitle("Question \(currentQuestionIndex + 1)")
    }
}

struct QuestionView: View {
    let question: QuizQuestion
    let onAnswer: (Int) -> Void

    var body: some View {
        VStack {
            Text(question.text)
                .font(.title)
            ForEach(question.options) { option in
                Button(action: { onAnswer(option.value) }) {
                    VStack(alignment: .leading) {
                        Text(option.text)
                            .foregroundColor(.white)
                        Text(option.note)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}
