import SwiftUI
import SwiftData

struct OrganizationsView: View {
    @Query(sort: \Organization.createdAt, order: .reverse)
    private var organizations: [Organization]
    @State private var isPresentingOrganizationSheet = false
    @State private var sortOption: SortOption = .nameAscending

    private enum SortOption: CaseIterable, Identifiable {
        case nameAscending
        case nameDescending
        case peopleCount

        var id: SortOption { self }

        var title: String {
            switch self {
            case .nameAscending:
                return "Name ↑"
            case .nameDescending:
                return "Name ↓"
            case .peopleCount:
                return "People Count"
            }
        }
    }

    private var sortedOrganizations: [Organization] {
        switch sortOption {
        case .nameAscending:
            return organizations.sorted { lhs, rhs in
                let comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if comparison == .orderedSame {
                    return lhs.createdAt > rhs.createdAt
                }

                return comparison == .orderedAscending
            }
        case .nameDescending:
            return organizations.sorted { lhs, rhs in
                let comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if comparison == .orderedSame {
                    return lhs.createdAt > rhs.createdAt
                }

                return comparison == .orderedDescending
            }
        case .peopleCount:
            return organizations.sorted { lhs, rhs in
                if lhs.people.count == rhs.people.count {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }

                return lhs.people.count > rhs.people.count
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(sortedOrganizations) { organization in
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

                    Text("👥 \(organization.people.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2), in: Capsule())
                }
            }
            .navigationTitle("Organizations")
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Picker("Sort Organizations", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

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
