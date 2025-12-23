import SwiftUI

// MARK: - Error View

struct ErrorView: View {
    let error: AppError
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(error.localizedDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if let recovery = error.recoverySuggestion {
                Text(recovery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(error: .networkError(URLError(.notConnectedToInternet))) {
                print("Retry tapped")
            }
            .previewDisplayName("Network Error")
            
            ErrorView(error: .invalidParameters) {
                print("Retry tapped")
            }
            .previewDisplayName("Invalid Parameters")
        }
    }
}
