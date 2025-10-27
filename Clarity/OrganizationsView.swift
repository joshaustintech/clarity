import SwiftUI
import SwiftData

struct OrganizationsView: View {
    @Query(sort: \Organization.createdAt, order: .reverse)
    private var organizations: [Organization]
    @State private var isPresentingOrganizationSheet = false

    var body: some View {
        NavigationStack {
            List(organizations) { organization in
                VStack(alignment: .leading, spacing: 4) {
                    Text(organization.name)
                        .font(.headline)

                    if let domain = organization.domain, !domain.isEmpty {
                        Text(domain)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Organizations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingOrganizationSheet = true
                    } label: {
                        Label("Add Organization", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if organizations.isEmpty {
                    ContentUnavailableView(
                        "No Organizations",
                        systemImage: "building.2",
                        description: Text("Add an organization to keep your workspace organized.")
                    )
                }
            }
        }
        .sheet(isPresented: $isPresentingOrganizationSheet) {
            OrganizationFastAddSheet()
        }
    }
}
