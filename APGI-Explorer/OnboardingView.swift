import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let imageType: ImageType
    let tips: [String]
    let highlightColor: Color

    enum ImageType {
        case system
        case asset
    }
}

let steps: [OnboardingStep] = [
    OnboardingStep(
        title: "Welcome to APGI Explorer",
        subtitle: "Your Cognitive Profile Navigator",
        description: "Discover how your mind works through the APGI framework. " +
            "Explore psychological states, take assessments, and track your cognitive " +
            "journey with precision and insight.",
        imageName: "brain.head.profile",
        imageType: .system,
        tips: [
            "Take the assessment to discover your cognitive profile",
            "Explore how different psychological states are mapped",
            "Compare your results with various cognitive patterns",
            "Track changes in your profile over time"
        ],
        highlightColor: .blue
    ),
    OnboardingStep(
        title: "Interactive Assessment",
        subtitle: "Map Your Cognitive Profile",
        description: "Our comprehensive quiz evaluates your cognitive patterns " +
            "across key APGI dimensions. Answer naturally—there are no right " +
            "or wrong answers, just insights waiting to be discovered.",
        imageName: "doc.text.magnifyingglass",
        imageType: .system,
        tips: [
            "Takes about 15-20 minutes to complete",
            "Save and resume your progress anytime",
            "Questions adapt based on your responses",
            "Get immediate results upon completion"
        ],
        highlightColor: .teal
    ),
    OnboardingStep(
        title: "APGI Framework",
        subtitle: "The Science Behind Your Mind",
        description: "The APGI model breaks down cognition into four key parameters " +
            "that shape your experience. Understanding these helps explain " +
            "how you perceive and interact with the world.",
        imageName: "atom",
        imageType: .system,
        tips: [
            "ε (Prediction Error): Your sensitivity to unexpected events",
            "π (Precision): How you weigh sensory vs. prior information",
            "θₜ (Threshold): Your awareness threshold for stimuli",
            "β (Somatic Bias): How bodily states influence your perception"
        ],
        highlightColor: .indigo
    ),
    OnboardingStep(
        title: "State Explorer",
        subtitle: "Understand Psychological Patterns",
        description: "Browse our comprehensive library of psychological states, " +
            "each mapped to the APGI framework. See how different cognitive " +
            "patterns manifest in thoughts, emotions, and behaviors.",
        imageName: "square.grid.3x3",
        imageType: .system,
        tips: [
            "Search by state name or description",
            "Filter by APGI parameters",
            "View detailed parameter breakdowns",
            "Save favorite states for quick reference"
        ],
        highlightColor: .purple
    ),
    OnboardingStep(
        title: "Profile Insights",
        subtitle: "Your Cognitive Blueprint",
        description: "After completing the assessment, receive a detailed analysis " +
            "of your cognitive profile. See how your scores compare to " +
            "population averages and understand what they mean for your daily experience.",
        imageName: "chart.bar.fill",
        imageType: .system,
        tips: [
            "Visual representation of your cognitive patterns",
            "Personalized insights and observations",
            "Actionable recommendations",
            "Exportable reports for professional review"
        ],
        highlightColor: .orange
    ),
    OnboardingStep(
        title: "Track & Compare",
        subtitle: "Your Cognitive Journey",
        description: "Save multiple assessment results to track how your cognitive " +
            "patterns evolve. Compare different profiles to understand changes " +
            "in your mental landscape over time.",
        imageName: "chart.line.uptrend.xyaxis",
        imageType: .system,
        tips: [
            "Save unlimited profiles",
            "Visual timeline of your progress",
            "Detailed comparison tools",
            "Set reminders for follow-up assessments"
        ],
        highlightColor: .green
    ),
    OnboardingStep(
        title: "Personalized Strategies",
        subtitle: "Optimize Your Mind",
        description: "Based on your profile, discover tailored strategies and " +
            "exercises to enhance your cognitive flexibility, emotional " +
            "regulation, and overall mental well-being.",
        imageName: "sparkles",
        imageType: .system,
        tips: [
            "Daily cognitive exercises",
            "Mindfulness practices",
            "Coping strategies",
            "Growth opportunities"
        ],
        highlightColor: .pink
    ),
    OnboardingStep(
        title: "Ready to Begin?",
        subtitle: "Your Cognitive Adventure Awaits",
        description: "You're all set to explore the fascinating landscape of your mind. " +
            "Start with the assessment or browse psychological states to begin " +
            "your journey of self-discovery.",
        imageName: "checkmark.seal.fill",
        imageType: .system,
        tips: [
            "Take the assessment first for personalized insights",
            "Bookmark interesting states to explore later",
            "Check back regularly for new content",
            "Your data is private and secure"
        ],
        highlightColor: .blue
    )
]

struct OnboardingView: View {
    @State private var currentStep = 0
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack {
            mainContent
            bottomIndicator
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    private var mainContent: some View {
        ZStack {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                stepView(for: step, at: index)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepView(for step: OnboardingStep, at index: Int) -> some View {
        OnboardingStepView(step: step, isLastStep: index == steps.count - 1) {
            if index == steps.count - 1 {
                appState.completeOnboarding()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep += 1
                }
            }
        }
        .opacity(index == currentStep ? 1 : 0)
        .scaleEffect(index == currentStep ? 1 : 0.95)
        .animation(.easeInOut(duration: 0.25), value: currentStep)
        .id("step-\(index)")
    }

    private var bottomIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                indicatorCircle(for: index)
            }
        }
        .padding(.bottom, 20)
    }

    private func indicatorCircle(for index: Int) -> some View {
        Circle()
            .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.5))
            .frame(width: 8, height: 8)
            .scaleEffect(index == currentStep ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: currentStep)
            .accessibleTap(
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = index
                    }
                },
                accessibilityLabel: "Go to step \(index + 1)",
                accessibilityHint: index == currentStep ? "Current step" : "Navigate to onboarding step \(index + 1)"
            )
    }
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    let isLastStep: Bool
    let action: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Image
            Group {
                if step.imageType == .system {
                    Image(systemName: step.imageName)
                        .font(.system(size: 80))
                        .foregroundColor(step.highlightColor)
                } else {
                    Image(step.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            }
            .padding(.bottom, 20)

            // Title and Subtitle
            VStack(spacing: 8) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(step.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .multilineTextAlignment(.center)

            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)

            // Tips
            if !step.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(step.tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(step.highlightColor)
                            Text(tip)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
                .padding(.horizontal, 40)
            }

            Spacer()

            // Buttons
            HStack(spacing: 16) {
                // Close button (only on last step)
                if isLastStep {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(step.highlightColor)
                            .frame(maxWidth: 120)
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(step.highlightColor, lineWidth: 2)
                            )
                            .cornerRadius(10)
                    })
                    .buttonStyle(PlainButtonStyle())
                }

                // Continue/Get Started Button
                Button(action: action, label: {
                    Text(isLastStep ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: isLastStep ? 120 : 200)
                        .padding()
                        .background(step.highlightColor)
                        .cornerRadius(10)
                })
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 40)
        }
        .padding()
        .frame(maxWidth: 600)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        // Reset for preview
        appState.hasCompletedOnboarding = false

        return Group {
            OnboardingView()
                .environmentObject(appState)
                .frame(width: 800, height: 600)

            // Dark mode preview
            OnboardingView()
                .environmentObject(appState)
                .frame(width: 800, height: 600)
                .preferredColorScheme(.dark)
        }
    }
}
