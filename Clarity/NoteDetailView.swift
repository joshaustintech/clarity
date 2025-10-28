import SwiftUI

struct NoteDetailView: View {
    @Bindable var note: Note

    private var sortedTags: [Tag] {
        note.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section("Details") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(note.createdAt, format: .dateTime.month().day().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(note.text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 4)
            }

            if !sortedTags.isEmpty {
                Section("Tags") {
                    ForEach(sortedTags, id: \.id) { tag in
                        Text(tag.name)
                            .font(.body)
                    }
                }
            }

            if let person = note.person {
                Section("Linked Person") {
                    NavigationLink {
                        PersonDetailView(person: person)
                    } label: {
                        Text(person.fullName)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Note")
    }
}
