import Foundation
import SwiftData

struct GlobalSearchResults: Equatable {
    let query: String
    let people: [Person]
    let organizations: [Organization]
    let notes: [Note]
    let reminders: [Reminder]

    static let empty = GlobalSearchResults(query: "", people: [], organizations: [], notes: [], reminders: [])
}

enum GlobalSearchService {
    static func search(query: String, in context: ModelContext) throws -> GlobalSearchResults {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .empty
        }

        let sanitized = trimmed.lowercased()
        let people = try context.fetch(peopleDescriptor())
            .filter { personMatches($0, term: sanitized) }
        let organizations = try context.fetch(organizationsDescriptor())
            .filter { organizationMatches($0, term: sanitized) }
        let notes = try context.fetch(notesDescriptor())
            .filter { noteMatches($0, term: sanitized) }
        let reminders = try context.fetch(remindersDescriptor())
            .filter { reminderMatches($0, term: sanitized) }

        return GlobalSearchResults(
            query: sanitized,
            people: people,
            organizations: organizations,
            notes: notes,
            reminders: reminders
        )
    }
}

private extension GlobalSearchService {
    static func peopleDescriptor() -> FetchDescriptor<Person> {
        FetchDescriptor<Person>(
            predicate: #Predicate<Person> { $0.archivedAt == nil },
            sortBy: [
                SortDescriptor(\Person.lastName, order: .forward),
                SortDescriptor(\Person.firstName, order: .forward)
            ]
        )
    }

    static func organizationsDescriptor() -> FetchDescriptor<Organization> {
        FetchDescriptor<Organization>(
            predicate: #Predicate<Organization> { $0.archivedAt == nil },
            sortBy: [
                SortDescriptor(\Organization.name, order: .forward)
            ]
        )
    }

    static func notesDescriptor() -> FetchDescriptor<Note> {
        FetchDescriptor<Note>(
            predicate: #Predicate<Note> { $0.archivedAt == nil },
            sortBy: [
                SortDescriptor(\Note.createdAt, order: .reverse)
            ]
        )
    }

    static func remindersDescriptor() -> FetchDescriptor<Reminder> {
        FetchDescriptor<Reminder>(
            sortBy: [
                SortDescriptor(\Reminder.dueDate, order: .forward)
            ]
        )
    }

    static func personMatches(_ person: Person, term: String) -> Bool {
        let firstName = person.firstName.lowercased()
        let lastName = person.lastName.lowercased()
        let title = person.title?.lowercased() ?? ""
        let organizationName = person.organization?.name.lowercased() ?? ""
        return firstName.contains(term) ||
            lastName.contains(term) ||
            title.contains(term) ||
            organizationName.contains(term)
    }

    static func organizationMatches(_ organization: Organization, term: String) -> Bool {
        let name = organization.name.lowercased()
        let domain = organization.domain?.lowercased() ?? ""
        return name.contains(term) || domain.contains(term)
    }

    static func noteMatches(_ note: Note, term: String) -> Bool {
        if note.text.lowercased().contains(term) {
            return true
        }

        if let person = note.person {
            let firstName = person.firstName.lowercased()
            let lastName = person.lastName.lowercased()
            if firstName.contains(term) || lastName.contains(term) {
                return true
            }
        }

        return note.tags.contains { $0.name.lowercased().contains(term) }
    }

    static func reminderMatches(_ reminder: Reminder, term: String) -> Bool {
        if reminder.message.lowercased().contains(term) {
            return true
        }

        if let person = reminder.person {
            let firstName = person.firstName.lowercased()
            let lastName = person.lastName.lowercased()
            if firstName.contains(term) || lastName.contains(term) {
                return true
            }
        }

        return false
    }
}
