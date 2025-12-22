import Foundation

// MARK: - App Error Types

enum AppError: LocalizedError {
    case dataLoadingFailed(underlying: Error)
    case stateNotFound(id: Int)
    case invalidParameters
    case networkError(Error)
    case quizValidationFailed(ValidationResult)
    case profileGenerationFailed
    case exportFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .dataLoadingFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .stateNotFound(let id):
            return "State with ID \(id) not found"
        case .invalidParameters:
            return "Invalid APGI parameters provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .quizValidationFailed(let result):
            return "Quiz validation failed: \(result.warnings.first ?? "Unknown validation error")"
        case .profileGenerationFailed:
            return "Failed to generate APGI profile"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataLoadingFailed, .networkError:
            return "Please check your connection and try again"
        case .stateNotFound:
            return "Try searching for a different state"
        case .invalidParameters:
            return "Please adjust your parameters and try again"
        case .quizValidationFailed(let result):
            if result.completionRate < 0.9 {
                return "Please complete all quiz questions for accurate results"
            } else {
                return "Please review your responses and try again"
            }
        case .profileGenerationFailed:
            return "Please complete the quiz again and ensure all questions are answered"
        case .exportFailed:
            return "Please check your storage space and try again"
        }
    }
}
