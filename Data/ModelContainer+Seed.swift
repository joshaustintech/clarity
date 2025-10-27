import Foundation
import SwiftData

extension ModelContainer {
    static func appContainer() -> ModelContainer {
        createContainer(configuration: ModelConfiguration())
    }

    static func previewContainer() -> ModelContainer {
        let container = createContainer(
            configuration: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        seedPreviewData(in: container)

        return container
    }
}

// MARK: - Private Helpers

private extension ModelContainer {
    static func createContainer(configuration: ModelConfiguration) -> ModelContainer {
        let schema = Schema([
            Person.self,
            Organization.self,
            Note.self,
            Reminder.self,
            Tag.self,
            WebLink.self
        ])

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    static func seedPreviewData(in container: ModelContainer) {
        let context = ModelContext(container)

        let organization = Organization(
            name: "Clarity Labs",
            domain: "clarity.app"
        )

        let discoveryTag = Tag(name: "Discovery")
        let strategyTag = Tag(name: "Strategy")
        let onboardingTag = Tag(name: "Onboarding")
        let alexPortfolio = WebLink(url: "https://alexrivers.design")
        let morganLinkedIn = WebLink(url: "https://linkedin.com/in/morganchen")
        let morganDocs = WebLink(url: "https://clarity.app/roadmap")

        let alex = Person(
            firstName: "Alex",
            lastName: "Rivers",
            title: "Design Lead"
        )

        let morgan = Person(
            firstName: "Morgan",
            lastName: "Chen",
            title: "Product Manager"
        )

        let kickoffNote = Note(text: "Schedule kickoff with leadership.")
        let researchNote = Note(text: "Validate assumptions with user interviews.")
        let onboardingNote = Note(text: "Draft onboarding flow outline.")

        let reminder = Reminder(
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            message: "Prepare weekly sync agenda."
        )

        context.insert(organization)
        context.insert(discoveryTag)
        context.insert(strategyTag)
        context.insert(onboardingTag)
        context.insert(alexPortfolio)
        context.insert(morganLinkedIn)
        context.insert(morganDocs)
        context.insert(alex)
        context.insert(morgan)
        context.insert(kickoffNote)
        context.insert(researchNote)
        context.insert(onboardingNote)
        context.insert(reminder)

        alex.organization = organization
        morgan.organization = organization

        alex.tags.append(contentsOf: [discoveryTag, strategyTag])
        morgan.tags.append(onboardingTag)

        alex.notes.append(contentsOf: [kickoffNote, researchNote])
        morgan.notes.append(onboardingNote)

        alex.webLinks.append(alexPortfolio)
        morgan.webLinks.append(contentsOf: [morganLinkedIn, morganDocs])

        kickoffNote.tags.append(strategyTag)
        researchNote.tags.append(discoveryTag)
        onboardingNote.tags.append(onboardingTag)

        morgan.reminders.append(reminder)

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed preview data: \(error.localizedDescription)")
        }
    }
}
