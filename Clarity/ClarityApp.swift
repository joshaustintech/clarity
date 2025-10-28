import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    private let sharedModelContainer = ModelContainer.appContainer()
    @State private var pendingReminderRoute: ReminderRoute?

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
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .task {
                ReminderScheduler.configure()
                await ReminderScheduler.registerDeepLinkHandler { url in
                    handleDeepLink(url)
                }
            }
            .sheet(item: $pendingReminderRoute) { route in
                NavigationStack {
                    ReminderDeepLinkView(reminderID: route.id)
                }
            }
        }
    }

    @MainActor
    private func handleDeepLink(_ url: URL) {
        guard let deepLink = AppDeepLink.parse(url) else {
            return
        }

        switch deepLink {
        case .reminder(let id):
            pendingReminderRoute = ReminderRoute(id: id)
        }
    }
}

private struct ReminderRoute: Identifiable {
    let id: UUID
}
