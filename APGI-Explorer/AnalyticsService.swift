import Foundation
import os.log
import OSLog

protocol AnalyticsService {
    func track(event: AnalyticsEvent)
    func setUserProperty(_ value: String, forKey key: String)
    func setUserId(_ id: String?)
    func enable(_ enabled: Bool)
}

enum AnalyticsEvent {
    // Quiz Events
    case quizStarted
    case quizCompleted(profileType: APGIProfileType, score: Double, duration: TimeInterval)
    case quizQuestionAnswered(questionId: UUID, questionIndex: Int, answerValue: Int, timeSpent: TimeInterval)
    case quizExited(progress: Double, questionsAnswered: Int)

    // State Navigation Events
    case stateViewed(id: Int, name: String)
    case stateExplored(id: Int, name: String, duration: TimeInterval)
    case transitionExplored(from: Int, toState: Int)

    // Profile Events
    case profileCreated(profileType: APGIProfileType)
    case profileViewed(profileType: APGIProfileType)
    case profileCompared(profileTypes: [APGIProfileType])
    case profileShared(profileType: APGIProfileType, method: String)
    case profileExported(profileType: APGIProfileType, format: String)

    // Comparison Events
    case similarStatesCompared(count: Int, stateIds: [Int])
    case comparisonStarted(profileTypes: [APGIProfileType])

    // Content Events
    case contentShared(contentType: String, id: String, method: String)
    case contentBookmarked(contentType: String, id: String)
    case contentSearched(query: String, resultCount: Int)

    // Settings & Preferences
    case parameterAdjusted(parameter: String, oldValue: Double, newValue: Double)
    case settingChanged(setting: String, value: Any)
    case notificationPreferenceChanged(type: String, enabled: Bool)

    // App Lifecycle
    case appLaunched
    case appBackgrounded
    case appForegrounded
    case appUpdated(previousVersion: String, newVersion: String)
    case appTerminated

    // Navigation
    case screenViewed(screenName: String)
    case deepLinkReceived(url: String)
    case handoffActivityRestored

    // Error & Performance
    case errorOccurred(error: String, context: String)
    case performanceMetric(name: String, duration: TimeInterval, metadata: [String: Any])
    case crashReported(error: Error, context: String)

    var name: String {
        switch self {
        // Quiz Events
        case .quizStarted: "quiz_started"
        case .quizCompleted: "quiz_completed"
        case .quizQuestionAnswered: "quiz_question_answered"
        case .quizExited: "quiz_exited"
        // State Navigation Events
        case .stateViewed: "state_viewed"
        case .stateExplored: "state_explored"
        case .transitionExplored: "transition_explored"
        // Profile Events
        case .profileCreated: "profile_created"
        case .profileViewed: "profile_viewed"
        case .profileCompared: "profile_compared"
        case .profileShared: "profile_shared"
        case .profileExported: "profile_exported"
        // Comparison Events
        case .similarStatesCompared: "similar_states_compared"
        case .comparisonStarted: "comparison_started"
        // Content Events
        case .contentShared: "content_shared"
        case .contentBookmarked: "content_bookmarked"
        case .contentSearched: "content_searched"
        // Settings & Preferences
        case .parameterAdjusted: "parameter_adjusted"
        case .settingChanged: "setting_changed"
        case .notificationPreferenceChanged: "notification_preference_changed"
        // App Lifecycle
        case .appLaunched: "app_launched"
        case .appBackgrounded: "app_backgrounded"
        case .appForegrounded: "app_foregrounded"
        case .appUpdated: "app_updated"
        case .appTerminated: "app_terminated"
        // Navigation
        case .screenViewed: "screen_viewed"
        case .deepLinkReceived: "deep_link_received"
        case .handoffActivityRestored: "handoff_activity_restored"
        // Error & Performance
        case .errorOccurred: "error_occurred"
        case .performanceMetric: "performance_metric"
        case .crashReported: "crash_reported"
        }
    }

    var properties: [String: Any] {
        switch self {
        // Quiz Events
        case .quizStarted:
            return ["timestamp": Date().timeIntervalSince1970]

        case let .quizCompleted(profileType, score, duration):
            return [
                "profile_type": profileType.rawValue,
                "score": score,
                "duration_seconds": duration,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .quizQuestionAnswered(questionId, questionIndex, answerValue, timeSpent):
            return [
                "question_id": questionId.uuidString,
                "question_index": questionIndex,
                "answer_value": answerValue,
                "time_spent_seconds": timeSpent,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .quizExited(progress, questionsAnswered):
            return [
                "progress_percentage": progress,
                "questions_answered": questionsAnswered,
                "timestamp": Date().timeIntervalSince1970,
            ]

        // State Navigation Events
        case let .stateViewed(id, name):
            return [
                "state_id": id,
                "state_name": name,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .stateExplored(id, name, duration):
            return [
                "state_id": id,
                "state_name": name,
                "duration_seconds": duration,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .transitionExplored(from, toState):
            return [
                "from_state_id": from,
                "to_state_id": toState,
                "timestamp": Date().timeIntervalSince1970,
            ]

        // Profile Events
        case let .profileCreated(profileType):
            return [
                "profile_type": profileType.rawValue,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .profileViewed(profileType):
            return [
                "profile_type": profileType.rawValue,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .profileCompared(profileTypes):
            return [
                "profile_types": profileTypes.map(\.rawValue),
                "count": profileTypes.count,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .profileShared(profileType, method):
            return [
                "profile_type": profileType.rawValue,
                "share_method": method,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .profileExported(profileType, format):
            return [
                "profile_type": profileType.rawValue,
                "export_format": format,
                "timestamp": Date().timeIntervalSince1970,
            ]

        // Comparison Events
        case let .similarStatesCompared(count, stateIds):
            return [
                "count": count,
                "state_ids": stateIds.map(String.init).joined(separator: ","),
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .comparisonStarted(profileTypes):
            return [
                "profile_types": profileTypes.map(\.rawValue),
                "count": profileTypes.count,
                "timestamp": Date().timeIntervalSince1970,
            ]

        // Content Events
        case let .contentShared(contentType, id, method):
            return [
                "content_type": contentType,
                "content_id": id,
                "share_method": method,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .contentBookmarked(contentType, id):
            return [
                "content_type": contentType,
                "content_id": id,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .contentSearched(query, resultCount):
            return [
                "query": query,
                "result_count": resultCount,
                "timestamp": Date().timeIntervalSince1970,
            ]

        // Settings & Preferences
        case let .parameterAdjusted(parameter, oldValue, newValue):
            return [
                "parameter": parameter,
                "old_value": oldValue,
                "new_value": newValue,
                "change_amount": newValue - oldValue,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .settingChanged(setting, value):
            return [
                "setting": setting,
                "value": String(describing: value),
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .notificationPreferenceChanged(type, enabled):
            return [
                "notification_type": type,
                "enabled": enabled,
                "timestamp": Date().timeIntervalSince1970,
            ]

        // App Lifecycle
        case .appLaunched:
            return ["timestamp": Date().timeIntervalSince1970]

        case .appBackgrounded:
            return ["timestamp": Date().timeIntervalSince1970]

        case .appForegrounded:
            return ["timestamp": Date().timeIntervalSince1970]

        case let .appUpdated(previousVersion, newVersion):
            return [
                "previous_version": previousVersion,
                "new_version": newVersion,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case .appTerminated:
            return ["timestamp": Date().timeIntervalSince1970]

        // Navigation
        case let .screenViewed(screenName):
            return [
                "screen_name": screenName,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .deepLinkReceived(url):
            return [
                "url": url,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case .handoffActivityRestored:
            return ["timestamp": Date().timeIntervalSince1970]

        // Error & Performance
        case let .errorOccurred(error, context):
            return [
                "error": error,
                "context": context,
                "timestamp": Date().timeIntervalSince1970,
            ]

        case let .performanceMetric(name, duration, metadata):
            var props: [String: Any] = [
                "metric_name": name,
                "duration_seconds": duration,
                "timestamp": Date().timeIntervalSince1970,
            ]
            metadata.forEach { props["metadata_\($0.key)"] = $0.value }
            return props

        case let .crashReported(error, context):
            return [
                "error": error.localizedDescription,
                "context": context,
                "timestamp": Date().timeIntervalSince1970,
            ]
        }
    }

    var description: String {
        switch self {
        // Quiz Events
        case .quizStarted:
            return "Quiz started"

        case let .quizCompleted(_, score, duration):
            return "Quiz completed (score: \(String(format: "%.1f", score)), duration: \(String(format: "%.1f", duration))s)"

        case let .quizQuestionAnswered(_, questionIndex, _, timeSpent):
            return "Question \(questionIndex + 1) answered (\(String(format: "%.1f", timeSpent))s)"

        case let .quizExited(progress, questionsAnswered):
            return "Quiz exited (\(String(format: "%.0f", progress))% complete, \(questionsAnswered) questions answered)"

        // State Navigation Events
        case let .stateViewed(id, name):
            return "State viewed: \(name) (#\(id))"

        case let .stateExplored(id, name, duration):
            return "State explored: \(name) (#\(id)) for \(String(format: "%.1f", duration))s"

        case let .transitionExplored(from, toState):
            return "Transition explored: \(from) → \(toState)"

        // Profile Events
        case let .profileCreated(profileType):
            return "Profile created: \(profileType.rawValue)"

        case let .profileViewed(profileType):
            return "Profile viewed: \(profileType.rawValue)"

        case let .profileCompared(profileTypes):
            let names = profileTypes.map(\.rawValue).joined(separator: " vs ")
            return "Profiles compared: \(names)"

        case let .profileShared(profileType, method):
            return "Profile shared: \(profileType.rawValue) via \(method)"

        case let .profileExported(profileType, format):
            return "Profile exported: \(profileType.rawValue) as \(format)"

        // Comparison Events
        case let .similarStatesCompared(count, _):
            return "Compared \(count) similar states"

        case let .comparisonStarted(profileTypes):
            let names = profileTypes.map(\.rawValue).joined(separator: " vs ")
            return "Comparison started: \(names)"

        // Content Events
        case let .contentShared(contentType, id, method):
            return "\(contentType) shared (ID: \(id)) via \(method)"

        case let .contentBookmarked(contentType, id):
            return "\(contentType) bookmarked (ID: \(id))"

        case let .contentSearched(query, resultCount):
            return "Searched for '\(query)' - \(resultCount) results"

        // Settings & Preferences
        case let .parameterAdjusted(parameter, oldValue, newValue):
            return "Parameter adjusted: \(parameter) \(oldValue) → \(newValue)"

        case let .settingChanged(setting, value):
            return "Setting changed: \(setting) = \(value)"

        case let .notificationPreferenceChanged(type, enabled):
            return "Notification preference changed: \(type) = \(enabled ? "enabled" : "disabled")"

        // App Lifecycle
        case .appLaunched:
            return "App launched"

        case .appBackgrounded:
            return "App backgrounded"

        case .appForegrounded:
            return "App foregrounded"

        case let .appUpdated(previousVersion, newVersion):
            return "App updated: \(previousVersion) → \(newVersion)"

        case .appTerminated:
            return "App terminated"

        // Navigation
        case let .screenViewed(screenName):
            return "Screen viewed: \(screenName)"

        case let .deepLinkReceived(url):
            return "Deep link received: \(url)"

        case .handoffActivityRestored:
            return "Handoff activity restored"

        // Error & Performance
        case let .errorOccurred(error, context):
            return "Error in \(context): \(error)"

        case let .performanceMetric(name, duration, _):
            return "Performance metric: \(name) took \(String(format: "%.3f", duration))s"

        case let .crashReported(error, context):
            return "Crash reported in \(context): \(error.localizedDescription)"
        }
    }
}

final class ConsoleAnalyticsService: AnalyticsService {
    private var userProperties: [String: String] = [:]
    static let shared = ConsoleAnalyticsService()

    func track(event: AnalyticsEvent) {
        let propertiesDescription = self.userProperties
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        let payload = propertiesDescription.isEmpty ? "" : " • properties: \(propertiesDescription)"
        os_log("[Analytics] %{public}@%@", log: OSLog.default, type: .info, event.description, payload)
    }

    func setUserProperty(_ value: String, forKey key: String) {
        self.userProperties[key] = value
        os_log("[Analytics] Set user property %{public}@=%{public}@", log: OSLog.default, type: .info, key, value)
    }

    func setUserId(_ id: String?) {
        if let id {
            self.userProperties["userId"] = id
            os_log("[Analytics] Set user ID: %{public}@", log: OSLog.default, type: .info, id)
        } else {
            self.userProperties.removeValue(forKey: "userId")
            os_log("[Analytics] Cleared user ID", log: OSLog.default, type: .info)
        }
    }

    func enable(_ enabled: Bool) {
        os_log("[Analytics] Analytics enabled: %{public}@", log: OSLog.default, type: .info, String(enabled))
    }
}
