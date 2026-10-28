import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

struct IntroView: View {
  @State private var showQuiz = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Header with icon
          VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
              .font(.system(size: 60))
              .foregroundColor(.blue)
              .padding()
              .background(Circle().fill(Color.blue.opacity(0.1)))
              .padding(.top, 20)

            Text("APGI Explorer")
              .font(.largeTitle)
              .fontWeight(.bold)

            Text("Exploratory self-report")
              .font(.title2)
              .foregroundColor(.secondary)
          }

          // Introduction section
          VStack(alignment: .leading, spacing: 16) {
            Text("Reflect on your recent experiences")
              .font(.title2)

            Text("This local questionnaire summarises your answers. It is not a validated psychological test or a diagnostic tool.")
              .font(.body)
          }
        }

        StandardCard {
          VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
            Text("35 questions")
              .font(.title2.bold())
            Text("Choose the answer that fits your experience. All items are required. Your answers and changes stay on this device.")
              .font(.body)
            Text("You can pause and resume your local session.")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }

        // APGI Parameters Overview
        InfoCard(title: "What the questionnaire covers") {
          VStack(spacing: LayoutConstants.smallSpacing) {
            ParameterCard(
              symbol: "bolt.fill",
              color: .orange,
              title: "Reported reactivity to the unexpected",
              description: "Your descriptions of responses to unexpected experiences."
            )
            ParameterCard(
              symbol: "scale.3d",
              color: .green,
              title: "Reported information prioritisation",
              description: "Your descriptions of how you prioritise information."
            )
            ParameterCard(
              symbol: "target",
              color: .purple,
              title: "Reported attentional threshold",
              description: "Your descriptions of attention in everyday situations."
            )
            ParameterCard(
              symbol: "figure.walk",
              color: .blue,
              title: "Reported body-signal attention",
              description: "Your descriptions of attention to bodily signals."
            )
          }
        }

        // Benefits section
        InfoCard(title: NSLocalizedString("intro_benefits_title", comment: "")) {
          VStack(spacing: LayoutConstants.smallSpacing) {
            BenefitItem(
              symbol: "lightbulb.fill",
              text: NSLocalizedString("intro_benefit1", comment: "")
            )
            BenefitItem(
              symbol: "chart.bar.fill",
              text: NSLocalizedString("intro_benefit2", comment: "")
            )
            BenefitItem(
              symbol: "person.2.fill",
              text: NSLocalizedString("intro_benefit3", comment: "")
            )
            BenefitItem(
              symbol: "gearshape.fill",
              text: NSLocalizedString("intro_benefit4", comment: "")
            )
          }
        }

        // Start button
        Button(
          action: {
            self.showQuiz = true
          },
          label: {
            Text(NSLocalizedString("intro_begin_assessment", comment: ""))
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
          }
        )
        .buttonStyle(PrimaryButtonStyle())
        .padding(.bottom, 30)
        #if os(iOS)
          .fullScreenCover(isPresented: self.$showQuiz) {
            QuizNavigationView()
          }
        #else
          .sheet(isPresented: self.$showQuiz) {
            QuizNavigationView()
            .frame(minWidth: 800, minHeight: 900)
          }
        #endif

        // Footer
        VStack(spacing: 8) {
          Text(NSLocalizedString("intro_footer_confidential", comment: ""))
            .font(.footnote)
            .foregroundColor(.secondary)

          Text(NSLocalizedString("intro_footer_copyright", comment: ""))
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .padding()
    }
    .navigationTitle(NSLocalizedString("intro_navigation_title", comment: ""))
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  // MARK: - Helper Views

  private struct ParameterCard: View {
    let symbol: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
      HStack(spacing: 12) {
        Image(systemName: self.symbol)
          .font(.title2)
          .foregroundColor(self.color)
          .frame(width: 40)

        VStack(alignment: .leading, spacing: 4) {
          Text(self.title)
            .font(.headline)
          Text(self.description)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()
      }
    }
  }

  private struct BenefitItem: View {
    let symbol: String
    let text: String

    var body: some View {
      HStack(spacing: 12) {
        Image(systemName: self.symbol)
          .font(.subheadline)
          .foregroundColor(.blue)
          .frame(width: 20)

        Text(self.text)
          .font(.subheadline)

        Spacer()
      }
    }
  }
}
