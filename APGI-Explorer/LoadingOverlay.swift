import SwiftUI

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String
    let isVisible: Bool

    init(message: String = "Loading...", isVisible: Bool = true) {
        self.message = message
        self.isVisible = isVisible
    }

    var body: some View {
        if isVisible {
            ZStack {
                AppColors.loadingOverlay
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text(message)
                        .foregroundColor(.white)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.adaptiveGray6)
                        .shadow(radius: 10)
                )
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}

// MARK: - Loading Indicator View

struct LoadingIndicator: View {
    let message: String?
    let size: LoadingSize

    enum LoadingSize {
        case small, medium, large

        var scale: CGFloat {
            switch self {
            case .small: return 0.8
            case .medium: return 1.0
            case .large: return 1.5
            }
        }

        var font: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .headline
            }
        }
    }

    init(message: String? = nil, size: LoadingSize = .medium) {
        self.message = message
        self.size = size
    }

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(size.scale)
                .tint(AppColors.progressTint)

            if let message = message {
                Text(message)
                    .font(size.font)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
}

// MARK: - Full Screen Loading View

struct FullScreenLoadingView: View {
    let message: String
    let showBackground: Bool

    init(message: String = "Loading...", showBackground: Bool = true) {
        self.message = message
        self.showBackground = showBackground
    }

    var body: some View {
        ZStack {
            if showBackground {
                AppColors.primaryBackground
                    .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2.0)
                    .tint(AppColors.progressTint)

                Text(message)
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - Progress Ring View

struct ProgressRingView: View {
    let progress: Double
    let message: String?
    let lineWidth: CGFloat

    init(progress: Double, message: String? = nil, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.message = message
        self.lineWidth = lineWidth
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppColors.adaptiveGray5, lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppColors.progressTint,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primaryText)
            }
            .frame(width: 120, height: 120)

            if let message = message {
                Text(message)
                    .font(.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Previews

struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingOverlay(message: "Loading states...")
                .previewDisplayName("Loading Overlay")

            LoadingIndicator(message: "Processing...", size: .large)
                .previewDisplayName("Loading Indicator")

            FullScreenLoadingView(message: "Analyzing your responses...")
                .previewDisplayName("Full Screen Loading")

            ProgressRingView(progress: 0.75, message: "Generating profile...")
                .previewDisplayName("Progress Ring")
        }
    }
}
