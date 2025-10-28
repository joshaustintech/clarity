import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [SortDescriptor(\Reminder.dueDate, order: .forward)],
        animation: .default
    )
    private var reminders: [Reminder]
    @State private var hasRequestedAuthorization = false

    var body: some View {
        NavigationStack {
            List {
                if groupedUpcomingReminders.isEmpty {
                    ContentUnavailableView(
                        "No Upcoming Reminders",
                        systemImage: "bell.slash",
                        description: Text("Create reminders from a person to keep important follow-ups on track.")
                    )
                } else {
                    ForEach(groupedUpcomingReminders) { group in
                        Section(group.title) {
                            ForEach(group.reminders) { reminder in
                                ReminderRow(
                                    reminder: reminder,
                                    toggleCompletion: { toggleCompletion(for: reminder) }
                                )
                            }
                            .onDelete { offsets in
                                deleteReminders(at: offsets, in: group.reminders)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
        }
        .task {
            ReminderScheduler.configure()
            guard !hasRequestedAuthorization else { return }
            hasRequestedAuthorization = true
            await ReminderScheduler.requestAuthorization()
        }
        .task(id: remindersSignature) {
            await scheduleUpcomingReminders()
        }
    }
}

private extension RemindersView {
    var upcomingReminders: [Reminder] {
        let now = Date()
        return reminders.filter { reminder in
            !reminder.completed && reminder.dueDate >= now && reminder.person != nil
        }
    }

    var groupedUpcomingReminders: [ReminderDayGroup] {
        let grouped = Dictionary(grouping: upcomingReminders) { reminder in
            Calendar.current.startOfDay(for: reminder.dueDate)
        }

        return grouped
            .map { ReminderDayGroup(date: $0.key, reminders: $0.value.sorted(by: dueDateSort)) }
            .sorted { $0.date < $1.date }
    }

    var remindersSignature: [ReminderSignature] {
        reminders.map(ReminderSignature.init(reminder:))
    }

    func scheduleUpcomingReminders() async {
        let now = Date()
        for reminder in reminders where ReminderSchedulingPolicy.shouldCancelReminder(reminder, relativeTo: now) {
            await ReminderScheduler.cancelReminder(reminder)
        }

        for reminder in upcomingReminders {
            await ReminderScheduler.scheduleReminder(reminder)
        }
    }

    func toggleCompletion(for reminder: Reminder) {
        reminder.completed.toggle()

        Task {
            if reminder.completed {
                await ReminderScheduler.cancelReminder(reminder)
            } else {
                await ReminderScheduler.scheduleReminder(reminder)
            }
        }

        saveContext()
    }

    func deleteReminders(at offsets: IndexSet, in reminders: [Reminder]) {
        let remindersToDelete = offsets.compactMap { index in
            reminders[safe: index]
        }

        Task {
            await ReminderScheduler.cancelReminders(remindersToDelete)
        }

        remindersToDelete.forEach(modelContext.delete)
        saveContext()
    }

    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to persist reminder changes: \(error.localizedDescription)")
        }
    }

    func dueDateSort(lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.dueDate < rhs.dueDate
    }
}

// Captures scheduling-relevant fields so reminder notifications stay in sync after edits.
private struct ReminderSignature: Equatable {
    let notificationIdentifier: String
    let dueDate: Date
    let completed: Bool
    let message: String
    let personID: UUID?

    init(reminder: Reminder) {
        notificationIdentifier = reminder.notificationIdentifier
        dueDate = reminder.dueDate
        completed = reminder.completed
        message = reminder.message
        personID = reminder.person?.id
    }
}

/// Derives whether a reminder should have its notification removed.
enum ReminderSchedulingPolicy {
    static func shouldCancelReminder(_ reminder: Reminder, relativeTo referenceDate: Date = Date()) -> Bool {
        reminder.completed || reminder.dueDate < referenceDate || reminder.person == nil
    }
}

private struct ReminderDayGroup: Identifiable {
    let date: Date
    let reminders: [Reminder]

    var id: Date { date }

    var title: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct ReminderRow: View {
    @Bindable var reminder: Reminder

    let toggleCompletion: () -> Void

    private var dueTimeText: String {
        reminder.dueDate.formatted(date: .omitted, time: .shortened)
    }

    private var isDueSoon: Bool {
        reminder.isDueSoon
    }

    var body: some View {
        if let person = reminder.person {
            NavigationLink {
                PersonDetailView(person: person)
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reminder.message)
                            .font(.headline)

                        HStack(spacing: 6) {
                            Text(person.fullName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.secondary)

                            Text(dueTimeText)
                                .font(.caption)
                                .foregroundStyle(isDueSoon ? .orange : .secondary)
                        }
                    }

                    Spacer()

                    Button {
                        toggleCompletion()
                    } label: {
                        Image(systemName: reminder.completed ? "checkmark.circle.fill" : "circle")
                            .imageScale(.large)
                            .foregroundStyle(reminder.completed ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(reminder.completed ? "Mark incomplete" : "Mark complete")
                }
                .padding(.vertical, 8)
            }
        } else {
            Text(reminder.message)
                .font(.headline)
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
