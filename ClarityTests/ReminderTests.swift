@testable import Clarity
import Foundation

#if canImport(Testing)
import Testing

@Suite("Reminder Due Soon Evaluations")
struct ReminderDueSoonTests {
    @Test("Due date within 24 hours should be due soon")
    func dueSoonWithinTwentyFourHours() {
        let dueDate = Date().addingTimeInterval(23 * 60 * 60)
        let reminder = Reminder(dueDate: dueDate, message: "Follow up")

        #expect(reminder.isDueSoon)
    }

    @Test("Past due reminders are not considered due soon")
    func pastDueIsNotDueSoon() {
        let dueDate = Date().addingTimeInterval(-3 * 60 * 60)
        let reminder = Reminder(dueDate: dueDate, message: "Too late")

        #expect(!reminder.isDueSoon)
    }

    @Test("Reminders more than 24 hours out are not due soon")
    func farFutureIsNotDueSoon() {
        let dueDate = Date().addingTimeInterval(25 * 60 * 60)
        let reminder = Reminder(dueDate: dueDate, message: "Future follow up")

        #expect(!reminder.isDueSoon)
    }
}

@Suite("Reminder Scheduling Policy")
struct ReminderSchedulingPolicyTests {
    @Test("Cancels reminders without an associated person")
    func cancelsReminderMissingPerson() {
        let now = Date()
        let futureDate = now.addingTimeInterval(45 * 60)
        let person = Person(firstName: "Morgan", lastName: "Lee")
        let reminder = Reminder(dueDate: futureDate, message: "Check in", person: person)

        #expect(!ReminderSchedulingPolicy.shouldCancelReminder(reminder, relativeTo: now))

        reminder.person = nil

        #expect(ReminderSchedulingPolicy.shouldCancelReminder(reminder, relativeTo: now))
    }
}
#else
import XCTest

final class ReminderDueSoonTests: XCTestCase {
    func testDueSoonWithinTwentyFourHours() {
        let dueDate = Date().addingTimeInterval(23 * 60 * 60)
        let reminder = Reminder(dueDate: dueDate, message: "Follow up")

        XCTAssertTrue(reminder.isDueSoon)
    }

    func testPastDueIsNotDueSoon() {
        let dueDate = Date().addingTimeInterval(-3 * 60 * 60)
        let reminder = Reminder(dueDate: dueDate, message: "Too late")

        XCTAssertFalse(reminder.isDueSoon)
    }

    func testFarFutureIsNotDueSoon() {
        let dueDate = Date().addingTimeInterval(25 * 60 * 60)
        let reminder = Reminder(dueDate: dueDate, message: "Future follow up")

        XCTAssertFalse(reminder.isDueSoon)
    }
}

final class ReminderSchedulingPolicyTests: XCTestCase {
    func testCancelsReminderMissingPerson() {
        let now = Date()
        let futureDate = now.addingTimeInterval(45 * 60)
        let person = Person(firstName: "Morgan", lastName: "Lee")
        let reminder = Reminder(dueDate: futureDate, message: "Check in", person: person)

        XCTAssertFalse(ReminderSchedulingPolicy.shouldCancelReminder(reminder, relativeTo: now))

        reminder.person = nil

        XCTAssertTrue(ReminderSchedulingPolicy.shouldCancelReminder(reminder, relativeTo: now))
    }
}
#endif
