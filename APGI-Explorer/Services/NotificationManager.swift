import Foundation
import UserNotifications
import os

nonisolated enum NotificationAuthorizationPolicy {
  static func canSchedule(_ status: UNAuthorizationStatus) -> Bool {
    status == .authorized || status == .provisional
  }
}

class NotificationManager {
  static let shared = NotificationManager()
  private let logger = os.Logger(subsystem: "com.apgi.explorer", category: "NotificationManager")
  private let center = UNUserNotificationCenter.current()

  private init() {
    setupNotificationCategories()
  }

  // MARK: - Notification Categories

  private func setupNotificationCategories() {
    let quizReminderAction = UNNotificationAction(
      identifier: "START_QUIZ",
      title: "Start Quiz",
      options: .foreground
    )

    let quizReminderCategory = UNNotificationCategory(
      identifier: "QUIZ_REMINDER",
      actions: [quizReminderAction],
      intentIdentifiers: [],
      options: []
    )

    center.setNotificationCategories([quizReminderCategory])
  }

  // MARK: - Quiz Reminders

  func scheduleQuizReminder(for date: Date) {
    guard UserDefaultsManager.shared.quizReminderEnabled else {
      logger.log("Quiz reminders disabled, skipping schedule")
      return
    }

    let content = UNMutableNotificationContent()
    content.title = "Quiz Reminder"
    content.body = "It's time to complete your assessment!"
    content.sound = .default
    content.categoryIdentifier = "QUIZ_REMINDER"
    content.badge = 1

    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

    let request = UNNotificationRequest(
      identifier: "quiz-reminder-\(UUID().uuidString)",
      content: content,
      trigger: trigger
    )

    Task { await addIfAuthorized(request) }
  }

  // MARK: - Profile Updates

  func sendProfileUpdateNotification(message: String) {
    guard UserDefaultsManager.shared.enableProfileUpdates else {
      logger.log("Profile update notifications disabled")
      return
    }

    let content = UNMutableNotificationContent()
    content.title = "Profile Update"
    content.body = message
    content.sound = .default
    content.badge = 1

    let request = UNNotificationRequest(
      identifier: "profile-update-\(UUID().uuidString)",
      content: content,
      trigger: nil
    )

    Task { await addIfAuthorized(request) }
  }

  // MARK: - System Alerts

  func sendSystemAlert(title: String, message: String) {
    guard UserDefaultsManager.shared.enableSystemAlerts else {
      logger.log("System alerts disabled")
      return
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default
    content.badge = 1

    let request = UNNotificationRequest(
      identifier: "system-alert-\(UUID().uuidString)",
      content: content,
      trigger: nil
    )

    Task { await addIfAuthorized(request) }
  }

  private func addIfAuthorized(_ request: UNNotificationRequest) async {
    let settings = await center.notificationSettings()
    guard NotificationAuthorizationPolicy.canSchedule(settings.authorizationStatus) else { return }
    do { try await center.add(request) } catch { logger.error("Could not schedule notification: \(error.localizedDescription)") }
  }

  func authorizationSummary() async -> String {
    let settings = await center.notificationSettings()
    if NotificationAuthorizationPolicy.canSchedule(settings.authorizationStatus) {
      return "Notifications are enabled."
    }
    if settings.authorizationStatus == .denied {
      return "Notifications are disabled. Enable APGI Explorer in System Settings → Notifications."
    }
    return "Notification permission has not been requested."
  }

  /// Called only after the user chooses Enable Notifications in Settings.
  func requestAuthorizationIfNeeded() async -> String {
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .notDetermined else {
      return await authorizationSummary()
    }
    do {
      _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
      return await authorizationSummary()
    } catch {
      return "Notifications are unavailable for this build. Use a signed app launched from Finder and check System Settings → Notifications."
    }
  }

  // MARK: - Management

  func cancelAllNotifications() {
    center.removeAllPendingNotificationRequests()
    center.removeAllDeliveredNotifications()
    logger.log("All notifications cancelled")
  }

  func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
    center.getPendingNotificationRequests { requests in
      completion(requests)
    }
  }

  func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
    center.getNotificationSettings { settings in
      completion(settings.authorizationStatus)
    }
  }
}
