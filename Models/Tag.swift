import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    @Attribute(.unique) var name: String

    var people: [Person]

    var notes: [Note]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        name: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.people = []
        self.notes = []
    }
}
