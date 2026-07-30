import SwiftData
import SwiftUI

struct SearchView: View {
    private enum Scope: String, CaseIterable, Identifiable {
        case all
        case caffeine
        case nicotine

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "All"
            case .caffeine: "Caffeine"
            case .nicotine: "Nicotine"
            }
        }

        var kind: ExposureKind? {
            switch self {
            case .all: nil
            case .caffeine: .caffeine
            case .nicotine: .nicotine
            }
        }
    }

    private enum SettingsDestination: String, CaseIterable, Identifiable {
        case guidance
        case appearance
        case privacy

        var id: Self { self }

        var title: String {
            switch self {
            case .guidance: "Personal Guidance"
            case .appearance: "Appearance"
            case .privacy: "Privacy & Data"
            }
        }

        var subtitle: String {
            switch self {
            case .guidance: "Bedtime, cutoff, and caffeine sensitivity"
            case .appearance: "System, Light, and Dark"
            case .privacy: "Local storage and Apple Health behavior"
            }
        }

        var symbol: String {
            switch self {
            case .guidance: "moon.zzz"
            case .appearance: "circle.lefthalf.filled"
            case .privacy: "hand.raised.fill"
            }
        }

        var searchableText: String {
            "\(title) \(subtitle)"
        }
    }

    @Environment(QuickAddCoordinator.self) private var quickAddCoordinator
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore

    @Query(sort: \CaffeineEntry.consumedAt, order: .reverse)
    private var caffeineEntries: [CaffeineEntry]

    @Query(sort: \NicotineEntry.usedAt, order: .reverse)
    private var nicotineEntries: [NicotineEntry]

    @State private var searchText = ""
    @State private var scope = Scope.all

    private let searchEngine = ExposureSearchEngine()

    var body: some View {
        ZStack {
            CXBackgroundView()

            List {
                Section {
                    if dynamicTypeSize.isAccessibilitySize {
                        Picker("Search scope", selection: $scope) {
                            ForEach(Scope.allCases) { scope in
                                Text(scope.title)
                                    .tag(scope)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Picker("Search scope", selection: $scope) {
                            ForEach(Scope.allCases) { scope in
                                Text(scope.title)
                                    .tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Search scope")
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if searchText.isEmpty {
                    searchLanding
                } else if eventResults.isEmpty && settingsResults.isEmpty {
                    Section {
                        ContentUnavailableView.search(text: searchText)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } else {
                    resultSections
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, CXTheme.horizontalPadding, for: .scrollContent)
            .contentMargins(.bottom, 32, for: .scrollContent)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                QuickAddToolbarButton()
            }
        }
        .searchable(
            text: $searchText,
            placement: .automatic,
            prompt: "Events, amounts, dates, or settings"
        )
        .searchSuggestions {
            if searchText.isEmpty {
                Text("Espresso")
                    .searchCompletion("Espresso")
                Text("Apple Health")
                    .searchCompletion("Apple Health")
                Text("Nicotine")
                    .searchCompletion("Nicotine")
            }
        }
    }

    @ViewBuilder
    private var searchLanding: some View {
        Section("Shortcuts") {
            ForEach(SettingsDestination.allCases) { destination in
                settingsLink(destination)
            }
        }

        Section("Recent Events") {
            if allItems.isEmpty {
                ContentUnavailableView {
                    Label("Nothing to search yet", systemImage: "magnifyingglass")
                } description: {
                    Text("Add caffeine or nicotine to build your searchable timeline.")
                } actions: {
                    Button("Quick Add") {
                        quickAddCoordinator.present()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(allItems.prefix(5)) { item in
                    eventLink(item)
                }
            }
        }
    }

    @ViewBuilder
    private var resultSections: some View {
        if !settingsResults.isEmpty {
            Section("Settings") {
                ForEach(settingsResults) { destination in
                    settingsLink(destination)
                }
            }
        }

        if !eventResults.isEmpty {
            Section("\(eventResults.count) Events") {
                ForEach(eventResults) { item in
                    eventLink(item)
                }
            }
        }
    }

    private func eventLink(_ item: ExposureItem) -> some View {
        NavigationLink {
            ExposureDetailView(item: item)
        } label: {
            ExposureRow(item: item, showsDate: true)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func settingsLink(_ destination: SettingsDestination) -> some View {
        NavigationLink {
            switch destination {
            case .guidance:
                GuidanceSettingsView(
                    sleepScheduleStore: sleepScheduleStore,
                    sensitivityStore: sensitivityStore
                )
            case .appearance:
                AppearanceSettingsView()
            case .privacy:
                PrivacyAndDataView()
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text(destination.title)
                        .font(.headline)
                    Text(destination.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: destination.symbol)
                    .foregroundStyle(CXTheme.caffeineAccent)
            }
        }
    }

    private var allItems: [ExposureItem] {
        ExposureItem.combined(
            caffeineEntries: caffeineEntries,
            nicotineEntries: nicotineEntries
        )
    }

    private var eventResults: [ExposureItem] {
        searchEngine.results(
            in: allItems,
            query: searchText,
            kind: scope.kind
        )
    }

    private var settingsResults: [SettingsDestination] {
        guard scope == .all else { return [] }
        let query = normalized(searchText)
        guard !query.isEmpty else { return [] }
        return SettingsDestination.allCases.filter {
            normalized($0.searchableText).contains(query)
        }
    }

    private func normalized(_ value: String) -> String {
        value.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environment(QuickAddCoordinator())
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
