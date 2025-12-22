import Foundation

protocol AnalyticsService {
    func track(event: AnalyticsEvent)
    func setUserProperty(_ value: String, forKey key: String)
}

enum AnalyticsEvent {
    case stateViewed(id: Int, name: String)
    case transitionExplored(from: Int, to: Int)
    case quizCompleted(resultStateId: Int)
    case profileCreated
    case similarStatesCompared(count: Int)

    var description: String {
        switch self {
        case .stateViewed(let id, let name):
            return "State viewed: \(name) (#\(id))"
        case .transitionExplored(let from, let to):
            return "Transition explored: \(from) → \(to)"
        case .quizCompleted(let resultStateId):
            return "Quiz completed (result state id: \(resultStateId))"
        case .profileCreated:
            return "Profile created"
        case .similarStatesCompared(let count):
            return "Compared \(count) similar states"
        }
    }
}

final class ConsoleAnalyticsService: AnalyticsService {
    private var userProperties: [String: String] = [:]

    func track(event: AnalyticsEvent) {
        let propertiesDescription = userProperties
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        let payload = propertiesDescription.isEmpty ? "" : " • properties: \(propertiesDescription)"
        print("[Analytics] \(event.description)\(payload)")
    }

    func setUserProperty(_ value: String, forKey key: String) {
        userProperties[key] = value
        print("[Analytics] Set user property \(key)=\(value)")
    }
}
