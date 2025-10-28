import SwiftUI
import SwiftData

struct PeopleView: View {
    @Query(sort: \Person.createdAt, order: .reverse)
    private var people: [Person]
    @State private var activeSheet: PeopleSheet?
    @State private var sortOption: SortOption = .lastName
    @State private var filter: Filter = .active

    private enum SortOption: CaseIterable, Identifiable {
        case firstName
        case lastName

        var id: SortOption { self }

        var title: String {
            switch self {
            case .firstName:
                return "First Name"
            case .lastName:
                return "Last Name"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(displayedPeople) { person in
                NavigationLink {
                    PersonDetailView(person: person)
                } label: {
                    HStack(spacing: 12) {
                        PersonAvatarView(person: person)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.fullName)
                                .font(.headline)

                            if let organizationName = person.organization?.name {
                                Text(organizationName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if !person.webLinks.isEmpty {
                            Text("🔗 \(person.webLinks.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2), in: Capsule())
                        }
                    }
                }
            }
            .navigationTitle("People")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .search
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search")

                    Button {
                        activeSheet = .newPerson
                    } label: {
                        Label("Add Person", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Filter") {
                            filterButton(for: .active, label: "Active")
                            filterButton(for: .archived, label: "Archived")
                        }

                        Section("Sort By") {
                            ForEach(SortOption.allCases) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.title)
                                        if option == sortOption {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("People options")
                }
            }
            .overlay {
                if displayedPeople.isEmpty {
                    ContentUnavailableView(
                        filter == .archived ? "No Archived People" : "No People",
                        systemImage: "person.2",
                        description: Text(filter == .archived ? "Archived people will appear here." : "Add someone to start building your workspace.")
                    )
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .newPerson:
                PersonFastAddSheet()
            case .search:
                GlobalSearchSheet()
            }
        }
    }
}

#Preview {
    PeopleView()
        .modelContainer(ModelContainer.previewContainer())
}

private extension PeopleView {
    enum PeopleSheet: Identifiable {
        case newPerson
        case search

        var id: Int {
            switch self {
            case .newPerson: 0
            case .search: 1
            }
        }
    }

    enum Filter: Equatable {
        case active
        case archived
    }

    var filteredPeople: [Person] {
        switch filter {
        case .active:
            return people.filter { !$0.isArchived }
        case .archived:
            return people.filter(\.isArchived)
        }
    }

    var displayedPeople: [Person] {
        switch sortOption {
        case .firstName:
            return filteredPeople.sorted { lhs, rhs in
                if lhs.firstName.caseInsensitiveCompare(rhs.firstName) == .orderedSame {
                    return lhs.lastName.caseInsensitiveCompare(rhs.lastName) == .orderedAscending
                }

                return lhs.firstName.caseInsensitiveCompare(rhs.firstName) == .orderedAscending
            }
        case .lastName:
            return filteredPeople.sorted { lhs, rhs in
                if lhs.lastName.caseInsensitiveCompare(rhs.lastName) == .orderedSame {
                    return lhs.firstName.caseInsensitiveCompare(rhs.firstName) == .orderedAscending
                }

                return lhs.lastName.caseInsensitiveCompare(rhs.lastName) == .orderedAscending
            }
        }
    }

    func filterButton(for option: Filter, label: String) -> some View {
        Button {
            filter = option
        } label: {
            HStack {
                Text(label)
                if filter == option {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
