import Foundation
import UserNotifications

enum ReminderScheduler {
    private static let notificationCenter = UNUserNotificationCenter.current()
    private static let notificationDelegate = NotificationDelegate()

    @MainActor
    private static var deepLinkHandler: ((URL) -> Void)?

    static func configure() {
        notificationCenter.delegate = notificationDelegate
    }

    @MainActor
    static func registerDeepLinkHandler(_ handler: @escaping (URL) -> Void) {
        deepLinkHandler = handler
    }

    static func deliverDeepLink(_ url: URL) {
        Task { @MainActor in
            deepLinkHandler?(url)
        }
    }

    static func requestAuthorization() async {
        do {
            _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            assertionFailure("Failed to request notification authorization: \(error.localizedDescription)")
        }
    }

    static func scheduleReminder(_ reminder: Reminder) async {
        await cancelReminder(reminder)

        guard reminder.dueDate > Date(), !reminder.completed else {
            return
        }

        let content = UNMutableNotificationContent()
        let personName = reminder.person?.fullName

        content.title = personName ?? "Reminder"
        content.body = reminder.message
        content.sound = .default
        content.userInfo = [
            ReminderUserInfoKey.reminderID: reminder.id.uuidString,
            ReminderUserInfoKey.deepLink: AppDeepLink.reminder(reminder.id).absoluteString
        ]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.dueDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminder.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await add(request)
        } catch {
            assertionFailure("Failed to schedule reminder notification: \(error.localizedDescription)")
        }
    }

    static func cancelReminder(_ reminder: Reminder) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.notificationIdentifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [reminder.notificationIdentifier])
    }

    static func rescheduleReminder(_ reminder: Reminder) async {
        await scheduleReminder(reminder)
    }

    static func cancelReminders(_ reminders: [Reminder]) async {
        let identifiers = reminders.map(\.notificationIdentifier)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

private extension ReminderScheduler {
    static func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notificationCenter.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    enum ReminderUserInfoKey {
        static let reminderID = "reminderID"
        static let deepLink = "deepLink"
    }

    final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            [.banner, .list, .sound]
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse
        ) async {
            guard
                let deepLink = response.notification.request.content.userInfo[ReminderUserInfoKey.deepLink] as? String,
                let url = URL(string: deepLink)
            else {
                return
            }

            ReminderScheduler.deliverDeepLink(url)
        }
    }
}

enum AppDeepLink {
    case reminder(UUID)

    var url: URL {
        switch self {
        case .reminder(let id):
            return URL(string: "clarity://reminder/\(id.uuidString)")!
        }
    }

    static func reminder(_ id: UUID) -> URL {
        AppDeepLink.reminder(id).url
    }

    static func parse(_ url: URL) -> AppDeepLink? {
        guard url.scheme == "clarity" else {
            return nil
        }

        switch url.host {
        case "reminder":
            guard
                let identifier = url.pathComponents.dropFirst().first,
                let uuid = UUID(uuidString: identifier)
            else {
                return nil
            }
            return .reminder(uuid)
        default:
            return nil
        }
    }
}
