import SwiftUI
import SwiftData

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var reminder: Reminder
    @State private var isCompleted: Bool = false

    var body: some View {
        Form {
            Section("Reminder") {
                Text(reminder.message)
                    .font(.body)
                    .padding(.vertical, 4)
            }

            Section("Due Date") {
                Text(reminder.dueDate, style: .date)
                Text(reminder.dueDate, style: .time)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Mark Complete", isOn: $isCompleted)
                    .onChange(of: isCompleted) {
                        handleCompletionChange(isCompleted)
                    }
            }

            if let person = reminder.person {
                Section("Linked Person") {
                    NavigationLink {
                        PersonDetailView(person: person)
                    } label: {
                        Text(person.fullName)
                    }
                }
            }
        }
        .navigationTitle("Reminder")
        .onAppear {
            isCompleted = reminder.completed
        }
    }
}

private extension ReminderDetailView {
    func handleCompletionChange(_ isComplete: Bool) {
        reminder.completed = isComplete

        Task {
            if isComplete {
                await ReminderScheduler.cancelReminder(reminder)
            } else {
                await ReminderScheduler.scheduleReminder(reminder)
            }
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save reminder completion change: \(error.localizedDescription)")
        }
    }
}
