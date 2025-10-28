import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var person: Person

    @State private var activeSheet: PersonDetailSheet?
    @State private var timelineSortOrder: TimelineSortOrder = .reverseChronological
    @State private var noteFilter: NoteFilter = .active

    private var filteredNotes: [Note] {
        switch noteFilter {
        case .active:
            return person.notes.filter { !$0.isArchived }
        case .archived:
            return person.notes.filter(\.isArchived)
        }
    }

    private var sortedNotes: [Note] {
        switch timelineSortOrder {
        case .chronological:
            return filteredNotes.sorted { $0.createdAt < $1.createdAt }
        case .reverseChronological:
            return filteredNotes.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private var sortedReminders: [Reminder] {
        person.reminders.sorted { $0.dueDate < $1.dueDate }
    }

    private var upcomingReminders: [Reminder] {
        ReminderCelebrationEvaluator.remindersUpcoming(sortedReminders)
    }

    private var nextReminder: Reminder? {
        upcomingReminders.first
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

            Section("Reminders") {
                if let upcoming = nextReminder {
                    reminderChip(for: upcoming)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }

                Button {
                    activeSheet = .reminder(ReminderEditorConfig(mode: .create(person: person)))
                } label: {
                    Label("+ Reminder", systemImage: "plus.circle.fill")
                }

                if sortedReminders.isEmpty {
                    ContentUnavailableView(
                        "No Reminders",
                        systemImage: "bell",
                        description: Text("Add reminders to keep follow-ups on track.")
                    )
                } else {
                    ForEach(sortedReminders) { reminder in
                        PersonReminderRow(
                            reminder: reminder,
                            toggleCompletion: { toggleReminderCompletion(reminder) }
                        )
                        .swipeActions {
                            Button {
                                activeSheet = .reminder(ReminderEditorConfig(mode: .edit(reminder: reminder)))
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                deleteReminder(reminder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("Timeline") {
                if sortedNotes.isEmpty {
                    ContentUnavailableView(
                        noteFilter == .archived ? "No Archived Notes" : "No Notes Yet",
                        systemImage: "note.text",
                        description: Text(noteFilter == .archived ? "Archived notes will appear here." : "Add the first note to start building a timeline.")
                    )
                } else {
                    ForEach(sortedNotes) { note in
                        TimelineNoteRow(note: note)
                            .padding(.vertical, 8)
                            .swipeActions {
                                Button {
                                    activeSheet = .note(NoteEditorConfig(mode: .edit(note: note)))
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                if note.isArchived {
                                    Button {
                                        unarchiveNote(note)
                                    } label: {
                                        Label("Unarchive", systemImage: "arrow.uturn.backward.circle")
                                    }
                                    .tint(.blue)
                                } else {
                                    Button {
                                        archiveNote(note)
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.indigo)
                                }

                                Button(role: .destructive) {
                                    deleteNote(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(person.fullName)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Section("Notes Filter") {
                        noteFilterButton(for: .active, label: "Active")
                        noteFilterButton(for: .archived, label: "Archived")
                    }

                    Section("Timeline Order") {
                        ForEach(TimelineSortOrder.allCases) { option in
                            Button {
                                timelineSortOrder = option
                            } label: {
                                HStack {
                                    Text(option.label)
                                    if option == timelineSortOrder {
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
                .accessibilityLabel("Timeline options")

                Button("+ Note") {
                    activeSheet = .note(NoteEditorConfig(mode: .create(person: person)))
                }

                Button("Edit") {
                    activeSheet = .personEditor
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .note(let config):
                NoteEditorSheet(config: config)
            case .reminder(let config):
                ReminderEditorSheet(config: config)
            case .personEditor:
                PersonEditorSheet(person: person) {
                    dismiss()
                }
            }
        }
    }
}

private extension PersonDetailView {
    enum TimelineSortOrder: String, CaseIterable, Identifiable {
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
    }

    enum NoteFilter {
        case active
        case archived
    }

    enum PersonDetailSheet: Identifiable {
        case note(NoteEditorConfig)
        case reminder(ReminderEditorConfig)
        case personEditor

        var id: String {
            switch self {
            case .note(let config):
                return "note-\(config.id.uuidString)"
            case .reminder(let config):
                return "reminder-\(config.id.uuidString)"
            case .personEditor:
                return "person-editor"
            }
        }
    }

    static func defaultReminderDate() -> Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? Date().addingTimeInterval(60 * 60)
    }

    func toggleReminderCompletion(_ reminder: Reminder) {
        reminder.completed.toggle()

        Task {
            if reminder.completed {
                await ReminderScheduler.cancelReminder(reminder)
            } else if ReminderSchedulingPolicy.shouldCancelReminder(reminder) {
                await ReminderScheduler.cancelReminder(reminder)
            } else {
                await ReminderScheduler.scheduleReminder(reminder)
            }
        }

        saveContext()
    }

    func deleteReminder(_ reminder: Reminder) {
        Task {
            await ReminderScheduler.cancelReminder(reminder)
        }

        modelContext.delete(reminder)
        saveContext()
    }

    func archiveNote(_ note: Note) {
        note.archive()
        saveContext()
    }

    func unarchiveNote(_ note: Note) {
        note.unarchive()
        saveContext()
    }

    func deleteNote(_ note: Note) {
        modelContext.delete(note)
        saveContext()
    }

    func noteFilterButton(for option: NoteFilter, label: String) -> some View {
        Button {
            noteFilter = option
        } label: {
            HStack {
                Text(label)
                if noteFilter == option {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                PersonAvatarView(
                    person: person,
                    size: 72,
                    font: .title
                )

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

    var summaryPlaceholder: some View {
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

    func reminderChip(for reminder: Reminder) -> some View {
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

    func organizationLink(_ organization: Organization) -> some View {
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

    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to persist changes: \(error.localizedDescription)")
        }
    }
}

private struct PersonReminderRow: View {
    @Bindable var reminder: Reminder
    let toggleCompletion: () -> Void

    private var dueDateText: String {
        reminder.dueDate.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.message)
                    .font(.headline)
                    .foregroundStyle(reminder.completed ? Color.secondary : Color.primary)

                Text(dueDateText)
                    .font(.caption)
                    .foregroundStyle(
                        reminder.completed
                            ? Color.secondary
                            : (reminder.isDueSoon ? Color.orange : Color.secondary)
                    )
            }

            Spacer()

            Button {
                toggleCompletion()
            } label: {
                Image(systemName: reminder.completed ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(reminder.completed ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(reminder.completed ? "Mark incomplete" : "Mark complete")
        }
        .padding(.vertical, 6)
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

private struct NoteEditorConfig: Identifiable {
    enum Mode {
        case create(person: Person)
        case edit(note: Note)
    }

    let id = UUID()
    let mode: Mode
}

private struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let config: NoteEditorConfig

    @State private var text: String
    @State private var noteDate: Date
    @FocusState private var isEditorFocused: Bool

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(config: NoteEditorConfig) {
        self.config = config

        switch config.mode {
        case .create:
            _text = State(initialValue: "")
            let now = Date()
            _noteDate = State(initialValue: now)
        case .edit(let note):
            _text = State(initialValue: note.text)
            _noteDate = State(initialValue: note.createdAt)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker(
                        "Date",
                        selection: $noteDate,
                        displayedComponents: [.date]
                    )
                }

                Section("Note") {
                    TextEditor(text: $text)
                        .frame(minHeight: 200)
                        .focused($isEditorFocused)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                }
            }
            .navigationTitle(config.mode.title)
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
            .task {
                await MainActor.run {
                    isEditorFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveNote() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch config.mode {
        case .create(let person):
            let note = Note(createdAt: noteDate, text: trimmed, person: person)
            modelContext.insert(note)
        case .edit(let note):
            note.text = trimmed
            note.createdAt = noteDate
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save note: \(error.localizedDescription)")
        }

        dismiss()
    }
}

private extension NoteEditorConfig.Mode {
    var title: String {
        switch self {
        case .create:
            return "New Note"
        case .edit:
            return "Edit Note"
        }
    }
}

private struct ReminderEditorConfig: Identifiable {
    enum Mode {
        case create(person: Person)
        case edit(reminder: Reminder)
    }

    let id = UUID()
    let mode: Mode
}

private struct ReminderEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let config: ReminderEditorConfig

    @State private var message: String
    @State private var dueDate: Date
    @State private var markComplete: Bool
    @FocusState private var isFocused: Bool

    private var canSave: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(config: ReminderEditorConfig) {
        self.config = config

        switch config.mode {
        case .create:
            _message = State(initialValue: "")
            let defaultDate = PersonDetailView.defaultReminderDate()
            _dueDate = State(initialValue: defaultDate)
            _markComplete = State(initialValue: false)
        case .edit(let reminder):
            _message = State(initialValue: reminder.message)
            _dueDate = State(initialValue: reminder.dueDate)
            _markComplete = State(initialValue: reminder.completed)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Message", text: $message, axis: .vertical)
                        .focused($isFocused)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                }

                Section("Due Date") {
                    DatePicker(
                        "Due",
                        selection: $dueDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section {
                    Toggle("Mark Complete", isOn: $markComplete)
                }
            }
            .navigationTitle(config.mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(!canSave)
                }
            }
            .task {
                await MainActor.run {
                    isFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveReminder() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let sanitizedDueDate = max(dueDate, Date())

        switch config.mode {
        case .create(let person):
            let reminder = Reminder(
                dueDate: sanitizedDueDate,
                message: trimmed,
                completed: markComplete,
                person: person
            )
            modelContext.insert(reminder)
            persistChanges(for: reminder)
        case .edit(let reminder):
            reminder.update(dueDate: sanitizedDueDate, message: trimmed)
            reminder.completed = markComplete
            persistChanges(for: reminder)
        }

        dismiss()
    }

    private func persistChanges(for reminder: Reminder) {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save reminder: \(error.localizedDescription)")
        }

        Task {
            if reminder.completed || ReminderSchedulingPolicy.shouldCancelReminder(reminder) {
                await ReminderScheduler.cancelReminder(reminder)
            } else {
                await ReminderScheduler.scheduleReminder(reminder)
            }
        }
    }
}

private extension ReminderEditorConfig.Mode {
    var title: String {
        switch self {
        case .create:
            return "New Reminder"
        case .edit:
            return "Edit Reminder"
        }
    }
}

private struct PersonEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var person: Person
    let onDelete: () -> Void

    @Query(sort: \Organization.name, order: .forward)
    private var organizations: [Organization]

    @State private var firstName: String
    @State private var lastName: String
    @State private var title: String
    @State private var selectedOrganizationID: UUID?
    @State private var isArchived: Bool
    @State private var showDeleteConfirmation = false

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(person: Person, onDelete: @escaping () -> Void) {
        self._person = Bindable(person)
        self.onDelete = onDelete
        _firstName = State(initialValue: person.firstName)
        _lastName = State(initialValue: person.lastName)
        _title = State(initialValue: person.title ?? "")
        _selectedOrganizationID = State(initialValue: person.organization?.id)
        _isArchived = State(initialValue: person.isArchived)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("First Name", text: $firstName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    TextField("Last Name", text: $lastName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                }

                Section("Organization") {
                    Picker("Organization", selection: $selectedOrganizationID) {
                        Text("None")
                            .tag(Optional<UUID>.none)

                        ForEach(organizations) { organization in
                            Text(organization.name)
                                .tag(Optional(organization.id))
                        }
                    }
                }

                Section("Status") {
                    Toggle("Archived", isOn: $isArchived)
                }

                Section {
                    Button("Delete Person", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .confirmationDialog(
            "Delete this person?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Person", role: .destructive) {
                deletePerson()
            }
        } message: {
            Text("This will remove the person and their related notes and reminders.")
        }
    }

    private func saveChanges() {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        person.firstName = trimmedFirst
        person.lastName = trimmedLast
        person.title = trimmedTitle.isEmpty ? nil : trimmedTitle
        person.organization = organizationSelection()

        if isArchived {
            person.archive()
        } else {
            person.unarchive()
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save person: \(error.localizedDescription)")
        }

        dismiss()
    }

    private func deletePerson() {
        modelContext.delete(person)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to delete person: \(error.localizedDescription)")
        }

        dismiss()
        onDelete()
    }

    private func organizationSelection() -> Organization? {
        guard let selectedOrganizationID else {
            return nil
        }

        return organizations.first { $0.id == selectedOrganizationID }
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
        Interview Highlights:
        - Participants resonated with the new onboarding copy.
        - Need to refine the dashboard empty state.
        """, person: person)

        let noteThree = Note(createdAt: noteThreeDate, text: """
        Wrapped synthesis session. Next step: compile insights for leadership review. ✅
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
