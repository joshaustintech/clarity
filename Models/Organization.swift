import Foundation
import SwiftData

@Model
final class Organization {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String
    var domain: String?
    var archivedAt: Date?

    @Relationship(deleteRule: .nullify, inverse: \Person.organization)
    var people: [Person]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        name: String,
        domain: String? = nil,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.domain = domain
        self.archivedAt = archivedAt
        self.people = []
    }
}

extension Organization {
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
