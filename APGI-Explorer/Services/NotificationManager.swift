import Foundation
import UserNotifications
import os

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

    center.add(request) { error in
      if let error = error {
        self.logger.error("Failed to schedule quiz reminder: \(error.localizedDescription)")
      } else {
        self.logger.log("Quiz reminder scheduled for \(date)")
      }
    }
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

    center.add(request) { error in
      if let error = error {
        self.logger.error("Failed to send profile update notification: \(error.localizedDescription)")
      } else {
        self.logger.log("Profile update notification sent")
      }
    }
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

    center.add(request) { error in
      if let error = error {
        self.logger.error("Failed to send system alert: \(error.localizedDescription)")
      } else {
        self.logger.log("System alert sent: \(title)")
      }
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
