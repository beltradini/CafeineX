import SwiftData
import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: HomeViewModel

    private enum Scope: String, CaseIterable, Identifiable {
        case all
        case caffeine
        case nicotine
        case cigarettes

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "All"
            case .caffeine: "Caffeine"
            case .nicotine: "Nicotine"
            case .cigarettes: "Cigarettes"
            }
        }

        var kind: ExposureKind? {
            switch self {
            case .all: nil
            case .caffeine: .caffeine
            case .nicotine: .nicotine
            case .cigarettes: nil
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
                    CXSurfaceCard(
                        cornerRadius: CXTheme.smallCornerRadius,
                        contentPadding: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                    ) {
                        if dynamicTypeSize.isAccessibilitySize {
                            Picker("Search scope", selection: $scope) {
                                ForEach(Scope.allCases) { scope in
                                    Text(scope.title)
                                        .tag(scope)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 10)
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
                }
                .listRowInsets(EdgeInsets())
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
            .contentMargins(.bottom, CXTheme.bottomContentInset, for: .scrollContent)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
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
            settingsLinksCard(Array(SettingsDestination.allCases))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                settingsLinksCard(settingsResults)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
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
    private func settingsLinksCard(_ destinations: [SettingsDestination]) -> some View {
        CXSurfaceCard(contentPadding: EdgeInsets()) {
            VStack(spacing: 0) {
                ForEach(destinations) { destination in
                    settingsLink(destination)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)

                    if destination != destinations.last {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
        }
    }

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
                PrivacyAndDataView(viewModel: viewModel)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: destination.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CXTheme.caffeineAccent)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(destination.title)
                        .font(.headline)
                    Text(destination.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
    }

    private var allItems: [ExposureItem] {
        ExposureItem.combined(
            caffeineEntries: caffeineEntries,
            nicotineEntries: nicotineEntries
        )
    }

    private var eventResults: [ExposureItem] {
        let results = searchEngine.results(
            in: allItems,
            query: searchText,
            kind: scope.kind
        )
        guard scope == .cigarettes else { return results }
        return results.filter {
            guard case .nicotine(let entry) = $0 else { return false }
            return entry.product == .cigarette
        }
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
        SearchView(viewModel: HomeViewModel())
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
