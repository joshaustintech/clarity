import SwiftUI
import SwiftData

struct OrganizationsView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section("Pinned Accounts") {
                    Text("Nimbus Labs")
                    Text("Aurora Ventures")
                    Text("Harborline Partners")
                }
            }
            .navigationTitle("Organizations")
        }
        .onAppear {
            _ = modelContext
        }
    }
}
