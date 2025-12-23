import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct IntroView: View {
    var body: some View {
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

                    Text("APGI Consciousness Assessment")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Understand Your Mind's Explorer")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                // Introduction section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome to the APGI Assessment")
                        .font(.title2)

                    Text("""
                    This quiz measures four fundamental parameters of consciousness that shape your experience:

                    • **Prediction Error Sensitivity (ε)**: How you respond to surprises and mismatches
                    • **Precision Allocation (π)**: What signals you trust most
                    • **Ignition Threshold (θₜ)**: What captures your awareness
                    • **Somatic Bias (β)**: Whether you're more body- or world-focused
                    """)
                    .font(.body)
                    .foregroundColor(.primary)

                    Text("The assessment consists of 35 questions with 4 response options each. Answer honestly for the most accurate results about your unique cognitive profile.")
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("Estimated time: 10-15 minutes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)

                // APGI Parameters Overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("What You'll Discover")
                        .font(.title2)

                    ParameterCard(symbol: "bolt.fill", color: .orange, title: "Prediction Error (ε)", description: "Your sensitivity to surprises and changes")

                    ParameterCard(symbol: "scale.3d", color: .green, title: "Precision (π)", description: "Which signals you prioritize")

                    ParameterCard(symbol: "target", color: .purple, title: "Ignition Threshold (θₜ)", description: "What grabs your attention")

                    ParameterCard(symbol: "figure.walk", color: .blue, title: "Somatic Bias (β)", description: "Your body-world awareness balance")
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)

                // Benefits section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why Take This Assessment?")
                        .font(.title2)

                    BenefitItem(symbol: "lightbulb.fill", text: "Understand your cognitive strengths and challenges")
                    BenefitItem(symbol: "chart.bar.fill", text: "Get personalized insights about your consciousness profile")
                    BenefitItem(symbol: "person.2.fill", text: "Learn how you process information differently from others")
                    BenefitItem(symbol: "gearshape.fill", text: "Discover strategies tailored to your mind's explorer")
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)

                // Start button
                NavigationLink(destination: QuizView()) {
                    Text("Begin Assessment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom, 30)

                // Footer
                VStack(spacing: 8) {
                    Text("Your results are confidential and saved only on this device")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("APGI Framework ©2025 Consciousness Research Institute")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Introduction")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Helper Views

private struct ParameterCard: View {
    let symbol: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
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
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}
