import Foundation
import UserNotifications

final class ReminderScheduler {
    static let shared = ReminderScheduler()

    private let center = UNUserNotificationCenter.current()

    private enum ReminderID {
        static let dailyReview = "capy.reminder.daily.review"
        static let weeklyReview = "capy.reminder.weekly.review"
    }

    private init() {}

    func requestPermissionIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func syncReminders(
        isEnabled: Bool,
        dailyReminderMinutes: Int,
        weeklyReminderMinutes: Int,
        weeklyWeekday: Int
    ) async {
        center.removePendingNotificationRequests(withIdentifiers: [
            ReminderID.dailyReview,
            ReminderID.weeklyReview
        ])

        guard isEnabled else { return }
        guard await requestPermissionIfNeeded() else { return }

        await scheduleDailyReminder(minutes: dailyReminderMinutes)
        await scheduleWeeklyReminder(minutes: weeklyReminderMinutes, weekday: weeklyWeekday)
    }

    private func scheduleDailyReminder(minutes: Int) async {
        let (hour, minute) = splitMinutes(minutes)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "capy daily check-in"
        content.body = "open capy, finish your goals, and log your day."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: ReminderID.dailyReview,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule daily reminder: \(error.localizedDescription)")
        }
    }

    private func scheduleWeeklyReminder(minutes: Int, weekday: Int) async {
        let (hour, minute) = splitMinutes(minutes)
        var dateComponents = DateComponents()
        dateComponents.weekday = max(1, min(weekday, 7))
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "capy weekly review"
        content.body = "review your week with capy and set your next steps."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: ReminderID.weeklyReview,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule weekly reminder: \(error.localizedDescription)")
        }
    }

    private func splitMinutes(_ totalMinutes: Int) -> (Int, Int) {
        let clamped = max(0, min(totalMinutes, 23 * 60 + 59))
        return (clamped / 60, clamped % 60)
    }
}
