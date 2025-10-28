import SwiftUI
import SwiftData

struct ReminderDeepLinkView: View {
    private let reminderID: UUID

    @Query private var reminders: [Reminder]

    init(reminderID: UUID) {
        self.reminderID = reminderID
        _reminders = Query(
            filter: #Predicate<Reminder> { reminder in
                reminder.id == reminderID
            }
        )
    }

    var body: some View {
        Group {
            if let reminder = reminders.first {
                if let person = reminder.person {
                    PersonDetailView(person: person)
                } else {
                    ContentUnavailableView(
                        "Person Missing",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("This reminder is no longer linked to a person.")
                    )
                }
            } else {
                ContentUnavailableView(
                    "Reminder Not Found",
                    systemImage: "bell.slash",
                    description: Text("The reminder may have been completed or deleted.")
                )
            }
        }
        .navigationTitle("Reminder")
    }
}
