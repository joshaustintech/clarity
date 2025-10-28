@testable import Clarity
import SwiftData
import Foundation

#if canImport(Testing)
import Testing

@Suite("Entity Lifecycle Operations")
struct EntityLifecycleTests {
    @Test("Person archive and unarchive update archivedAt")
    func personArchiveUnarchive() {
        let person = Person(firstName: "Taylor", lastName: "Kim")

        #expect(person.archivedAt == nil)

        person.archive()
        #expect(person.archivedAt != nil)

        person.unarchive()
        #expect(person.archivedAt == nil)
    }

    @Test("Organization archive and unarchive toggle archived state")
    func organizationArchive() {
        let organization = Organization(name: "Northwind")

        #expect(!organization.isArchived)
        organization.archive()
        #expect(organization.isArchived)
        organization.unarchive()
        #expect(!organization.isArchived)
    }

    @Test("Note archive and unarchive update archivedAt")
    func noteArchive() {
        let note = Note(text: "Markdown body")

        #expect(!note.isArchived)
        note.archive()
        #expect(note.isArchived)
        note.unarchive()
        #expect(!note.isArchived)
    }

    @Test("Reminder update mutates message and due date")
    func reminderUpdate() {
        let reminder = Reminder(dueDate: .now, message: "Initial")
        let newDate = Date().addingTimeInterval(3600)

        reminder.update(dueDate: newDate, message: "Updated")

        #expect(reminder.dueDate == newDate)
        #expect(reminder.message == "Updated")
    }

    @Test("Deleting a person removes it from the model context")
    func deletePersonRemovesFromContext() throws {
        let context = try makeInMemoryContext()
        let person = Person(firstName: "Jordan", lastName: "Lee")
        context.insert(person)
        try context.save()

        context.delete(person)
        try context.save()

        let people = try context.fetch(FetchDescriptor<Person>())
        #expect(people.isEmpty)
    }

    @Test("Celebration triggers when there are no upcoming reminders")
    func celebrationWhenUpcomingIsEmpty() {
        let pastReminder = Reminder(
            dueDate: Date().addingTimeInterval(-3600),
            message: "Past"
        )
        let completedReminder = Reminder(
            dueDate: Date().addingTimeInterval(3600),
            message: "Complete",
            completed: true
        )

        let shouldCelebrate = ReminderCelebrationEvaluator.shouldCelebrate(reminders: [pastReminder, completedReminder])
        #expect(shouldCelebrate)
    }

    @Test("Celebration does not trigger when an upcoming reminder exists")
    func celebrationFalseWhenUpcomingExists() {
        let person = Person(firstName: "Jamie", lastName: "Ross")
        let upcoming = Reminder(
            dueDate: Date().addingTimeInterval(3600),
            message: "Upcoming",
            person: person
        )

        let shouldCelebrate = ReminderCelebrationEvaluator.shouldCelebrate(reminders: [upcoming])
        #expect(!shouldCelebrate)
    }
}
#else
import XCTest

final class EntityLifecycleTests: XCTestCase {
    func testPersonArchiveUnarchive() {
        let person = Person(firstName: "Taylor", lastName: "Kim")

        XCTAssertNil(person.archivedAt)

        person.archive()
        XCTAssertNotNil(person.archivedAt)

        person.unarchive()
        XCTAssertNil(person.archivedAt)
    }

    func testOrganizationArchive() {
        let organization = Organization(name: "Northwind")

        XCTAssertFalse(organization.isArchived)
        organization.archive()
        XCTAssertTrue(organization.isArchived)
        organization.unarchive()
        XCTAssertFalse(organization.isArchived)
    }

    func testNoteArchive() {
        let note = Note(text: "Markdown body")

        XCTAssertFalse(note.isArchived)
        note.archive()
        XCTAssertTrue(note.isArchived)
        note.unarchive()
        XCTAssertFalse(note.isArchived)
    }

    func testReminderUpdate() {
        let reminder = Reminder(dueDate: .now, message: "Initial")
        let newDate = Date().addingTimeInterval(3600)

        reminder.update(dueDate: newDate, message: "Updated")

        XCTAssertEqual(reminder.dueDate, newDate)
        XCTAssertEqual(reminder.message, "Updated")
    }

    func testDeletePersonRemovesFromContext() throws {
        let context = try makeInMemoryContext()
        let person = Person(firstName: "Jordan", lastName: "Lee")
        context.insert(person)
        try context.save()

        context.delete(person)
        try context.save()

        let people = try context.fetch(FetchDescriptor<Person>())
        XCTAssertTrue(people.isEmpty)
    }

    func testCelebrationTriggersWhenNoUpcomingReminders() {
        let pastReminder = Reminder(
            dueDate: Date().addingTimeInterval(-3600),
            message: "Past"
        )
        let completedReminder = Reminder(
            dueDate: Date().addingTimeInterval(3600),
            message: "Complete",
            completed: true
        )

        XCTAssertTrue(ReminderCelebrationEvaluator.shouldCelebrate(reminders: [pastReminder, completedReminder]))
    }

    func testCelebrationDoesNotTriggerWhenUpcomingExists() {
        let person = Person(firstName: "Jamie", lastName: "Ross")
        let upcoming = Reminder(
            dueDate: Date().addingTimeInterval(3600),
            message: "Upcoming",
            person: person
        )

        XCTAssertFalse(ReminderCelebrationEvaluator.shouldCelebrate(reminders: [upcoming]))
    }
}
#endif

// MARK: - Helpers

private func makeInMemoryContext() throws -> ModelContext {
    let schema = Schema([
        Person.self,
        Organization.self,
        Note.self,
        Reminder.self,
        Tag.self,
        WebLink.self
    ])

    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
}
