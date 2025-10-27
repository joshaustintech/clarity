import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section("Upcoming") {
                    Text("Follow up with Alex")
                    Text("Prepare Aurora proposal")
                    Text("Schedule quarterly review")
                }
            }
            .navigationTitle("Reminders")
        }
        .onAppear {
            _ = modelContext
        }
    }
}
