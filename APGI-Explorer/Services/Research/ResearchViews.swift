import SwiftUI

/// Entry point shown in Settings. Renders nothing unless research is both approved in this build
/// and enabled by the server.
struct ResearchEntryView: View {
  @ObservedObject private var model = ResearchModel.shared
  @State private var showFlow = false

  var body: some View {
    Group {
      if model.isAvailable {
        VStack(alignment: .leading, spacing: 8) {
          Text("Research participation").font(.headline)
          Text("Optional. Your personal results stay on this device unless you choose to take part.")
            .font(.caption).foregroundStyle(.secondary)
          Button("Learn more and take part…") { showFlow = true }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .sheet(isPresented: $showFlow) { ResearchFlowView(model: model) }
      }
    }
    .task { await model.refreshAvailability() }
  }
}

struct ResearchFlowView: View {
  @ObservedObject var model: ResearchModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      switch model.phase {
      case .unavailable:
        Text("Research is not available right now.")
      case .idle, .preparing:
        ResearchIntroPane(model: model)
      case .consent:
        ResearchConsentPane(model: model)
      case .signIn:
        ResearchSignInPane(model: model)
      case .questionnaire:
        ResearchQuestionPane(model: model)
      case .finishing:
        ProgressView("Checking that all answers reached the server…")
      case .result(let scores):
        ResearchResultPane(scores: scores)
      case .failed(let message):
        Text(message)
      }
      if let message = model.errorMessage {
        Text(message).foregroundStyle(.red).textSelection(.enabled)
      }
      HStack {
        Spacer()
        Button("Close") { model.close(); dismiss() }
      }
    }
    .padding(24)
    .frame(minWidth: 520, minHeight: 460)
  }
}

private struct ResearchIntroPane: View {
  @ObservedObject var model: ResearchModel
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Take part in research").font(.title2)
      Text("You will read each consent text, then answer the same 35 questions as the personal questionnaire. "
           + "Answers are uploaded to the study; the app checks that every one arrived before removing its local copy.")
      Button(model.phase == .preparing ? "Checking…" : "Continue") { Task { await model.begin() } }
        .disabled(model.phase == .preparing)
    }
  }
}

private struct ResearchConsentPane: View {
  @ObservedObject var model: ResearchModel
  @State private var accepted: Set<String> = []

  var body: some View {
    let prepared = model.preparation
    VStack(alignment: .leading, spacing: 12) {
      Text("Consent").font(.title2)
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          ForEach(prepared?.consentTexts ?? [], id: \.purpose) { text in
            let required = prepared?.requiredPurposes.contains(text.purpose) == true
            VStack(alignment: .leading, spacing: 6) {
              Text(text.title).font(.headline)
              Text(text.body).textSelection(.enabled)
              Toggle(required ? "I agree (required)" : "I agree (optional)", isOn: Binding(
                get: { accepted.contains(text.purpose) },
                set: { on in if on { accepted.insert(text.purpose) } else { accepted.remove(text.purpose) } }))
            }
          }
        }
      }
      Button("Continue") {
        model.setAccepted(accepted)
        model.continueFromConsent()
      }
      .disabled(!(prepared?.requiredPurposes ?? []).isSubset(of: accepted))
    }
  }
}

private struct ResearchSignInPane: View {
  @ObservedObject var model: ResearchModel
  @State private var username = ""
  @State private var password = ""
  @State private var email = ""
  @State private var creating = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(creating ? "Create a research account" : "Sign in").font(.title2)
      TextField("Username", text: $username)
      if creating { TextField("Email", text: $email) }
      SecureField("Password", text: $password)
      HStack {
        Button(creating ? "Create account and start" : "Sign in and start") {
          Task {
            await model.signInAndEnroll(username: username, password: password,
                                        email: creating ? email : nil, accepted: model.acceptedPurposes)
          }
        }
        .disabled(username.isEmpty || password.isEmpty || (creating && email.isEmpty))
        Button(creating ? "I already have an account" : "Create an account") { creating.toggle() }
      }
    }
  }
}

private struct ResearchQuestionPane: View {
  @ObservedObject var model: ResearchModel
  @State private var index = 0

  var body: some View {
    let items = model.preparation?.bank.items ?? []
    VStack(alignment: .leading, spacing: 12) {
      if items.indices.contains(index) {
        let item = items[index]
        Text("Question \(index + 1) of \(items.count)").font(.caption).foregroundStyle(.secondary)
        Text(item.text).font(.title3)
        ForEach(item.optionValues, id: \.self) { value in
          Button {
            Task { await model.answer(itemID: item.id, value: value) }
          } label: {
            HStack {
              Image(systemName: model.answers[item.id] == value ? "largecircle.fill.circle" : "circle")
              Text(item.optionTexts[value] ?? "")
              Spacer()
            }
          }
          .buttonStyle(.plain)
        }
        .task(id: index) { await model.show(itemID: item.id) }
      }
      HStack {
        Button("Back") { index = max(0, index - 1) }.disabled(index == 0)
        Button("Next") { index = min(items.count - 1, index + 1) }
          .disabled(index >= items.count - 1 || model.answers[items[safe: index]?.id ?? -1] == nil)
        Spacer()
        if model.pendingUploads > 0 {
          Text("\(model.pendingUploads) answers waiting to upload").font(.caption).foregroundStyle(.secondary)
          Button("Retry upload") { Task { await model.sync() } }
        }
      }
      HStack {
        Button("Withdraw and delete local data", role: .destructive) { Task { await model.withdraw() } }
        Spacer()
        Button("Finish") { Task { await model.finish() } }
          .disabled(model.answers.count != items.count)
      }
    }
  }
}

private struct ResearchResultPane: View {
  let scores: [DisplayedScore]
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Thank you").font(.title2)
      Text("Your answers were received. These self-report summaries are exploratory and are not a diagnosis.")
        .font(.caption).foregroundStyle(.secondary)
      ForEach(scores, id: \.label) { score in
        HStack { Text(score.label); Spacer(); Text(String(format: "%.1f", score.value)) }
      }
    }
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
