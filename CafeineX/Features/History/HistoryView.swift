import SwiftData
import SwiftUI

struct HistoryView: View {
    private enum SubstanceFilter: String, CaseIterable, Identifiable {
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
    }

    private enum SourceFilter: String, CaseIterable, Identifiable {
        case all
        case local
        case health

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "All sources"
            case .local: "Local"
            case .health: "Apple Health"
            }
        }
    }

    private enum DateRange: String, CaseIterable, Identifiable {
        case week
        case month
        case all

        var id: Self { self }

        var title: String {
            switch self {
            case .week: "7 days"
            case .month: "30 days"
            case .all: "All time"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(QuickAddCoordinator.self) private var quickAddCoordinator

    @Query(sort: \CaffeineEntry.consumedAt, order: .reverse)
    private var caffeineEntries: [CaffeineEntry]

    @Query(sort: \NicotineEntry.usedAt, order: .reverse)
    private var nicotineEntries: [NicotineEntry]

    @State private var searchText = ""
    @State private var substanceFilter = SubstanceFilter.all
    @State private var sourceFilter = SourceFilter.all
    @State private var dateRange = DateRange.month

    private let calendar: Calendar
    private let searchEngine = ExposureSearchEngine()

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    var body: some View {
        ZStack {
            CXBackgroundView()

            List {
                summarySection
                filterSection

                if filteredItems.isEmpty {
                    emptySection
                } else {
                    ForEach(groupedItems, id: \.date) { group in
                        Section {
                            ForEach(group.items) { item in
                                NavigationLink {
                                    ExposureDetailView(item: item)
                                } label: {
                                    ExposureRow(item: item)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if item.canModify {
                                        Button("Delete", role: .destructive) {
                                            delete(item)
                                        }
                                    }
                                }
                            }
                        } header: {
                            dayHeader(date: group.date, items: group.items)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, CXTheme.horizontalPadding, for: .scrollContent)
            .contentMargins(.bottom, 32, for: .scrollContent)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                QuickAddToolbarButton()
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search this history"
        )
    }

    private var summarySection: some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                spacing: 12
            ) {
                summaryCard(
                    title: "Events",
                    value: filteredItems.count.formatted(),
                    symbol: "list.bullet",
                    tint: CXTheme.healthAccent
                )
                summaryCard(
                    title: "Caffeine",
                    value: "\(Int(totalCaffeineMG.rounded())) mg",
                    symbol: "cup.and.saucer.fill",
                    tint: CXTheme.caffeineAccent
                )
                summaryCard(
                    title: "Nicotine",
                    value: totalNicotine.displayText,
                    symbol: "waveform.path.ecg",
                    tint: CXTheme.nicotineAccent
                )
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var filterSection: some View {
        Section("Filters") {
            if dynamicTypeSize.isAccessibilitySize {
                Picker("Substance", selection: $substanceFilter) {
                    ForEach(SubstanceFilter.allCases) { filter in
                        Text(filter.title)
                            .tag(filter)
                    }
                }
                .pickerStyle(.menu)
            } else {
                Picker("Substance", selection: $substanceFilter) {
                    ForEach(SubstanceFilter.allCases) { filter in
                        Text(filter.title)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("History substance")
            }

            Picker("Date range", selection: $dateRange) {
                ForEach(DateRange.allCases) { range in
                    Text(range.title)
                        .tag(range)
                }
            }

            Picker("Source", selection: $sourceFilter) {
                ForEach(SourceFilter.allCases) { source in
                    Text(source.title)
                        .tag(source)
                }
            }
        }
        .listRowBackground(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }

    private var emptySection: some View {
        Section {
            ContentUnavailableView {
                Label(
                    allItems.isEmpty ? "No history yet" : "No matching events",
                    systemImage: searchText.isEmpty
                        ? "clock.arrow.circlepath"
                        : "magnifyingglass"
                )
            } description: {
                Text(
                    allItems.isEmpty
                        ? "Caffeine and nicotine events you log will appear here."
                        : "Try another search, date range, substance, or source."
                )
            } actions: {
                if allItems.isEmpty {
                    Button("Quick Add") {
                        quickAddCoordinator.present()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private func dayHeader(
        date: Date,
        items: [ExposureItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dayTitle(for: date))
                .font(.headline)
                .foregroundStyle(.primary)

            Text(daySummary(for: items))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private func summaryCard(
        title: String,
        value: String,
        symbol: String,
        tint: Color
    ) -> some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(value)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var allItems: [ExposureItem] {
        ExposureItem.combined(
            caffeineEntries: caffeineEntries,
            nicotineEntries: nicotineEntries
        )
    }

    private var filteredItems: [ExposureItem] {
        searchEngine.results(
            in: allItems,
            query: searchText,
            kind: selectedKind
        )
        .filter(matchesSource)
        .filter(matchesDateRange)
    }

    private var selectedKind: ExposureKind? {
        switch substanceFilter {
        case .all: nil
        case .caffeine: .caffeine
        case .nicotine: .nicotine
        }
    }

    private var groupedItems: [(date: Date, items: [ExposureItem])] {
        Dictionary(grouping: filteredItems) {
            calendar.startOfDay(for: $0.date)
        }
        .map { date, items in
            (date: date, items: items.sorted { $0.date > $1.date })
        }
        .sorted { $0.date > $1.date }
    }

    private var totalCaffeineMG: Double {
        filteredItems.reduce(0) { result, item in
            guard case .caffeine(let entry) = item else { return result }
            return result + max(entry.caffeineMG, 0)
        }
    }

    private var totalNicotine: NicotineAmountSummary {
        filteredItems.reduce(into: NicotineAmountSummary()) { summary, item in
            guard case .nicotine(let entry) = item else { return }
            summary.add(quantity: entry.quantity, unit: entry.unit)
        }
    }

    private func matchesSource(_ item: ExposureItem) -> Bool {
        switch sourceFilter {
        case .all: true
        case .local: !item.isHealthKit
        case .health: item.isHealthKit
        }
    }

    private func matchesDateRange(_ item: ExposureItem) -> Bool {
        let days: Int?
        switch dateRange {
        case .week: days = 7
        case .month: days = 30
        case .all: days = nil
        }

        guard let days,
              let cutoff = calendar.date(byAdding: .day, value: -days, to: .now) else {
            return true
        }
        return item.date >= cutoff
    }

    private func dayTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
    }

    private func daySummary(for items: [ExposureItem]) -> String {
        let caffeine = items.reduce(0.0) { result, item in
            guard case .caffeine(let entry) = item else { return result }
            return result + max(entry.caffeineMG, 0)
        }
        let nicotine = items.reduce(into: NicotineAmountSummary()) { summary, item in
            guard case .nicotine(let entry) = item else { return }
            summary.add(quantity: entry.quantity, unit: entry.unit)
        }

        var components: [String] = []
        if caffeine > 0 {
            components.append("\(Int(caffeine.rounded())) mg caffeine")
        }
        if !nicotine.isEmpty {
            components.append(nicotine.displayText)
        }
        return components.joined(separator: " • ")
    }

    private func delete(_ item: ExposureItem) {
        guard item.canModify else { return }

        switch item {
        case .caffeine(let entry):
            modelContext.delete(entry)
        case .nicotine(let entry):
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .environment(QuickAddCoordinator())
    .modelContainer(
        for: [CaffeineEntry.self, Drink.self, NicotineEntry.self],
        inMemory: true
    )
}
