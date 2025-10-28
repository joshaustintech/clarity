import Foundation
import SwiftData

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var notificationID: UUID
    var createdAt: Date
    var dueDate: Date
    var message: String
    var completed: Bool

    var person: Person?

    init(
        id: UUID = UUID(),
        notificationID: UUID = UUID(),
        createdAt: Date = .now,
        dueDate: Date,
        message: String,
        completed: Bool = false,
        person: Person? = nil
    ) {
        self.id = id
        self.notificationID = notificationID
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.message = message
        self.completed = completed
        self.person = person
    }
}

extension Reminder {
    var notificationIdentifier: String {
        notificationID.uuidString
    }

    var isDueSoon: Bool {
        let now = Date()
        guard dueDate >= now else {
            return false
        }

        let timeInterval = dueDate.timeIntervalSince(now)
        let oneDay: TimeInterval = 24 * 60 * 60
        return timeInterval <= oneDay
    }
}
