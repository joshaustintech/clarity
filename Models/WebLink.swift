import Foundation
import SwiftData

@Model
final class WebLink {
    @Attribute(.unique) var id: UUID
    var url: String
    var createdAt: Date

    var person: Person?

    init(
        id: UUID = UUID(),
        url: String,
        createdAt: Date = .now,
        person: Person? = nil
    ) {
        self.id = id
        self.url = url
        self.createdAt = createdAt
        self.person = person
    }
}
