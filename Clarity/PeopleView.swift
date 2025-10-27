import SwiftUI
import SwiftData

struct PeopleView: View {
    @Query(sort: \Person.createdAt, order: .reverse)
    private var people: [Person]

    var body: some View {
        NavigationStack {
            List(people) { person in
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.headline)

                    if let organizationName = person.organization?.name {
                        Text(organizationName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("People")
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
    }
}

#Preview {
    PeopleView()
        .modelContainer(ModelContainer.previewContainer())
}
