import Foundation
import SwiftData

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var text: String

    var person: Person?

    @Relationship(deleteRule: .nullify, inverse: \Tag.notes)
    var tags: [Tag]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        text: String,
        person: Person? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.person = person
        self.tags = []
    }
}
