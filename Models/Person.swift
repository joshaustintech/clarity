import Foundation
import SwiftData

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String
    var title: String?
    var profileImageData: Data?
    var archivedAt: Date?

    var organization: Organization?

    @Relationship(deleteRule: .nullify, inverse: \Tag.people)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade, inverse: \Note.person)
    var notes: [Note]

    @Relationship(deleteRule: .cascade, inverse: \Reminder.person)
    var reminders: [Reminder]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        name: String,
        title: String? = nil,
        profileImageData: Data? = nil,
        archivedAt: Date? = nil,
        organization: Organization? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.title = title
        self.profileImageData = profileImageData
        self.archivedAt = archivedAt
        self.organization = organization
        self.tags = []
        self.notes = []
        self.reminders = []
    }
}
