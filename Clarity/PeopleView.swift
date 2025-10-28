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
                        PersonMonogram(person: person)

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

private struct PersonMonogram: View {
    let person: Person

    private static let gradientPalettes: [[Color]] = [
        [.indigo, .cyan],
        [.purple, .pink],
        [.blue, .teal],
        [.orange, .yellow],
        [.mint, .green],
        [.red, .orange]
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: palette,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .blendMode(.plusLighter)
                }
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        .blendMode(.overlay)
                }

            Text(person.firstInitial)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(width: 40, height: 40)
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        .accessibilityHidden(true)
    }

    private var palette: [Color] {
        let index = abs(stableHash(for: person)) % Self.gradientPalettes.count
        return Self.gradientPalettes[index]
    }

    private func stableHash(for person: Person) -> Int {
        let key = person.firstName + person.lastName
        return key.unicodeScalars.reduce(0) { accumulator, scalar in
            let value = Int(scalar.value)
            return (accumulator &* 31 &+ value) & 0x7fffffff
        }
    }
}
