import Foundation
import SwiftData

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var firstName: String
    var lastName: String
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

    @Relationship(deleteRule: .cascade, inverse: \WebLink.person)
    var webLinks: [WebLink]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        firstName: String,
        lastName: String,
        title: String? = nil,
        profileImageData: Data? = nil,
        archivedAt: Date? = nil,
        organization: Organization? = nil,
        webLinks: [WebLink] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.firstName = firstName
        self.lastName = lastName
        self.title = title
        self.profileImageData = profileImageData
        self.archivedAt = archivedAt
        self.organization = organization
        self.tags = []
        self.notes = []
        self.reminders = []
        self.webLinks = webLinks
    }
}

extension Person {
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Person {
    var firstInitial: String {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let character = trimmed.first else {
            return "#"
        }

        return String(character).uppercased()
    }

    var isArchived: Bool {
        archivedAt != nil
    }

    func archive(at date: Date = .now) {
        archivedAt = archivedAt ?? date
    }

    func unarchive() {
        archivedAt = nil
    }
}
