import Foundation

enum ReminderCelebrationEvaluator {
    static func shouldCelebrate(reminders: [Reminder], referenceDate: Date = .now) -> Bool {
        remindersUpcoming(reminders, referenceDate: referenceDate).isEmpty
    }

    static func remindersUpcoming(_ reminders: [Reminder], referenceDate: Date = .now) -> [Reminder] {
        reminders.filter { reminder in
            !reminder.completed &&
            reminder.dueDate >= referenceDate &&
            reminder.person != nil
        }
    }
}
