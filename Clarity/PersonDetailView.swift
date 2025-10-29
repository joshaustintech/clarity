import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var person: Person

    @State private var activeSheet: PersonDetailSheet?
    @State private var timelineSortOrder: TimelineSortOrder = .reverseChronological
    @State private var noteFilter: NoteFilter = .active
    @State private var reminderFilter: ReminderFilter = .upcoming

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

    private var personReminders: [Reminder] {
        person.reminders
    }

    private var overdueReminders: [Reminder] {
        let now = Date()
        return personReminders
            .filter { !$0.completed && $0.dueDate < now }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var scheduledReminders: [Reminder] {
        ReminderCelebrationEvaluator
            .remindersUpcoming(personReminders)
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var completedReminders: [Reminder] {
        personReminders
            .filter(\.completed)
            .sorted { $0.dueDate > $1.dueDate }
    }

    private var hasActiveReminders: Bool {
        !overdueReminders.isEmpty || !scheduledReminders.isEmpty
    }

    private var nextReminder: Reminder? {
        overdueReminders.first ?? scheduledReminders.first
    }

    private var sortedWebLinks: [WebLink] {
        person.webLinks.sorted { lhs, rhs in
            lhs.createdAt < rhs.createdAt
        }
    }

    private var webLinkItems: [WebLinkItem] {
        sortedWebLinks.compactMap { link in
            guard let url = normalizedURL(from: link.url) else { return nil }

            return WebLinkItem(
                id: link.id,
                url: url,
                title: displayHost(for: url),
                detail: displayDetail(for: url)
            )
        }
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

            Section("Links") {
                if webLinkItems.isEmpty {
                    ContentUnavailableView(
                        "No Links",
                        systemImage: "link",
                        description: Text("Add web links to quickly launch resources for this person.")
                    )
                    .padding(.vertical, 4)
                } else {
                    ForEach(webLinkItems) { item in
                        Link(destination: item.url) {
                            PersonWebLinkRow(item: item)
                        }
                        .accessibilityIdentifier("personDetail.webLinkRow")
                    }
                }
            }

            Section("Reminders") {
                reminderSummaryCard
                    .padding(.vertical, 4)

                Button {
                    reminderFilter = .upcoming
                    activeSheet = .reminder(ReminderEditorConfig(mode: .create(person: person)))
                } label: {
                    Label("New Reminder", systemImage: "plus.circle.fill")
                }

                if personReminders.isEmpty {
                    ContentUnavailableView(
                        "No Reminders",
                        systemImage: "bell",
                        description: Text("Add reminders to keep follow-ups on track.")
                    )
                    .padding(.vertical, 4)
                } else {
                    reminderFilterPicker
                        .padding(.vertical, 4)
                    remindersList
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
    var reminderSummaryCard: some View {
        ReminderSummaryCard(
            overdueCount: overdueReminders.count,
            upcomingCount: scheduledReminders.count,
            completedCount: completedReminders.count,
            spotlight: nextReminder
        )
    }

    @ViewBuilder
    var reminderFilterPicker: some View {
        Picker("Reminder Filter", selection: $reminderFilter) {
            ForEach(ReminderFilter.allCases) { option in
                Text(option.label)
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Reminder filter")
    }

    @ViewBuilder
    var remindersList: some View {
        switch reminderFilter {
        case .upcoming:
            if hasActiveReminders {
                if !overdueReminders.isEmpty {
                    ReminderGroupHeader(title: "Overdue")
                        .padding(.top, 4)
                    ForEach(overdueReminders) { reminder in
                        reminderRow(for: reminder, status: .overdue)
                    }
                }

                if !scheduledReminders.isEmpty {
                    ReminderGroupHeader(title: "Scheduled")
                        .padding(.top, overdueReminders.isEmpty ? 4 : 12)
                    ForEach(scheduledReminders) { reminder in
                        reminderRow(for: reminder, status: .upcoming)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Active Reminders",
                    systemImage: "bell.badge",
                    description: Text("Add a reminder to schedule your next follow-up.")
                )
                .padding(.vertical, 4)
            }
        case .completed:
            if completedReminders.isEmpty {
                ContentUnavailableView(
                    "No Completed Reminders",
                    systemImage: "checkmark.circle",
                    description: Text("Mark reminders complete to see them here.")
                )
                .padding(.vertical, 4)
            } else {
                ReminderGroupHeader(title: "Completed")
                    .padding(.top, 4)
                ForEach(completedReminders) { reminder in
                    reminderRow(for: reminder, status: .completed)
                }
            }
        }
    }

    @ViewBuilder
    func reminderRow(for reminder: Reminder, status: PersonReminderRow.Status) -> some View {
        NavigationLink {
            ReminderDetailView(reminder: reminder)
        } label: {
            PersonReminderRow(
                reminder: reminder,
                status: status,
                toggleCompletion: { toggleReminderCompletion(reminder) }
            )
        }
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

    enum ReminderFilter: String, CaseIterable, Identifiable {
        case upcoming
        case completed

        var id: ReminderFilter { self }

        var label: String {
            switch self {
            case .upcoming:
                return "Upcoming"
            case .completed:
                return "Completed"
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
                        Text(organization.name)
                            .font(.headline)
                            .foregroundStyle(.secondary)
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

    private func normalizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty {
            return url
        }

        return URL(string: "https://\(trimmed)")
    }

    private func displayHost(for url: URL) -> String {
        if let host = url.host, !host.isEmpty {
            return host
        }

        return url.absoluteString
    }

    private func displayDetail(for url: URL) -> String? {
        var detail = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if let query = url.query, !query.isEmpty {
            let queryString = "?\(query)"
            detail = detail.isEmpty ? queryString : "\(detail)\(queryString)"
        }

        if let fragment = url.fragment, !fragment.isEmpty {
            let fragmentString = "#\(fragment)"
            detail = detail.isEmpty ? fragmentString : "\(detail)\(fragmentString)"
        }

        if let decoded = detail.removingPercentEncoding {
            detail = decoded
        }

        return detail.isEmpty ? nil : detail
    }

    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to persist changes: \(error.localizedDescription)")
        }
    }
}

private struct ReminderGroupHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReminderSummaryCard: View {
    let overdueCount: Int
    let upcomingCount: Int
    let completedCount: Int
    let spotlight: Reminder?

    private var hasActiveReminders: Bool {
        overdueCount > 0 || upcomingCount > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bell")
                    .imageScale(.medium)
                    .foregroundStyle(.blue)

                Text("Reminder Overview")
                    .font(.headline)
            }

            HStack(spacing: 16) {
                ReminderSummaryMetric(title: "Overdue", value: overdueCount, tint: .red)
                ReminderSummaryMetric(title: "Upcoming", value: upcomingCount, tint: .blue)
                ReminderSummaryMetric(title: "Completed", value: completedCount, tint: .green)
            }

            Divider()

            if let reminder = spotlight {
                VStack(alignment: .leading, spacing: 6) {
                    Text(spotlightHeading(for: reminder))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(reminder.message)
                        .font(.body)

                    Text(spotlightDueDate(for: reminder))
                        .font(.caption)
                        .foregroundStyle(spotlightColor(for: reminder))
                }
            } else if !hasActiveReminders {
                Text("No active reminders yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
    }

    private func spotlightHeading(for reminder: Reminder) -> String {
        reminder.dueDate < Date() ? "Overdue Follow-Up" : "Next Follow-Up"
    }

    private func spotlightDueDate(for reminder: Reminder) -> String {
        reminder.dueDate.formatted(date: .abbreviated, time: .shortened)
    }

    private func spotlightColor(for reminder: Reminder) -> Color {
        reminder.dueDate < Date() ? .red : (reminder.isDueSoon ? .orange : .secondary)
    }
}

private struct ReminderSummaryMetric: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("\(value)"))
    }
}

private struct WebLinkItem: Identifiable {
    let id: UUID
    let url: URL
    let title: String
    let detail: String?
}

private struct PersonWebLinkRow: View {
    let item: WebLinkItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .imageScale(.medium)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let detail = item.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.up.right.square")
                .imageScale(.small)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray.opacity(0.12))
        )
    }
}

private struct PersonReminderRow: View {
    enum Status {
        case overdue
        case upcoming
        case completed

        var badgeLabel: String? {
            switch self {
            case .overdue:
                return "Overdue"
            case .upcoming:
                return nil
            case .completed:
                return "Completed"
            }
        }

        var badgeColor: Color {
            switch self {
            case .overdue:
                return .red
            case .upcoming:
                return .blue
            case .completed:
                return .green
            }
        }

        func subtitle(for reminder: Reminder) -> String {
            let formatted = reminder.dueDate.formatted(date: .abbreviated, time: .shortened)
            switch self {
            case .overdue:
                return "Was due \(formatted)"
            case .upcoming:
                return "Due \(formatted)"
            case .completed:
                return "Completed \(formatted)"
            }
        }

        func subtitleColor(for reminder: Reminder) -> Color {
            switch self {
            case .overdue:
                return .red
            case .upcoming:
                return reminder.isDueSoon ? .orange : .secondary
            case .completed:
                return .secondary
            }
        }
    }

    @Bindable var reminder: Reminder
    let status: Status
    let toggleCompletion: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.message)
                    .font(.headline)
                    .foregroundStyle(messageColor)

                HStack(spacing: 8) {
                    if let label = status.badgeLabel {
                        Text(label)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.badgeColor.opacity(0.16), in: Capsule())
                            .foregroundStyle(status.badgeColor)
                    }

                    Text(status.subtitle(for: reminder))
                        .font(.caption)
                        .foregroundStyle(status.subtitleColor(for: reminder))
                }
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

    private var messageColor: Color {
        reminder.completed ? .secondary : .primary
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
