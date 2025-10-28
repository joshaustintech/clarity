import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Bindable var person: Person

    @State private var isPresentingNoteSheet = false
    @State private var timelineSortOrder: TimelineSortOrder = .reverseChronological

    private enum TimelineSortOrder: String, CaseIterable, Identifiable {
        case chronological
        case reverseChronological

        var id: TimelineSortOrder { self }

        var label: String {
            switch self {
            case .chronological:
                return "Oldest First"
            case .reverseChronological:
                return "Newest First"
            }
        }

        var iconName: String {
            switch self {
            case .chronological:
                return "arrow.down"
            case .reverseChronological:
                return "arrow.up"
            }
        }

        mutating func toggle() {
            self = self == .chronological ? .reverseChronological : .chronological
        }
    }

    private var sortedNotes: [Note] {
        switch timelineSortOrder {
        case .chronological:
            return person.notes.sorted { $0.createdAt < $1.createdAt }
        case .reverseChronological:
            return person.notes.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private var nextReminder: Reminder? {
        person.reminders
            .filter { !$0.completed }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    var body: some View {
        List {
            Section {
                header
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("AI Summary") {
                summaryPlaceholder
            }

            if let reminder = nextReminder {
                Section("Next Reminder") {
                    reminderChip(for: reminder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Section("Timeline") {
                if sortedNotes.isEmpty {
                    ContentUnavailableView(
                        "No Notes Yet",
                        systemImage: "note.text",
                        description: Text("Add the first note to start building a timeline.")
                    )
                } else {
                    ForEach(sortedNotes) { note in
                        TimelineNoteRow(note: note)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(person.fullName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("+ Note") {
                    isPresentingNoteSheet = true
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button {
                    timelineSortOrder.toggle()
                } label: {
                    Label(timelineSortOrder.label, systemImage: timelineSortOrder.iconName)
                }
                .accessibilityLabel("Toggle timeline order")
            }
        }
        .sheet(isPresented: $isPresentingNoteSheet) {
            NoteEditorSheet(person: person)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                PersonAvatarView(initials: person.firstInitial)

                VStack(alignment: .leading, spacing: 6) {
                    Text(person.fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)

                    if let title = person.title, !title.isEmpty {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    if let organization = person.organization {
                        organizationLink(organization)
                    }
                }

                Spacer()
            }
        }
        .padding(.vertical, 12)
    }

    private var summaryPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Summary")
                .font(.headline)

            Text("Insights for this person will appear here once AI summaries are available.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray.opacity(0.08))
        )
    }

    private func reminderChip(for reminder: Reminder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .imageScale(.medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.message)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(reminder.dueDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1), in: Capsule())
    }

    private func organizationLink(_ organization: Organization) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(organization.name)
                .font(.subheadline)

            if let domain = organization.domain, let url = URL(string: "https://\(domain)") {
                Link(destination: url) {
                    Label(domain, systemImage: "link")
                        .font(.caption)
                }
            }
        }
    }
}

private struct PersonAvatarView: View {
    let initials: String

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

            Text(initials)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(width: 72, height: 72)
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        .accessibilityHidden(true)
    }

    private var palette: [Color] {
        let index = abs(stableHash(for: initials)) % Self.gradientPalettes.count
        return Self.gradientPalettes[index]
    }

    private func stableHash(for value: String) -> Int {
        value.unicodeScalars.reduce(0) { accumulator, scalar in
            let scalarValue = Int(scalar.value)
            return (accumulator &* 31 &+ scalarValue) & 0x7fffffff
        }
    }
}

private struct TimelineNoteRow: View {
    let note: Note

    private var sortedTags: [Tag] {
        note.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.createdAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !sortedTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(sortedTags, id: \.id) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }

            Text(note.text)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let person: Person

    @State private var text: String = ""
    @State private var noteDate: Date = .now
    @State private var isShowingDateSheet = false
    @State private var pendingDate: Date = .now
    @FocusState private var isEditorFocused: Bool

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    Button {
                        pendingDate = noteDate
                        isShowingDateSheet = true
                    } label: {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(noteDate, format: .dateTime.month().day().year())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Note") {
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                        .focused($isEditorFocused)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    isEditorFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $isShowingDateSheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker(
                        "Date",
                        selection: $pendingDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .accessibilityLabel("Select note date")

                    Spacer()
                }
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            isShowingDateSheet = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            noteDate = pendingDate
                            isShowingDateSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func saveNote() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = Note(createdAt: noteDate, text: trimmed, person: person)
        modelContext.insert(note)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save note: \(error.localizedDescription)")
        }

        dismiss()
    }
}

#Preview {
    PersonDetailPreviewHarness()
}

private struct PersonDetailPreviewHarness: View {
    let container: ModelContainer
    let person: Person

    init() {
        container = ModelContainer.previewContainer()
        let context = ModelContext(container)

        let organization = Organization(name: "Northstar Studio", domain: "northstar.design")
        let person = Person(
            firstName: "Jordan",
            lastName: "Lee",
            title: "Lead Researcher",
            organization: organization
        )

        let discovery = Tag(name: "Discovery")
        let strategy = Tag(name: "Strategy")
        let followUp = Tag(name: "Follow Up")

        let now = Date()
        let noteOneDate = Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now
        let noteTwoDate = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
        let noteThreeDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now

        let noteOne = Note(createdAt: noteOneDate, text: """
        Kicked off the discovery sprint. Captured stakeholder goals and success metrics.
        """, person: person)

        let noteTwo = Note(createdAt: noteTwoDate, text: """
        **Interview Highlights**
        - Participants resonated with the new onboarding copy.
        - Need to refine the dashboard empty state.
        """, person: person)

        let noteThree = Note(createdAt: noteThreeDate, text: """
        Wrapped synthesis session. Next step: compile insights for leadership review.
        """, person: person)

        noteOne.tags.append(discovery)
        noteTwo.tags.append(contentsOf: [strategy, followUp])
        noteThree.tags.append(followUp)

        let reminder = Reminder(
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
            message: "Prepare executive readout."
        )

        person.reminders.append(reminder)

        context.insert(organization)
        context.insert(person)
        context.insert(discovery)
        context.insert(strategy)
        context.insert(followUp)
        context.insert(noteOne)
        context.insert(noteTwo)
        context.insert(noteThree)
        context.insert(reminder)

        try? context.save()

        self.person = person
    }

    var body: some View {
        NavigationStack {
            PersonDetailView(person: person)
        }
        .modelContainer(container)
    }
}
