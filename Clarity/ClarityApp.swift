import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let configuration = ModelConfiguration()

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                PeopleView()
                    .tabItem {
                        Label("People", systemImage: "person.2.fill")
                    }

                OrganizationsView()
                    .tabItem {
                        Label("Organizations", systemImage: "building.2.fill")
                    }

                RemindersView()
                    .tabItem {
                        Label("Reminders", systemImage: "bell.badge.fill")
                    }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}
