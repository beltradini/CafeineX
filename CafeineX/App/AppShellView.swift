import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case home
    case history
    case profile
    case search
}

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppearanceStore.self) private var appearanceStore
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(NotificationPreferencesStore.self) private var notificationPreferencesStore
    @Environment(RecentActionStore.self) private var recentActionStore
    @Environment(\.scenePhase) private var scenePhase
    @Query private var drinks: [Drink]
    @Query private var cigaretteProfiles: [CigaretteProfile]
    @Query private var caffeineEntries: [CaffeineEntry]

    @Bindable var persistenceIssueCenter: PersistenceIssueCenter

    @State private var selectedTab = AppTab.home
    @State private var quickAddCoordinator = QuickAddCoordinator()
    @State private var homeViewModel: HomeViewModel
    private let notificationScheduler = NotificationScheduler()

    init(persistenceIssueCenter: PersistenceIssueCenter) {
        self.persistenceIssueCenter = persistenceIssueCenter
        _homeViewModel = State(
            initialValue: HomeViewModel(persistenceIssueCenter: persistenceIssueCenter)
        )
    }

    var body: some View {
        @Bindable var quickAddCoordinator = quickAddCoordinator

        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeView(viewModel: homeViewModel)
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath", value: .history) {
                NavigationStack {
                    HistoryView()
                }
            }

            Tab("Profile", systemImage: "person.crop.circle.fill", value: .profile) {
                NavigationStack {
                    ProfileView(viewModel: homeViewModel)
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                NavigationStack {
                    SearchView(viewModel: homeViewModel)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .environment(persistenceIssueCenter)
        .environment(quickAddCoordinator)
        .onOpenURL { url in
            switch url.host {
            case "history":
                selectedTab = .history
            case "quick-add":
                selectedTab = .home
                quickAddCoordinator.present()
            default:
                break
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }

            consumeWidgetCommands()

        }
        .task {
            homeViewModel.attachRecentActionStore(recentActionStore)
            consumeWidgetCommands()
            await refreshNotifications()
        }
        .sheet(isPresented: $quickAddCoordinator.isPresented) {
            QuickAddSheet(initialKind: quickAddCoordinator.initialKind) { request in
                save(request)
            }
            // Sheets are a separate presentation boundary. Keep the save-error
            // coordinator explicit so QuickAddSheet can run its bootstrap task
            // even when SwiftUI does not propagate the parent environment.
            .environment(persistenceIssueCenter)
        }
        .preferredColorScheme(appearanceStore.selection.colorScheme)
        .alert(item: Binding(
            get: { persistenceIssueCenter.issue },
            set: { if $0 == nil { persistenceIssueCenter.dismiss() } }
        )) { issue in
            Alert(
                title: Text("Could Not Save"),
                message: Text("\(issue.operation) failed. \(issue.errorDescription)"),
                primaryButton: .default(Text("Try Again")) {
                    persistenceIssueCenter.retry()
                },
                secondaryButton: .cancel(Text("Dismiss")) {
                    persistenceIssueCenter.dismiss()
                }
            )
        }
    }

    private func save(_ request: QuickAddRequest) -> Bool {
        switch request {
        case .caffeine(let drinkID, let name, let milligrams, let date):
            homeViewModel.addDrink(
                name: name,
                caffeineMG: milligrams,
                consumedAt: date,
                drink: drinkID.flatMap { identifier in
                    drinks.first { $0.id == identifier }
                },
                context: modelContext
            )
        case .nicotine(
            let product,
            let quantity,
            let unit,
            let date,
            let note,
            let profileID,
            let cigaretteContext
        ):
            if product == .cigarette {
                homeViewModel.addCigarette(
                    quantity: quantity,
                    usedAt: date,
                    profileID: profileID,
                    cigaretteContext: cigaretteContext,
                    note: note,
                    profiles: cigaretteProfiles,
                    context: modelContext
                )
            } else {
                homeViewModel.addNicotine(
                    product: product,
                    quantity: quantity,
                    unit: unit,
                    usedAt: date,
                    note: note,
                    context: modelContext
                )
            }
        }
    }

    private func refreshNotifications() async {
        let selectedDrink = drinks.first {
            $0.id == notificationPreferencesStore.preferences.habitualDrinkID
        }

        try? await notificationScheduler.reschedule(
            preferences: notificationPreferencesStore.preferences,
            sleepSchedule: sleepScheduleStore.schedule,
            drinkName: selectedDrink?.name
        )
    }

    // MARK: - Widget Command

    private func consumeWidgetCommands() {
        var didChange = false

        for command in WidgetCommandStore.pendingDrinkCommands() {
            let alreadySaved = caffeineEntries.contains { entry in
                entry.source == .widget
                    && entry.drinkName == command.name
                    && abs(entry.caffeineMG - command.caffeineMG) < 0.01
                    && abs(entry.consumedAt.timeIntervalSince(command.createdAt)) < 0.01
            }
            if alreadySaved {
                WidgetCommandStore.acknowledgeDrinkCommand(id: command.id)
                continue
            }

            let matchedDrink = drinks.first {
                $0.name == command.name
                    && abs($0.caffeineMG - command.caffeineMG) < 0.01
            }

            let didSave = homeViewModel.addDrink(
                name: command.name,
                caffeineMG: command.caffeineMG,
                consumedAt: command.createdAt,
                drink: matchedDrink,
                context: modelContext,
                source: .widget
            )
            guard didSave else { break }

            WidgetCommandStore.acknowledgeDrinkCommand(id: command.id)
            didChange = true
        }

        if didChange {
            CafeineXWidgetStore.reloadTimelines()
        }
    }
}

#Preview {
    AppShellView(persistenceIssueCenter: PersistenceIssueCenter())
        .environment(SleepScheduleStore())
        .environment(CaffeineSensitivityStore())
        .environment(AppearanceStore())
        .environment(RecentActionStore())
        .environment(NotificationPreferencesStore())
        .modelContainer(
            for: [
                CaffeineEntry.self,
                Drink.self,
                NicotineEntry.self,
                UserProfile.self,
                AwarenessCheckIn.self,
                DrinkMetadata.self,
                DrinkDetails.self,
                HealthSyncOutboxItem.self,
            ],
            inMemory: true
        )
}
