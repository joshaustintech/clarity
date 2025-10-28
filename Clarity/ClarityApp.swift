import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    private let sharedModelContainer = ModelContainer.appContainer()
    @State private var pendingReminderRoute: ReminderRoute?
    @State private var selectedTab: Tab = .reminders

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                RemindersView()
                    .tag(Tab.reminders)
                    .tabItem {
                        Label("Reminders", systemImage: "bell.badge.fill")
                    }

                PeopleView()
                    .tag(Tab.people)
                    .tabItem {
                        Label("People", systemImage: "person.2.fill")
                    }

                OrganizationsView()
                    .tag(Tab.organizations)
                    .tabItem {
                        Label("Organizations", systemImage: "building.2.fill")
                    }
            }
            .modelContainer(sharedModelContainer)
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .task {
                ReminderScheduler.configure()
                ReminderScheduler.registerDeepLinkHandler { url in
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

private enum Tab: Hashable {
    case reminders
    case people
    case organizations
}
