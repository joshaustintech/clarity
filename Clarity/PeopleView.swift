import SwiftUI
import SwiftData

struct PeopleView: View {
    @Query(sort: \Person.createdAt, order: .reverse)
    private var people: [Person]
    @State private var isPresentingPersonSheet = false
    @State private var sortOption: SortOption = .lastName

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

    private var sortedPeople: [Person] {
        switch sortOption {
        case .firstName:
            return people.sorted { lhs, rhs in
                if lhs.firstName.caseInsensitiveCompare(rhs.firstName) == .orderedSame {
                    return lhs.lastName.caseInsensitiveCompare(rhs.lastName) == .orderedAscending
                }

                return lhs.firstName.caseInsensitiveCompare(rhs.firstName) == .orderedAscending
            }
        case .lastName:
            return people.sorted { lhs, rhs in
                if lhs.lastName.caseInsensitiveCompare(rhs.lastName) == .orderedSame {
                    return lhs.firstName.caseInsensitiveCompare(rhs.firstName) == .orderedAscending
                }

                return lhs.lastName.caseInsensitiveCompare(rhs.lastName) == .orderedAscending
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(sortedPeople) { person in
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
                ToolbarItem(placement: .secondaryAction) {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingPersonSheet = true
                    } label: {
                        Label("Add Person", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if people.isEmpty {
                    ContentUnavailableView(
                        "No People",
                        systemImage: "person.2",
                        description: Text("Add someone to start building your workspace.")
                    )
                }
            }
        }
        .sheet(isPresented: $isPresentingPersonSheet) {
            PersonFastAddSheet()
        }
    }
}

#Preview {
    PeopleView()
        .modelContainer(ModelContainer.previewContainer())
}
