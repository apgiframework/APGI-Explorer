import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack {
            ZStack {
                // Content
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    if index == currentStep {
                        OnboardingStepView(step: step, isLastStep: index == steps.count - 1) {
                            if index == steps.count - 1 {
                                appState.completeOnboarding()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .transition(.opacity)
                        .id(index)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation {
                                currentStep = index
                            }
                        }
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    let isLastStep: Bool
    let action: () -> Void
    
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
            
            // Continue Button
            Button(action: action) {
                Text(isLastStep ? "Get Started" : "Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(step.highlightColor)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
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
