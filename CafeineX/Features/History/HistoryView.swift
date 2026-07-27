import SwiftData
import SwiftUI

struct HistoryView: View {
    private enum SourceFilter: String, CaseIterable, Identifiable {
        case all
        case local
        case health

        var id: Self { self }

        var title: String {
            switch self {
            case .all:
                return "All"
            case .local:
                return "Local"
            case .health:
                return "Health"
            }
        }
    }

    @Query(sort: \CaffeineEntry.consumedAt, order: .reverse)
    private var entries: [CaffeineEntry]

    @State private var searchText = ""
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

                    if filteredEntries.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedEntries, id: \.date) { section in
                            daySection(date: section.date, entries: section.entries)
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
            prompt: "Search drinks"
        )
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Entries",
                value: filteredEntries.count.formatted(),
                symbol: "list.bullet",
                tint: CXTheme.healthAccent
            )

            summaryCard(
                title: "Logged caffeine",
                value: "\(Int(totalCaffeineMG.rounded())) mg",
                symbol: "cup.and.saucer.fill",
                tint: CXTheme.caffeineAccent
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var filterSection: some View {
        Picker("Source", selection: $sourceFilter) {
            ForEach(SourceFilter.allCases) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("History source")
    }

    private func daySection(
        date: Date,
        entries: [CaffeineEntry]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayTitle(for: date))
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(Int(entries.reduce(0) { $0 + max($1.caffeineMG, 0) }.rounded())) mg")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(entries) { entry in
                historyRow(entry)
            }
        }
    }

    private func historyRow(_ entry: CaffeineEntry) -> some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(sourceTint(for: entry).opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: symbol(for: entry.drinkName))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(sourceTint(for: entry))
                }

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

    private var filteredEntries: [CaffeineEntry] {
        entries.filter { entry in
            let matchesSearch = searchText.isEmpty
                || entry.drinkName.localizedCaseInsensitiveContains(searchText)

            let matchesSource: Bool
            switch sourceFilter {
            case .all:
                matchesSource = true
            case .local:
                matchesSource = entry.source != .healthKit
            case .health:
                matchesSource = entry.source == .healthKit
            }

            return matchesSearch && matchesSource
        }
    }

    private var groupedEntries: [(date: Date, entries: [CaffeineEntry])] {
        Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.consumedAt)
        }
        .map { (date: $0.key, entries: $0.value) }
        .sorted { $0.date > $1.date }
    }

    private var totalCaffeineMG: Double {
        filteredEntries.reduce(0) { $0 + max($1.caffeineMG, 0) }
    }

    private var emptyTitle: String {
        entries.isEmpty ? "No history yet" : "No matching entries"
    }

    private var emptyDescription: String {
        if entries.isEmpty {
            return "Caffeine you log will appear here."
        }

        return "Try another search or source filter."
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
        case .manual:
            return "Manual"
        case .appleWatch:
            return "Apple Watch"
        case .siri:
            return "Siri"
        case .widget:
            return "Widget"
        case .healthKit:
            return "Apple Health"
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

#Preview {
    NavigationStack {
        HistoryView()
    }
    .preferredColorScheme(.dark)
    .modelContainer(for: [CaffeineEntry.self, Drink.self], inMemory: true)
}

