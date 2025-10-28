import SwiftUI
import SwiftData

struct OrganizationDetailView: View {
    @Bindable var organization: Organization

    private var websiteURL: URL? {
        guard let domain = organization.domain?.trimmingCharacters(in: .whitespacesAndNewlines),
              !domain.isEmpty else {
            return nil
        }

        let prefixedDomain: String
        if domain.hasPrefix("http://") || domain.hasPrefix("https://") {
            prefixedDomain = domain
        } else {
            prefixedDomain = "https://\(domain)"
        }

        return URL(string: prefixedDomain)
    }

    private var sortedPeople: [Person] {
        organization.people.sorted { lhs, rhs in
            let lastNameComparison = lhs.lastName.localizedCaseInsensitiveCompare(rhs.lastName)
            if lastNameComparison != .orderedSame {
                return lastNameComparison == .orderedAscending
            }

            return lhs.firstName.localizedCaseInsensitiveCompare(rhs.firstName) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Section {
                header
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("People at this organization") {
                if sortedPeople.isEmpty {
                    ContentUnavailableView(
                        "No People Linked",
                        systemImage: "person.2",
                        description: Text("Add people and link them to this organization to see them here.")
                    )
                } else {
                    ForEach(sortedPeople) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            HStack(spacing: 12) {
                                PersonAvatarView(person: person, size: 44, font: .title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(person.fullName)
                                        .font(.headline)

                                    if let title = person.title, !title.isEmpty {
                                        Text(title)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(organization.name)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(organization.name)
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            if let domain = organization.domain, !domain.isEmpty {
                Text(domain)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let url = websiteURL {
                Link(destination: url) {
                    Label("Visit Website", systemImage: "globe")
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }
}

#Preview {
    OrganizationDetailPreviewHarness()
}

private struct OrganizationDetailPreviewHarness: View {
    let container: ModelContainer
    let organization: Organization

    init() {
        container = ModelContainer.previewContainer()

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Organization>(sortBy: [SortDescriptor(\.name)])
        if let fetched = try? context.fetch(descriptor), let first = fetched.first {
            organization = first
        } else {
            let sampleOrganization = Organization(name: "Sample Studio", domain: "samplestudio.design")
            let teamLead = Person(firstName: "Riley", lastName: "Nguyen", title: "Team Lead", organization: sampleOrganization)
            let designer = Person(firstName: "Avery", lastName: "Stone", title: "Product Designer", organization: sampleOrganization)

            organization = sampleOrganization

            context.insert(sampleOrganization)
            context.insert(teamLead)
            context.insert(designer)
        }
    }

    var body: some View {
        NavigationStack {
            OrganizationDetailView(organization: organization)
        }
        .modelContainer(container)
    }
}
