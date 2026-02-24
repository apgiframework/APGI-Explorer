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
                        """)
                        .font(.body)
                    }
                }

                StandardCard {
                    VStack(alignment: .leading, spacing: LayoutConstants.smallSpacing) {
                        Text("APGI Assessment")
                            .font(.title2.bold())
                        Text("Discover your unique consciousness profile through our comprehensive assessment")
                            .font(.body)
                        Text("Estimated time: 10-15 minutes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // APGI Parameters Overview
                InfoCard(title: "What You'll Discover") {
                    VStack(spacing: LayoutConstants.smallSpacing) {
                        ParameterCard(
                            symbol: "bolt.fill",
                            color: .orange,
                            title: "Prediction Error (ε)",
                            description: "Your sensitivity to surprises and changes"
                        )
                        ParameterCard(
                            symbol: "scale.3d",
                            color: .green,
                            title: "Precision (π)",
                            description: "Which signals you prioritize"
                        )
                        ParameterCard(
                            symbol: "target",
                            color: .purple,
                            title: "Ignition Threshold (θₜ)",
                            description: "What grabs your attention"
                        )
                        ParameterCard(
                            symbol: "figure.walk",
                            color: .blue,
                            title: "Somatic Bias (β)",
                            description: "Your body-world awareness balance"
                        )
                    }
                }

                // Benefits section
                InfoCard(title: "Why Take This Assessment?") {
                    VStack(spacing: LayoutConstants.smallSpacing) {
                        BenefitItem(
                            symbol: "lightbulb.fill",
                            text: "Understand your cognitive strengths and challenges"
                        )
                        BenefitItem(
                            symbol: "chart.bar.fill",
                            text: "Get personalized insights about your consciousness profile"
                        )
                        BenefitItem(
                            symbol: "person.2.fill",
                            text: "Learn how you process information differently from others"
                        )
                        BenefitItem(
                            symbol: "gearshape.fill",
                            text: "Discover strategies tailored to your mind's explorer"
                        )
                    }
                }

                // Start button
                Button(action: {
                    self.showQuiz = true
                }, label: {
                    Text("Begin Assessment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                })
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 30)
                #if os(iOS)
                    .fullScreenCover(isPresented: self.$showQuiz) {
                        QuizNavigationView()
                    }
                #else
                    .sheet(isPresented: self.$showQuiz) {
                            QuizNavigationView()
                                .frame(minWidth: 800, minHeight: 600)
                        }
                #endif

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
