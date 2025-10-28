import SwiftUI
import SwiftData

struct OrganizationsView: View {
    @Query(sort: \Organization.name, order: .forward)
    private var organizations: [Organization]
    @State private var isPresentingOrganizationSheet = false
    @State private var searchText = ""

    private var filteredOrganizations: [Organization] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return organizations
        }

        let lowercasedQuery = trimmedQuery.lowercased()

        return organizations.filter { organization in
            let nameMatches = organization.name.lowercased().contains(lowercasedQuery)
            let domainMatches = organization.domain?.lowercased().contains(lowercasedQuery) ?? false
            return nameMatches || domainMatches
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredOrganizations.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ForEach(filteredOrganizations) { organization in
                        NavigationLink {
                            OrganizationDetailView(organization: organization)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(organization.name)
                                        .font(.headline)

                                    if let domain = organization.domain, !domain.isEmpty {
                                        Text(domain)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "person.2")
                                    Text(personCountLabel(for: organization.people.count))
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.18), in: Capsule())
                            }
                        }
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
        .searchable(text: $searchText, prompt: "Search organizations")
        .sheet(isPresented: $isPresentingOrganizationSheet) {
            OrganizationFastAddSheet()
        }
    }

    private func personCountLabel(for count: Int) -> String {
        if count == 1 {
            return "1 person"
        }

        return "\(count) people"
    }
}

#Preview {
    NavigationStack {
        OrganizationsView()
    }
    .modelContainer(ModelContainer.previewContainer())
}
