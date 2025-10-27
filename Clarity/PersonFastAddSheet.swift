import SwiftUI
import SwiftData

struct PersonFastAddSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Organization.name, order: .forward)
    private var organizations: [Organization]

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var title: String = ""
    @State private var selectedOrganizationID: UUID?
    @State private var webLinkFields: [WebLinkField] = [WebLinkField()]

    private var trimmedFirstName: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLastName: String {
        lastName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedTitle: String? {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var canSave: Bool {
        guard !trimmedFirstName.isEmpty, !trimmedLastName.isEmpty else { return false }

        return webLinkFields.allSatisfy { field in
            let trimmed = field.url.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty || isValidURL(trimmed)
        }
    }

    private var hasInvalidLink: Bool {
        webLinkFields.contains { field in
            let trimmed = field.url.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && !isValidURL(trimmed)
        }
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

                    Picker("Organization", selection: $selectedOrganizationID) {
                        Text("None")
                            .tag(Optional<UUID>.none)

                        ForEach(organizations) { organization in
                            Text(organization.name)
                                .tag(Optional(organization.id))
                        }
                    }
                }

                Section("Web Links") {
                    if webLinkFields.isEmpty {
                        Text("Add relevant links to quickly reference profiles or resources.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach($webLinkFields) { $field in
                        HStack {
                            TextField(
                                "Link URL",
                                text: $field.url,
                                prompt: Text("https://example.com")
                            )
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            if webLinkFields.count > 1 || !field.url.isEmpty {
                                Button(role: .destructive) {
                                    removeLinkField(field.id)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        webLinkFields.append(WebLinkField())
                    } label: {
                        Label("Add Link", systemImage: "plus")
                    }

                    if hasInvalidLink {
                        Text("Enter valid URLs that include http or https.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePerson()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

// MARK: - Private Helpers

private extension PersonFastAddSheet {
    struct WebLinkField: Identifiable {
        let id = UUID()
        var url: String = ""
    }

    func isValidURL(_ string: String) -> Bool {
        guard
            let components = URLComponents(string: string),
            let scheme = components.scheme?.lowercased(),
            (scheme == "http" || scheme == "https"),
            components.host != nil
        else {
            return false
        }

        return true
    }

    func savePerson() {
        let person = Person(
            firstName: trimmedFirstName,
            lastName: trimmedLastName,
            title: trimmedTitle,
            organization: organizationSelection()
        )

        let links = webLinkFields
            .map { $0.url.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { WebLink(url: $0, person: person) }

        person.webLinks.append(contentsOf: links)
        modelContext.insert(person)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Failed to save person: \(error.localizedDescription)")
        }
    }

    func organizationSelection() -> Organization? {
        guard let selectedOrganizationID else {
            return nil
        }

        return organizations.first(where: { $0.id == selectedOrganizationID })
    }

    func removeLinkField(_ id: UUID) {
        webLinkFields.removeAll { $0.id == id }
    }
}

#Preview {
    PersonFastAddSheet()
        .modelContainer(ModelContainer.previewContainer())
}
