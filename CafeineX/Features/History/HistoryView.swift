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
            case .all: "All"
            case .local: "Local"
            case .health: "Health"
            }
        }
    }

    @Query(sort: \CaffeineEntry.consumedAt, order: .reverse)
    private var caffeineEntries: [CaffeineEntry]

    @Query(sort: \NicotineEntry.usedAt, order: .reverse)
    private var nicotineEntries: [NicotineEntry]

    @State private var searchText = ""
    @State private var substanceFilter = SubstanceFilter.all
    @State private var sourceFilter = SourceFilter.all

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    var body: some View {
        ZStack {
            CXBackgroundView()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    summarySection
                    filterSection

                    if filteredItems.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedItems, id: \.date) { section in
                            daySection(date: section.date, items: section.items)
                        }
                    }
                }
                .padding(.horizontal, CXTheme.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search exposure events"
        )
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
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
            }

            summaryCard(
                title: "Nicotine — quantities stay separate",
                value: totalNicotine.displayText,
                symbol: "waveform.path.ecg",
                tint: CXTheme.nicotineAccent
            )
        }
    }

    private func summaryCard(
        title: String,
        value: String,
        symbol: String,
        tint: Color
    ) -> some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundStyle(tint)

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var filterSection: some View {
        VStack(spacing: 10) {
            Picker("Substance", selection: $substanceFilter) {
                ForEach(SubstanceFilter.allCases) { filter in
                    Text(filter.title)
                        .tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("History substance")

            Picker("Source", selection: $sourceFilter) {
                ForEach(SourceFilter.allCases) { filter in
                    Text(filter.title)
                        .tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("History source")
        }
    }

    private func daySection(
        date: Date,
        items: [HistoryItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayTitle(for: date))
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 10) {
                    let caffeine = dayCaffeineMG(in: items)
                    if caffeine > 0 {
                        Label(
                            "\(Int(caffeine.rounded())) mg caffeine",
                            systemImage: "cup.and.saucer.fill"
                        )
                        .foregroundStyle(CXTheme.caffeineAccent)
                    }

                    let nicotine = dayNicotineSummary(in: items)
                    if !nicotine.isEmpty {
                        Label(
                            nicotine.displayText,
                            systemImage: "waveform.path.ecg"
                        )
                        .foregroundStyle(CXTheme.nicotineAccent)
                    }
                }
                .font(.caption.weight(.semibold))
            }

            ForEach(items) { item in
                switch item {
                case .caffeine(let entry):
                    caffeineRow(entry)
                case .nicotine(let entry):
                    nicotineRow(entry)
                }
            }
        }
    }

    private func caffeineRow(_ entry: CaffeineEntry) -> some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            HStack(spacing: 14) {
                historySymbol(
                    symbol: symbol(for: entry.drinkName),
                    tint: sourceTint(for: entry)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.drinkName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text(entry.consumedAt, style: .time)
                        Text("•")
                        Text(sourceTitle(for: entry.source))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(entry.caffeineMG.rounded())) mg")
                    .font(.headline)
                    .foregroundStyle(CXTheme.caffeineAccent)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func nicotineRow(_ entry: NicotineEntry) -> some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            HStack(spacing: 14) {
                historySymbol(
                    symbol: entry.product.symbol,
                    tint: CXTheme.nicotineAccent
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.product.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text(entry.usedAt, style: .time)
                        Text("•")
                        Text(nicotineSourceTitle(entry.source))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let note = entry.note {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Text(entry.unit.formatted(quantity: entry.quantity))
                    .font(.headline)
                    .foregroundStyle(CXTheme.nicotineAccent)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func historySymbol(symbol: String, tint: Color) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 44, height: 44)

            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
        }
    }

    private var emptyState: some View {
        CXGlassCard {
            ContentUnavailableView(
                emptyTitle,
                systemImage: searchText.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass",
                description: Text(emptyDescription)
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var allItems: [HistoryItem] {
        let caffeine = caffeineEntries.map(HistoryItem.caffeine)
        let nicotine = nicotineEntries.map(HistoryItem.nicotine)
        return (caffeine + nicotine).sorted { $0.date > $1.date }
    }

    private var filteredItems: [HistoryItem] {
        allItems.filter { item in
            let matchesSearch = searchText.isEmpty
                || item.searchableText.localizedCaseInsensitiveContains(searchText)

            let matchesSubstance: Bool
            switch (substanceFilter, item) {
            case (.all, _), (.caffeine, .caffeine), (.nicotine, .nicotine):
                matchesSubstance = true
            default:
                matchesSubstance = false
            }

            let matchesSource: Bool
            switch sourceFilter {
            case .all:
                matchesSource = true
            case .local:
                matchesSource = !item.isHealthKit
            case .health:
                matchesSource = item.isHealthKit
            }

            return matchesSearch && matchesSubstance && matchesSource
        }
    }

    private var groupedItems: [(date: Date, items: [HistoryItem])] {
        Dictionary(grouping: filteredItems) { item in
            calendar.startOfDay(for: item.date)
        }
        .map { (date: $0.key, items: $0.value) }
        .sorted { $0.date > $1.date }
    }

    private var totalCaffeineMG: Double {
        filteredItems.reduce(0) { result, item in
            guard case .caffeine(let entry) = item else { return result }
            return result + max(entry.caffeineMG, 0)
        }
    }

    private var totalNicotine: NicotineAmountSummary {
        dayNicotineSummary(in: filteredItems)
    }

    private func dayCaffeineMG(in items: [HistoryItem]) -> Double {
        items.reduce(0) { result, item in
            guard case .caffeine(let entry) = item else { return result }
            return result + max(entry.caffeineMG, 0)
        }
    }

    private func dayNicotineSummary(in items: [HistoryItem]) -> NicotineAmountSummary {
        items.reduce(into: NicotineAmountSummary()) { summary, item in
            guard case .nicotine(let entry) = item else { return }
            summary.add(quantity: entry.quantity, unit: entry.unit)
        }
    }

    private var emptyTitle: String {
        allItems.isEmpty ? "No history yet" : "No matching events"
    }

    private var emptyDescription: String {
        if allItems.isEmpty {
            return "Caffeine and nicotine events you log will appear here."
        }

        return "Try another search, substance, or source filter."
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

    private func sourceTitle(for source: CaffeineSource) -> String {
        switch source {
        case .manual: "Manual"
        case .appleWatch: "Apple Watch"
        case .siri: "Siri"
        case .widget: "Widget"
        case .healthKit: "Apple Health"
        }
    }

    private func nicotineSourceTitle(_ source: NicotineSource) -> String {
        switch source {
        case .manual: "Manual"
        case .appleWatch: "Apple Watch"
        case .siri: "Siri"
        case .widget: "Widget"
        }
    }

    private func sourceTint(for entry: CaffeineEntry) -> Color {
        entry.source == .healthKit ? CXTheme.healthAccent : CXTheme.caffeineAccent
    }

    private func symbol(for drinkName: String) -> String {
        let name = drinkName.lowercased()

        if name.contains("espresso") {
            return "cup.and.saucer.fill"
        }
        if name.contains("americano") {
            return "mug.fill"
        }
        if name.contains("latte") {
            return "takeoutbag.and.cup.and.straw.fill"
        }
        if name.contains("cold") {
            return "snowflake"
        }
        return "cup.and.saucer"
    }
}

private enum HistoryItem: Identifiable {
    case caffeine(CaffeineEntry)
    case nicotine(NicotineEntry)

    var id: String {
        switch self {
        case .caffeine(let entry):
            "caffeine-\(entry.id.uuidString)"
        case .nicotine(let entry):
            "nicotine-\(entry.id.uuidString)"
        }
    }

    var date: Date {
        switch self {
        case .caffeine(let entry):
            entry.consumedAt
        case .nicotine(let entry):
            entry.usedAt
        }
    }

    var searchableText: String {
        switch self {
        case .caffeine(let entry):
            entry.drinkName
        case .nicotine(let entry):
            ([entry.product.title] + [entry.note].compactMap { $0 })
                .joined(separator: " ")
        }
    }

    var isHealthKit: Bool {
        guard case .caffeine(let entry) = self else { return false }
        return entry.source == .healthKit
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(
        for: [CaffeineEntry.self, Drink.self, NicotineEntry.self],
        inMemory: true
    )
}
