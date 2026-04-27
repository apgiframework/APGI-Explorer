import SwiftUI

struct ContentView: View {
  var body: some View {
    ZStack {
      Color.spaceBlack
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: APGISpacing.giant) {
        // App Title
        VStack(spacing: APGISpacing.sm) {
          Image(systemName: "brain.head.profile")
            .font(.system(size: LayoutConstants.iconFontSize))
            .foregroundColor(.thresholdBlue)

          Text("APGI Explorer")
            .font(APGITypography.h1)
            .foregroundColor(.primary)

          Text("Discover your psychological patterns")
            .font(APGITypography.body)
            .foregroundColor(.secondary)
        }
        .padding(.top, LayoutConstants.topPadding)
        .padding(.bottom, LayoutConstants.titleBottomPadding)

        Spacer()

        VStack(spacing: APGISpacing.md) {
          NavigationLink(destination: IntroView()) {
            HStack {
              Image(systemName: "play.fill")
              Text("Start Quiz")
            }
          }
          .buttonStyle(PrimaryButtonStyle())

          NavigationLink(
            destination: PsychologicalStatesView()
              .environment(\.appDependencies, AppDependencies.shared)
          ) {
            HStack {
              Image(systemName: "book.fill")
              Text("Browse Psychological States")
            }
          }
          .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, LayoutConstants.horizontalPadding)
        .padding(.bottom, LayoutConstants.bottomPadding)
      }
    }
    .accentColor(.thresholdBlue)
  }
}

#Preview {
  ContentView()
}
