import SwiftUI
import SwiftData

struct PeopleView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section("Recently Viewed") {
                    Text("Alex Rivers")
                    Text("Morgan Chen")
                    Text("Sam Patel")
                }
            }
            .navigationTitle("People")
        }
        .onAppear {
            _ = modelContext
        }
    }
}
