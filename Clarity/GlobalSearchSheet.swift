import SwiftUI
import SwiftData

struct GlobalSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var query: String = ""
    @State private var results: GlobalSearchResults = .empty
    @State private var isSearching = false
    @State private var searchError: String?
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .searchable(text: $query, prompt: "Search people, notes, reminders")
                .focused($isSearchFieldFocused)
                .onChange(of: query) { _, newValue in
                    handleSearchChange(newValue)
                }
                .task {
                    await MainActor.run {
                        isSearchFieldFocused = true
                    }
                }
        }
    }
}

private extension GlobalSearchSheet {
    var content: some View {
        Group {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                instructionView
            } else if isSearching {
                ProgressView("Searching…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let searchError {
                ContentUnavailableView(
                    "Search Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(searchError)
                )
            } else if results.people.isEmpty &&
                        results.organizations.isEmpty &&
                        results.notes.isEmpty &&
                        results.reminders.isEmpty {
                ContentUnavailableView.search
            } else {
                List {
                    peopleSection
                    organizationsSection
                    notesSection
                    remindersSection
                }
                .listStyle(.insetGrouped)
                .animation(.easeInOut, value: results)
                .navigationDestination(for: SearchDestination.self) { destination in
                    destinationView(for: destination)
                }
            }
        }
    }

    var instructionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Search across people, organizations, notes, and reminders.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityAddTraits(.isStaticText)
    }

    @ViewBuilder
    var peopleSection: some View {
        if !results.people.isEmpty {
            Section("People") {
                ForEach(results.people) { person in
                    NavigationLink(value: SearchDestination.person(person)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.fullName)
                                .font(.headline)
                            if let title = person.title, !title.isEmpty {
                                Text(title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let organizationName = person.organization?.name {
                                Text(organizationName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var organizationsSection: some View {
        if !results.organizations.isEmpty {
            Section("Organizations") {
                ForEach(results.organizations) { organization in
                    NavigationLink(value: SearchDestination.organization(organization)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(organization.name)
                                .font(.headline)
                            if let domain = organization.domain, !domain.isEmpty {
                                Text(domain)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var notesSection: some View {
        if !results.notes.isEmpty {
            Section("Notes") {
                ForEach(results.notes) { note in
                    NavigationLink(value: SearchDestination.note(note)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.text)
                                .lineLimit(3)
                                .font(.body)
                            HStack(spacing: 6) {
                                Text(note.createdAt, format: .relative(presentation: .named))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let person = note.person {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(person.fullName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var remindersSection: some View {
        if !results.reminders.isEmpty {
            Section("Reminders") {
                ForEach(results.reminders) { reminder in
                    NavigationLink(value: SearchDestination.reminder(reminder)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(reminder.message)
                                .font(.headline)
                            HStack(spacing: 6) {
                                Text(reminder.dueDate, format: .relative(presentation: .named))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let person = reminder.person {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(person.fullName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    func handleSearchChange(_ newValue: String) {
        searchTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = .empty
            searchError = nil
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task { [trimmed] in
            await performSearch(for: trimmed)
        }
    }

    @MainActor
    @ViewBuilder
    func destinationView(for destination: SearchDestination) -> some View {
        switch destination {
        case .person(let person):
            PersonDetailView(person: person)
        case .organization(let organization):
            OrganizationDetailView(organization: organization)
        case .note(let note):
            NoteDetailView(note: note)
        case .reminder(let reminder):
            ReminderDetailView(reminder: reminder)
        }
    }

    func performSearch(for trimmed: String) async {
        do {
            let fetched = try await MainActor.run {
                try GlobalSearchService.search(query: trimmed, in: modelContext)
            }
            try Task.checkCancellation()
            await MainActor.run {
                results = fetched
                searchError = nil
                isSearching = false
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                results = .empty
                searchError = error.localizedDescription
                isSearching = false
            }
        }
    }
}

private enum SearchDestination: Hashable {
    case person(Person)
    case organization(Organization)
    case note(Note)
    case reminder(Reminder)
}
