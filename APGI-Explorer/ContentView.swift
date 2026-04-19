import SwiftUI

struct ContentView: View {
  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [
          Color.accentColor.opacity(ColorConstants.backgroundOpacity),
          Color.secondary.opacity(ColorConstants.backgroundOpacity),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .edgesIgnoringSafeArea(.all)

      VStack(spacing: LayoutConstants.largeSpacing) {
        // App Title
        VStack(spacing: LayoutConstants.smallSpacing) {
          Image(systemName: "brain.head.profile")
            .font(.system(size: LayoutConstants.iconFontSize))
            .foregroundColor(.blue)

          Text("APGI Explorer")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primary)

          Text("Discover your psychological patterns")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.top, LayoutConstants.topPadding)
        .padding(.bottom, LayoutConstants.titleBottomPadding)

        Spacer()

        VStack(spacing: LayoutConstants.mediumSpacing) {
          NavigationLink(destination: IntroView()) {
            HStack {
              Image(systemName: "play.fill")
              Text("Start Quiz")
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.buttonBackground)
            .foregroundColor(AppColors.buttonText)
            .cornerRadius(LayoutConstants.buttonCornerRadius)
            .shadow(radius: LayoutConstants.buttonShadowRadius)
          }

          NavigationLink(
            destination: PsychologicalStatesView()
              .environment(\.appDependencies, AppDependencies.shared)
          ) {
            HStack {
              Image(systemName: "book.fill")
              Text("Browse Psychological States")
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.info)
            .foregroundColor(AppColors.buttonText)
            .cornerRadius(LayoutConstants.buttonCornerRadius)
            .shadow(radius: LayoutConstants.buttonShadowRadius)
          }
        }
        .padding(.horizontal, LayoutConstants.horizontalPadding)
        .padding(.bottom, LayoutConstants.bottomPadding)
      }
    }
    .accentColor(.blue)
  }
}

#Preview {
  ContentView()
}
