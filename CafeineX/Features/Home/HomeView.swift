import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore
    @Environment(QuickAddCoordinator.self) private var quickAddCoordinator

    @Query private var entries: [CaffeineEntry]
    @Query private var nicotineEntries: [NicotineEntry]

    @Bindable var viewModel: HomeViewModel

    init(
        viewModel: HomeViewModel,
        referenceDate: Date = .now
    ) {
        self.viewModel = viewModel
        let historyStart = CaffeineHistoryPolicy.synchronizationStartDate(
            relativeTo: referenceDate
        )
        _entries = Query(
            filter: #Predicate<CaffeineEntry> { $0.consumedAt >= historyStart },
            sort: \.consumedAt,
            order: .reverse
        )
        _nicotineEntries = Query(
            filter: #Predicate<NicotineEntry> { $0.usedAt >= historyStart },
            sort: \.usedAt,
            order: .reverse
        )
    }

    var body: some View {
        ZStack {
            CXBackgroundView()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header

                    HealthConnectionCard(
                        state: viewModel.healthAccessState,
                        isSyncing: viewModel.isSyncingHealth
                    ) {
                        Task {
                            if viewModel.healthAccessState == .notRequested {
                                await viewModel.requestHealthAccess(context: modelContext)
                            } else {
                                await viewModel.synchronizeHealthKit(context: modelContext)
                            }
                        }
                    }

                    if let message = viewModel.healthMessage {
                        Label(message, systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                            .accessibilityIdentifier("health-status-message")
                    }

                    if let status = viewModel.status {
                        ExposureHeroView(status: status)
                    }

                    if let context = viewModel.dailyExposureContext {
                        DailyExposureCard(context: context)
                    }

                    HomeQuickAddView(
                        addCaffeine: addPreset,
                        openQuickAdd: quickAddCoordinator.present
                    )

                    HomeTimelineView(
                        items: Array(allItems.prefix(CaffeineHistoryPolicy.dashboardEntryLimit)),
                        openQuickAdd: { quickAddCoordinator.present() }
                    )
                }
                .frame(maxWidth: 900)
                .padding(.horizontal, CXTheme.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("CafeineX")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                QuickAddToolbarButton()
            }
        }
        .task {
            updateGuidancePreferences()
            viewModel.load(entries: entries, nicotineEntries: nicotineEntries)
            viewModel.refreshHealthAccessState()

            if viewModel.healthAccessState != .notRequested {
                await viewModel.synchronizeHealthKit(context: modelContext)
            }
        }
        .onChange(of: timelineSignature) {
            viewModel.load(entries: entries, nicotineEntries: nicotineEntries)
        }
        .onChange(of: sleepScheduleStore.schedule) { _, schedule in
            viewModel.updatePreferences(
                sleepSchedule: schedule,
                sensitivity: sensitivityStore.profile
            )
        }
        .onChange(of: sensitivityStore.profile) { _, sensitivity in
            viewModel.updatePreferences(
                sleepSchedule: sleepScheduleStore.schedule,
                sensitivity: sensitivity
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your exposure today")
                .font(.largeTitle.bold())

            Text("Understand timing, active estimates, and sleep guidance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var allItems: [ExposureItem] {
        ExposureItem.combined(
            caffeineEntries: entries,
            nicotineEntries: nicotineEntries
        )
    }

    private var timelineSignature: [String] {
        allItems.map {
            "\($0.id)|\($0.title)|\($0.amountText)|\($0.date.timeIntervalSinceReferenceDate)"
        }
    }

    private func addPreset(name: String, milligrams: Double) {
        _ = viewModel.addDrink(
            name: name,
            caffeineMG: milligrams,
            context: modelContext
        )
    }

    private func updateGuidancePreferences() {
        viewModel.updatePreferences(
            sleepSchedule: sleepScheduleStore.schedule,
            sensitivity: sensitivityStore.profile
        )
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
    .environment(SleepScheduleStore())
    .environment(CaffeineSensitivityStore())
    .environment(QuickAddCoordinator())
    .modelContainer(
        for: [CaffeineEntry.self, Drink.self, NicotineEntry.self],
        inMemory: true
    )
}
