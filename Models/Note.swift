import Foundation
import SwiftData

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var text: String
    var archivedAt: Date?

    var person: Person?

    @Relationship(deleteRule: .nullify, inverse: \Tag.notes)
    var tags: [Tag]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        text: String,
        person: Person? = nil,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.person = person
        self.tags = []
        self.archivedAt = archivedAt
    }
}

extension Note {
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
