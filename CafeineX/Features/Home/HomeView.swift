import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore
    @Environment(QuickAddCoordinator.self) private var quickAddCoordinator

    @Query private var entries: [CaffeineEntry]
    @Query private var nicotineEntries: [NicotineEntry]
    @Query(sort: \Drink.name) private var drinks: [Drink]
    @Query private var drinkDetails: [DrinkDetails]
    @Query private var profiles: [UserProfile]
    @Query private var checkIns: [AwarenessCheckIn]

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

                    if let status = viewModel.status {
                        ExposureHeroView(status: status)
                    }

                    if let context = viewModel.dailyExposureContext {
                        DailyExposureCard(context: context)
                    }

                    HomeStreakCard(
                        summary: streakSummary,
                        reviewToday: reviewToday
                    )

                    HomeQuickAddView(
                        favoriteDrinks: favoriteDrinks,
                        addDrink: addFavorite,
                        openQuickAdd: quickAddCoordinator.present
                    )

                    HomeTimelineView(
                        items: Array(allItems.prefix(CaffeineHistoryPolicy.dashboardEntryLimit)),
                        openQuickAdd: { quickAddCoordinator.present() },
                        repeatItem: repeatItem
                    )

                    if viewModel.healthAccessState != .writeEnabled {
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
                    }

                    if let message = viewModel.healthMessage {
                        Label(message, systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                            .accessibilityIdentifier("health-status-message")
                    }
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
        .safeAreaInset(edge: .bottom) {
            if let feedback = viewModel.feedback {
                feedbackBanner(feedback)
                    .padding(.horizontal, CXTheme.horizontalPadding)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: feedback.id) {
                        try? await Task.sleep(for: .seconds(5))
                        guard viewModel.feedback?.id == feedback.id else { return }
                        withAnimation {
                            viewModel.dismissFeedback()
                        }
                    }
            }
        }
        .animation(.snappy, value: viewModel.feedback?.id)
        .sensoryFeedback(.success, trigger: viewModel.feedback?.id)
        .task {
            DrinkLibrary.bootstrapIfNeeded(drinks: drinks, context: modelContext)
            ensureProfileExists()
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
            Text(greeting)
                .font(.largeTitle.bold())

            Text("Make the next choice with your sleep and active exposure in view.")
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

    private var favoriteDrinks: [Drink] {
        drinks
            .filter {
                $0.isFavorite
                    && !(DrinkLibrary.existingDetails(
                        for: $0,
                        in: drinkDetails
                    )?.isArchived ?? false)
            }
            .sorted {
                let lhsDetails = DrinkLibrary.existingDetails(
                    for: $0,
                    in: drinkDetails
                )
                let rhsDetails = DrinkLibrary.existingDetails(
                    for: $1,
                    in: drinkDetails
                )
                if lhsDetails?.favoriteOrder != rhsDetails?.favoriteOrder {
                    return (lhsDetails?.favoriteOrder ?? .max)
                        < (rhsDetails?.favoriteOrder ?? .max)
                }
                return (lhsDetails?.lastUsedAt ?? .distantPast)
                    > (rhsDetails?.lastUsedAt ?? .distantPast)
            }
    }

    private var streakSummary: StreakSummary {
        StreakEngine().makeSummary(
            checkInDates: checkIns.map(\.day),
            caffeineDates: entries.map(\.consumedAt),
            sleepSchedule: sleepScheduleStore.schedule
        )
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let salutation: String
        switch hour {
        case 5..<12: salutation = "Good morning"
        case 12..<18: salutation = "Good afternoon"
        default: salutation = "Good evening"
        }

        guard let name = profiles.first?.displayName, !name.isEmpty else {
            return salutation
        }
        return "\(salutation), \(name)"
    }

    private func addFavorite(_ drink: Drink) {
        _ = viewModel.addDrink(
            name: drink.name,
            caffeineMG: drink.caffeineMG,
            drink: drink,
            context: modelContext
        )
    }

    private func repeatItem(_ item: ExposureItem) {
        switch item {
        case .caffeine(let entry):
            _ = viewModel.addDrink(
                name: entry.drinkName,
                caffeineMG: entry.caffeineMG,
                context: modelContext
            )
        case .nicotine(let entry):
            _ = viewModel.addNicotine(
                product: entry.product,
                quantity: entry.quantity,
                unit: entry.unit,
                note: entry.note,
                context: modelContext
            )
        }
    }

    private func reviewToday() {
        let today = Calendar.current.startOfDay(for: .now)
        guard !checkIns.contains(where: {
            Calendar.current.isDate($0.day, inSameDayAs: today)
        }) else {
            return
        }
        modelContext.insert(AwarenessCheckIn(day: today))
        try? modelContext.save()
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty else { return }
        _ = try? UserProfileStore.resolve(in: modelContext)
    }

    private func feedbackBanner(_ feedback: HomeViewModel.Feedback) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CXTheme.healthAccent)

            Text(feedback.message)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button("Undo") {
                withAnimation {
                    _ = viewModel.undoLastCaffeineAdd(context: modelContext)
                }
            }
            .font(.subheadline.bold())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
        .accessibilityElement(children: .contain)
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
