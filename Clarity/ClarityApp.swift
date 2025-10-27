import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    private let sharedModelContainer = ModelContainer.appContainer()

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
