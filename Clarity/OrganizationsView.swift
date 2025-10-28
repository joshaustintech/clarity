import SwiftUI
import SwiftData

struct OrganizationsView: View {
    @Query(sort: \Organization.name, order: .forward)
    private var organizations: [Organization]
    @State private var activeSheet: ActiveSheet?
    @State private var searchText = ""
    @State private var filter: Filter = .active

    private enum ActiveSheet: Identifiable {
        case newOrganization
        case search

        var id: Int {
            switch self {
            case .newOrganization: 0
            case .search: 1
            }
        }
    }

    private enum Filter: Equatable {
        case active
        case archived

        var label: String {
            switch self {
            case .active:
                return "Active"
            case .archived:
                return "Archived"
            }
        }
    }

    private var filteredOrganizations: [Organization] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let base: [Organization]
        switch filter {
        case .active:
            base = organizations.filter { !$0.isArchived }
        case .archived:
            base = organizations.filter(\.isArchived)
        }

        guard !trimmedQuery.isEmpty else {
            return base
        }

        let lowercasedQuery = trimmedQuery.lowercased()

        return base.filter { organization in
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .search
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search")

                    Button {
                        activeSheet = .newOrganization
                    } label: {
                        Label("Add Organization", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        filterButton(for: .active)
                        filterButton(for: .archived)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Organization filters")
                }
            }
            .overlay {
                if filteredOrganizations.isEmpty {
                    ContentUnavailableView(
                        filter == .archived ? "No Archived Organizations" : "No Organizations",
                        systemImage: "building.2",
                        description: Text(filter == .archived ? "Archived organizations will appear here." : "Add an organization to keep your workspace organized.")
                    )
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search organizations")
        .sheet(item: $activeSheet) { item in
            switch item {
            case .newOrganization:
                OrganizationFastAddSheet()
            case .search:
                GlobalSearchSheet()
            }
        }
    }

    private func personCountLabel(for count: Int) -> String {
        if count == 1 {
            return "1 person"
        }

        return "\(count) people"
    }

    private func filterButton(for option: Filter) -> some View {
        Button {
            filter = option
        } label: {
            HStack {
                Text(option.label)
                if filter == option {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OrganizationsView()
    }
    .modelContainer(ModelContainer.previewContainer())
}
