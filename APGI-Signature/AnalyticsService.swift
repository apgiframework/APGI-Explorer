import Foundation
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
    case transitionExplored(from: Int, to: Int)
    
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
        case .quizStarted: return "quiz_started"
        case .quizCompleted: return "quiz_completed"
        case .quizQuestionAnswered: return "quiz_question_answered"
        case .quizExited: return "quiz_exited"
            
        // State Navigation Events
        case .stateViewed: return "state_viewed"
        case .stateExplored: return "state_explored"
        case .transitionExplored: return "transition_explored"
            
        // Profile Events
        case .profileCreated: return "profile_created"
        case .profileViewed: return "profile_viewed"
        case .profileCompared: return "profile_compared"
        case .profileShared: return "profile_shared"
        case .profileExported: return "profile_exported"
            
        // Comparison Events
        case .similarStatesCompared: return "similar_states_compared"
        case .comparisonStarted: return "comparison_started"
            
        // Content Events
        case .contentShared: return "content_shared"
        case .contentBookmarked: return "content_bookmarked"
        case .contentSearched: return "content_searched"
            
        // Settings & Preferences
        case .parameterAdjusted: return "parameter_adjusted"
        case .settingChanged: return "setting_changed"
        case .notificationPreferenceChanged: return "notification_preference_changed"
            
        // App Lifecycle
        case .appLaunched: return "app_launched"
        case .appBackgrounded: return "app_backgrounded"
        case .appForegrounded: return "app_foregrounded"
        case .appUpdated: return "app_updated"
        case .appTerminated: return "app_terminated"
            
        // Navigation
        case .screenViewed: return "screen_viewed"
        case .deepLinkReceived: return "deep_link_received"
        case .handoffActivityRestored: return "handoff_activity_restored"
            
        // Error & Performance
        case .errorOccurred: return "error_occurred"
        case .performanceMetric: return "performance_metric"
        case .crashReported: return "crash_reported"
        }
    }
    
    var properties: [String: Any] {
        switch self {
        // Quiz Events
        case .quizStarted:
            return ["timestamp": Date().timeIntervalSince1970]
            
        case .quizCompleted(let profileType, let score, let duration):
            return [
                "profile_type": profileType.rawValue,
                "score": score,
                "duration_seconds": duration,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .quizQuestionAnswered(let questionId, let questionIndex, let answerValue, let timeSpent):
            return [
                "question_id": questionId.uuidString,
                "question_index": questionIndex,
                "answer_value": answerValue,
                "time_spent_seconds": timeSpent,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .quizExited(let progress, let questionsAnswered):
            return [
                "progress_percentage": progress,
                "questions_answered": questionsAnswered,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        // State Navigation Events
        case .stateViewed(let id, let name):
            return [
                "state_id": id,
                "state_name": name,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .stateExplored(let id, let name, let duration):
            return [
                "state_id": id,
                "state_name": name,
                "duration_seconds": duration,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .transitionExplored(let from, let to):
            return [
                "from_state_id": from,
                "to_state_id": to,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        // Profile Events
        case .profileCreated(let profileType):
            return [
                "profile_type": profileType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .profileViewed(let profileType):
            return [
                "profile_type": profileType.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .profileCompared(let profileTypes):
            return [
                "profile_types": profileTypes.map { $0.rawValue },
                "count": profileTypes.count,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .profileShared(let profileType, let method):
            return [
                "profile_type": profileType.rawValue,
                "share_method": method,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .profileExported(let profileType, let format):
            return [
                "profile_type": profileType.rawValue,
                "export_format": format,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        // Comparison Events
        case .similarStatesCompared(let count, let stateIds):
            return [
                "count": count,
                "state_ids": stateIds.map(String.init).joined(separator: ","),
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .comparisonStarted(let profileTypes):
            return [
                "profile_types": profileTypes.map { $0.rawValue },
                "count": profileTypes.count,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        // Content Events
        case .contentShared(let contentType, let id, let method):
            return [
                "content_type": contentType,
                "content_id": id,
                "share_method": method,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .contentBookmarked(let contentType, let id):
            return [
                "content_type": contentType,
                "content_id": id,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .contentSearched(let query, let resultCount):
            return [
                "query": query,
                "result_count": resultCount,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        // Settings & Preferences
        case .parameterAdjusted(let parameter, let oldValue, let newValue):
            return [
                "parameter": parameter,
                "old_value": oldValue,
                "new_value": newValue,
                "change_amount": newValue - oldValue,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .settingChanged(let setting, let value):
            return [
                "setting": setting,
                "value": String(describing: value),
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .notificationPreferenceChanged(let type, let enabled):
            return [
                "notification_type": type,
                "enabled": enabled,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        // App Lifecycle
        case .appLaunched:
            return ["timestamp": Date().timeIntervalSince1970]
            
        case .appBackgrounded:
            return ["timestamp": Date().timeIntervalSince1970]
            
        case .appForegrounded:
            return ["timestamp": Date().timeIntervalSince1970]
            
        case .appUpdated(let previousVersion, let newVersion):
            return [
                "previous_version": previousVersion,
                "new_version": newVersion,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .appTerminated:
            return ["timestamp": Date().timeIntervalSince1970]
            
        // Navigation
        case .screenViewed(let screenName):
            return [
                "screen_name": screenName,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .deepLinkReceived(let url):
            return [
                "url": url,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .handoffActivityRestored:
            return ["timestamp": Date().timeIntervalSince1970]
            
        // Error & Performance
        case .errorOccurred(let error, let context):
            return [
                "error": error,
                "context": context,
                "timestamp": Date().timeIntervalSince1970
            ]
            
        case .performanceMetric(let name, let duration, let metadata):
            var props: [String: Any] = [
                "metric_name": name,
                "duration_seconds": duration,
                "timestamp": Date().timeIntervalSince1970
            ]
            metadata.forEach { props["metadata_\($0.key)"] = $0.value }
            return props
            
        case .crashReported(let error, let context):
            return [
                "error": error.localizedDescription,
                "context": context,
                "timestamp": Date().timeIntervalSince1970
            ]
        }
    }
    
    var description: String {
        switch self {
        // Quiz Events
        case .quizStarted:
            return "Quiz started"
            
        case .quizCompleted(_, let score, let duration):
            return "Quiz completed (score: \(String(format: "%.1f", score)), duration: \(String(format: "%.1f", duration))s)"
            
        case .quizQuestionAnswered(_, let questionIndex, _, let timeSpent):
            return "Question \(questionIndex + 1) answered (\(String(format: "%.1f", timeSpent))s)"
            
        case .quizExited(let progress, let questionsAnswered):
            return "Quiz exited (\(String(format: "%.0f", progress))% complete, \(questionsAnswered) questions answered)"
            
        // State Navigation Events
        case .stateViewed(let id, let name):
            return "State viewed: \(name) (#\(id))"
            
        case .stateExplored(let id, let name, let duration):
            return "State explored: \(name) (#\(id)) for \(String(format: "%.1f", duration))s"
            
        case .transitionExplored(let from, let to):
            return "Transition explored: \(from) → \(to)"
            
        // Profile Events
        case .profileCreated(let profileType):
            return "Profile created: \(profileType.rawValue)"
            
        case .profileViewed(let profileType):
            return "Profile viewed: \(profileType.rawValue)"
            
        case .profileCompared(let profileTypes):
            let names = profileTypes.map { $0.rawValue }.joined(separator: " vs ")
            return "Profiles compared: \(names)"
            
        case .profileShared(let profileType, let method):
            return "Profile shared: \(profileType.rawValue) via \(method)"
            
        case .profileExported(let profileType, let format):
            return "Profile exported: \(profileType.rawValue) as \(format)"
            
        // Comparison Events
        case .similarStatesCompared(let count, _):
            return "Compared \(count) similar states"
            
        case .comparisonStarted(let profileTypes):
            let names = profileTypes.map { $0.rawValue }.joined(separator: " vs ")
            return "Comparison started: \(names)"
            
        // Content Events
        case .contentShared(let contentType, let id, let method):
            return "\(contentType) shared (ID: \(id)) via \(method)"
            
        case .contentBookmarked(let contentType, let id):
            return "\(contentType) bookmarked (ID: \(id))"
            
        case .contentSearched(let query, let resultCount):
            return "Searched for '\(query)' - \(resultCount) results"
            
        // Settings & Preferences
        case .parameterAdjusted(let parameter, let oldValue, let newValue):
            return "Parameter adjusted: \(parameter) \(oldValue) → \(newValue)"
            
        case .settingChanged(let setting, let value):
            return "Setting changed: \(setting) = \(value)"
            
        case .notificationPreferenceChanged(let type, let enabled):
            return "Notification preference changed: \(type) = \(enabled ? "enabled" : "disabled")"
            
        // App Lifecycle
        case .appLaunched:
            return "App launched"
            
        case .appBackgrounded:
            return "App backgrounded"
            
        case .appForegrounded:
            return "App foregrounded"
            
        case .appUpdated(let previousVersion, let newVersion):
            return "App updated: \(previousVersion) → \(newVersion)"
            
        case .appTerminated:
            return "App terminated"
            
        // Navigation
        case .screenViewed(let screenName):
            return "Screen viewed: \(screenName)"
            
        case .deepLinkReceived(let url):
            return "Deep link received: \(url)"
            
        case .handoffActivityRestored:
            return "Handoff activity restored"
            
        // Error & Performance
        case .errorOccurred(let error, let context):
            return "Error in \(context): \(error)"
            
        case .performanceMetric(let name, let duration, _):
            return "Performance metric: \(name) took \(String(format: "%.3f", duration))s"
            
        case .crashReported(let error, let context):
            return "Crash reported in \(context): \(error.localizedDescription)"
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
    
    func setUserId(_ id: String?) {
        if let id = id {
            userProperties["userId"] = id
            print("[Analytics] Set user ID: \(id)")
        } else {
            userProperties.removeValue(forKey: "userId")
            print("[Analytics] Cleared user ID")
        }
    }
    
    func enable(_ enabled: Bool) {
        print("[Analytics] Analytics enabled: \(enabled)")
    }
}
