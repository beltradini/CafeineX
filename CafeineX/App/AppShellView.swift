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
    @Query private var drinks: [Drink]

    @State private var selectedTab = AppTab.home
    @State private var quickAddCoordinator = QuickAddCoordinator()
    @State private var homeViewModel = HomeViewModel()

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
                    SearchView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .environment(quickAddCoordinator)
        .sheet(isPresented: $quickAddCoordinator.isPresented) {
            QuickAddSheet(initialKind: quickAddCoordinator.initialKind) { request in
                save(request)
            }
        }
        .preferredColorScheme(appearanceStore.selection.colorScheme)
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
        case .nicotine(let product, let quantity, let unit, let date, let note):
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

#Preview {
    AppShellView()
        .environment(SleepScheduleStore())
        .environment(CaffeineSensitivityStore())
        .environment(AppearanceStore())
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
