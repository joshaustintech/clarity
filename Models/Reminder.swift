import Foundation
import SwiftData

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var dueDate: Date
    var message: String
    var completed: Bool

    var person: Person?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        dueDate: Date,
        message: String,
        completed: Bool = false,
        person: Person? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.message = message
        self.completed = completed
        self.person = person
    }
}
