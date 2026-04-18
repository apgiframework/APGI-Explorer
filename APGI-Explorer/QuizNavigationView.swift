import SwiftUI

struct QuizNavigationView: View {
  @Environment(\.presentationMode) private var presentationMode

  var body: some View {
    NavigationStack {
      QuizView()
        .toolbar {
          #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("Done") {
                self.presentationMode.wrappedValue.dismiss()
              }
            }
          #else
            ToolbarItem(placement: .primaryAction) {
              Button("Done") {
                self.presentationMode.wrappedValue.dismiss()
              }
            }
          #endif
        }
    }
    #if os(iOS)
      .navigationViewStyle(StackNavigationViewStyle())
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}
