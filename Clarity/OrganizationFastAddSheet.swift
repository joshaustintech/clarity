import SwiftUI
import SwiftData

struct OrganizationFastAddSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var domain: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDomain: String? {
        let value = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    TextField("Domain", text: $domain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
            }
            .navigationTitle("New Organization")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveOrganization()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func saveOrganization() {
        let organization = Organization(
            name: trimmedName,
            domain: trimmedDomain
        )

        modelContext.insert(organization)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Failed to save organization: \(error.localizedDescription)")
        }
    }
}

#Preview {
    OrganizationFastAddSheet()
        .modelContainer(ModelContainer.previewContainer())
}
