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

struct OnboardingView: View {
    @State private var currentStep = 0
    @EnvironmentObject private var appState: AppState

    private static let steps: [OnboardingStep] = [
        OnboardingStep(
            title: NSLocalizedString("onboarding_welcome_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_welcome_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_welcome_description", comment: ""),
            imageName: "brain.head.profile",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_welcome_tip1", comment: ""),
                NSLocalizedString("onboarding_welcome_tip2", comment: ""),
                NSLocalizedString("onboarding_welcome_tip3", comment: ""),
                NSLocalizedString("onboarding_welcome_tip4", comment: "")
            ],
            highlightColor: .blue
        ),
        OnboardingStep(
            title: NSLocalizedString("onboarding_assessment_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_assessment_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_assessment_description", comment: ""),
            imageName: "doc.text.magnifyingglass",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_assessment_tip1", comment: ""),
                NSLocalizedString("onboarding_assessment_tip2", comment: ""),
                NSLocalizedString("onboarding_assessment_tip3", comment: ""),
                NSLocalizedString("onboarding_assessment_tip4", comment: "")
            ],
            highlightColor: .teal
        ),
        OnboardingStep(
            title: NSLocalizedString("onboarding_framework_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_framework_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_framework_description", comment: ""),
            imageName: "atom",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_framework_tip1", comment: ""),
                NSLocalizedString("onboarding_framework_tip2", comment: ""),
                NSLocalizedString("onboarding_framework_tip3", comment: ""),
                NSLocalizedString("onboarding_framework_tip4", comment: "")
            ],
            highlightColor: .indigo
        ),
        OnboardingStep(
            title: NSLocalizedString("onboarding_explorer_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_explorer_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_explorer_description", comment: ""),
            imageName: "square.grid.3x3",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_explorer_tip1", comment: ""),
                NSLocalizedString("onboarding_explorer_tip2", comment: ""),
                NSLocalizedString("onboarding_explorer_tip3", comment: ""),
                NSLocalizedString("onboarding_explorer_tip4", comment: "")
            ],
            highlightColor: .purple
        ),
        OnboardingStep(
            title: NSLocalizedString("onboarding_insights_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_insights_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_insights_description", comment: ""),
            imageName: "chart.bar.fill",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_insights_tip1", comment: ""),
                NSLocalizedString("onboarding_insights_tip2", comment: ""),
                NSLocalizedString("onboarding_insights_tip3", comment: ""),
                NSLocalizedString("onboarding_insights_tip4", comment: "")
            ],
            highlightColor: .orange
        ),
        OnboardingStep(
            title: NSLocalizedString("onboarding_track_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_track_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_track_description", comment: ""),
            imageName: "chart.line.uptrend.xyaxis",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_track_tip1", comment: ""),
                NSLocalizedString("onboarding_track_tip2", comment: ""),
                NSLocalizedString("onboarding_track_tip3", comment: ""),
                NSLocalizedString("onboarding_track_tip4", comment: "")
            ],
            highlightColor: .green
        ),
        OnboardingStep(
            title: NSLocalizedString("onboarding_strategies_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_strategies_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_strategies_description", comment: ""),
            imageName: "sparkles",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_strategies_tip1", comment: ""),
                NSLocalizedString("onboarding_strategies_tip2", comment: ""),
                NSLocalizedString("onboarding_strategies_tip3", comment: ""),
                NSLocalizedString("onboarding_strategies_tip4", comment: "")
            ],
            highlightColor: .pink
        ),
        OnboardingStep(
            title: NSLocalizedString("onboarding_ready_title", comment: ""),
            subtitle: NSLocalizedString("onboarding_ready_subtitle", comment: ""),
            description: NSLocalizedString("onboarding_ready_description", comment: ""),
            imageName: "checkmark.seal.fill",
            imageType: .system,
            tips: [
                NSLocalizedString("onboarding_ready_tip1", comment: ""),
                NSLocalizedString("onboarding_ready_tip2", comment: ""),
                NSLocalizedString("onboarding_ready_tip3", comment: ""),
                NSLocalizedString("onboarding_ready_tip4", comment: "")
            ],
            highlightColor: .blue
        )
    ]

    var body: some View {
        VStack {
            self.mainContent
            self.bottomIndicator
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    private var mainContent: some View {
        ZStack {
            ForEach(Array(OnboardingView.steps.enumerated()), id: \.offset) { index, step in
                self.stepView(for: step, at: index)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepView(for step: OnboardingStep, at index: Int) -> some View {
        OnboardingStepView(step: step, isLastStep: index == OnboardingView.steps.count - 1) {
            if index == OnboardingView.steps.count - 1 {
                self.appState.completeOnboarding()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentStep += 1
                }
            }
        }
        .opacity(index == self.currentStep ? 1 : 0)
        .scaleEffect(index == self.currentStep ? 1 : 0.95)
        .animation(.easeInOut(duration: 0.25), value: self.currentStep)
        .id("step-\(index)")
    }

    private var bottomIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< OnboardingView.steps.count, id: \.self) { index in
                self.indicatorCircle(for: index)
            }
        }
        .padding(.bottom, 20)
    }

    private func indicatorCircle(for index: Int) -> some View {
        Circle()
            .fill(index == self.currentStep ? Color.blue : Color.gray.opacity(0.5))
            .frame(width: 8, height: 8)
            .scaleEffect(index == self.currentStep ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: self.currentStep)
            .accessibleTap(
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.currentStep = index
                    }
                },
                accessibilityLabel: String(
                    format: NSLocalizedString("onboarding_go_to_step", comment: ""), index + 1
                ),
                accessibilityHint: index == self.currentStep
                    ? NSLocalizedString("onboarding_current_step", comment: "")
                    : String(format: NSLocalizedString("onboarding_navigate_to_step", comment: ""), index + 1)
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
                if self.step.imageType == .system {
                    Image(systemName: self.step.imageName)
                        .font(.system(size: 80))
                        .foregroundColor(self.step.highlightColor)
                } else {
                    Image(self.step.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            }
            .padding(.bottom, 20)

            // Title and Subtitle
            VStack(spacing: 8) {
                Text(self.step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(self.step.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .multilineTextAlignment(.center)

            // Description
            Text(self.step.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)

            // Tips
            if !self.step.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(self.step.tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(self.step.highlightColor)
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
                if self.isLastStep {
                    Button(
                        action: {
                            self.dismiss()
                        },
                        label: {
                            Text(NSLocalizedString("onboarding_close", comment: ""))
                                .font(.headline)
                                .foregroundColor(self.step.highlightColor)
                                .frame(maxWidth: 120)
                                .padding()
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(self.step.highlightColor, lineWidth: 2)
                                )
                                .cornerRadius(10)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }

                // Continue/Get Started Button
                Button(
                    action: self.action,
                    label: {
                        Text(
                            self.isLastStep
                                ? NSLocalizedString("onboarding_get_started", comment: "")
                                : NSLocalizedString("onboarding_continue", comment: "")
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: self.isLastStep ? 120 : 200)
                        .padding()
                        .background(self.step.highlightColor)
                        .cornerRadius(10)
                    }
                )
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
