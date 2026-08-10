import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore
    @Environment(QuickAddCoordinator.self) private var quickAddCoordinator
    @Environment(PersistenceIssueCenter.self) private var persistenceIssues

    @Query private var entries: [CaffeineEntry]
    @Query private var nicotineEntries: [NicotineEntry]
    @Query(sort: \Drink.name) private var drinks: [Drink]
    @Query private var drinkDetails: [DrinkDetails]
    @Query private var profiles: [UserProfile]
    @Query private var checkIns: [AwarenessCheckIn]
    @Query private var cigaretteProfiles: [CigaretteProfile]
    @Query private var cigaretteDetails: [CigaretteEventDetails]
    @Query private var cigarettePreferences: [CigarettePreferences]

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
                VStack(alignment: .leading, spacing: CXTheme.sectionSpacing) {
                    header

                    if allItems.isEmpty {
                        HomeEmptyStateCard(
                            healthState: viewModel.healthAccessState,
                            startCaffeine: { quickAddCoordinator.present(.caffeine) },
                            startNicotine: { quickAddCoordinator.present(.nicotine) },
                            connectHealth: {
                                Task {
                                    if viewModel.healthAccessState == .notRequested {
                                        await viewModel.requestHealthAccess(context: modelContext)
                                    } else {
                                        await viewModel.synchronizeHealthKit(context: modelContext)
                                    }
                                }
                            }
                        )
                    }

                    if let status = viewModel.status {
                        ExposureHeroView(status: status)
                    }

                    if let context = viewModel.dailyExposureContext {
                        DailyExposureCard(context: context)
                    }

                    HomeQuickAddView(
                        favoriteDrinks: favoriteDrinks,
                        addDrink: addFavorite,
                        openQuickAdd: quickAddCoordinator.present,
                        nicotineProduct: quickNicotineProduct,
                        nicotineQuantity: quickNicotineQuantity,
                        logNicotine: logQuickNicotine
                    )

                    RecentActionsCard()

                    HealthInsightsCard(
                        state: viewModel.sleepDataState,
                        summary: viewModel.healthInsightsSummary,
                        message: viewModel.sleepDataMessage,
                        isLoading: viewModel.isLoadingSleep,
                        connect: {
                            Task {
                                await viewModel.requestSleepAccess()
                            }
                        },
                        refresh: {
                            Task {
                                await viewModel.refreshSleepSnapshot()
                            }
                        }
                    )

                    if !allItems.isEmpty {
                        HomeTimelineView(
                            items: Array(allItems.prefix(CaffeineHistoryPolicy.dashboardEntryLimit)),
                            openQuickAdd: { quickAddCoordinator.present() },
                            repeatItem: repeatItem
                        )
                    }

                    CigaretteIntelligenceCard(
                        summary: cigaretteSummary,
                        goal: cigarettePreference?.goal ?? .awareness,
                        addCigarette: addOneCigarette
                    )

                    HomeStreakCard(
                        summary: streakSummary,
                        reviewToday: reviewToday
                    )

                    HealthConnectionCard(
                        state: viewModel.healthAccessState,
                        isSyncing: viewModel.isSyncingHealth,
                        lastSyncDate: viewModel.lastHealthSyncDate,
                        message: viewModel.healthMessage,
                        sleepState: viewModel.sleepDataState
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
                .frame(maxWidth: CXTheme.screenMaxWidth)
                .padding(.horizontal, CXTheme.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, CXTheme.bottomContentInset)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
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
                        try? await Task.sleep(for: .seconds(10))
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
            persistenceIssues.attempt("Preparing local libraries") {
                try DrinkLibrary.bootstrapIfNeeded(drinks: drinks, context: modelContext)
                try CigaretteLibrary.bootstrapIfNeeded(
                    profiles: cigaretteProfiles,
                    preferences: cigarettePreferences,
                    context: modelContext
                )
            }
            ensureProfileExists()
            updateGuidancePreferences()
            viewModel.load(entries: entries, nicotineEntries: nicotineEntries)
            viewModel.refreshHealthAccessState()
            await viewModel.refreshSleepContext()

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
                .foregroundStyle(.primary)
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

    private var cigarettePreference: CigarettePreferences? {
        cigarettePreferences.first
    }

    private var favoriteCigarette: CigaretteProfile? {
        cigaretteProfiles
            .filter { !$0.isArchived }
            .sorted {
                if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
                return ($0.favoriteOrder ?? .max) < ($1.favoriteOrder ?? .max)
            }
            .first
    }

    private var latestNicotineEntry: NicotineEntry? {
        nicotineEntries.first
    }

    private var quickNicotineProduct: NicotineProduct {
        latestNicotineEntry?.product ?? .cigarette
    }

    private var quickNicotineQuantity: Double {
        latestNicotineEntry?.quantity ?? 1
    }

    @discardableResult
    private func logQuickNicotine() -> Bool {
        guard let entry = latestNicotineEntry else {
            return viewModel.addCigarette(
                quantity: 1,
                profileID: favoriteCigarette?.id,
                profiles: cigaretteProfiles,
                context: modelContext
            )
        }

        switch entry.product {
        case .cigarette:
            let details = cigaretteDetails.first { $0.nicotineEntryID == entry.id }
            return viewModel.addCigarette(
                quantity: entry.quantity,
                profileID: details?.cigaretteProfileID ?? favoriteCigarette?.id,
                cigaretteContext: details?.context,
                profiles: cigaretteProfiles,
                context: modelContext
            )
        default:
            return viewModel.addNicotine(
                product: entry.product,
                quantity: entry.quantity,
                unit: entry.unit,
                context: modelContext
            )
        }
    }

    private var cigaretteSummary: CigaretteIntelligenceSummary {
        let detailsByEntry = Dictionary(uniqueKeysWithValues: cigaretteDetails.map { ($0.nicotineEntryID, $0) })
        let preference = cigarettePreference
        return CigaretteEngine(configuration: .init(
            pairingWindow: TimeInterval((preference?.pairingWindowMinutes ?? 30) * 60),
            sleepProtectionWindow: TimeInterval((preference?.sleepProtectionMinutes ?? 240) * 60),
            sleepSchedule: sleepScheduleStore.schedule
        )).makeSummary(
            cigaretteEvents: nicotineEntries
                .filter { $0.product == .cigarette }
                .map {
                    CigaretteEvent(
                        id: $0.id,
                        usedAt: $0.usedAt,
                        quantity: $0.quantity,
                        context: detailsByEntry[$0.id]?.context
                    )
                },
            caffeineDoses: entries.map(\.dose)
        )
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

    private func addOneCigarette() {
        _ = viewModel.addCigarette(
            profileID: favoriteCigarette?.id,
            profiles: cigaretteProfiles,
            context: modelContext
        )
    }

    private func repeatItem(_ item: ExposureItem) {
        switch item {
        case .caffeine(let entry):
            _ = viewModel.addDrink(
                name: entry.drinkName,
                caffeineMG: entry.caffeineMG,
                drink: drinks.first {
                    $0.name == entry.drinkName
                        && abs($0.caffeineMG - entry.caffeineMG) < 0.01
                },
                context: modelContext,
                actionKind: .loggedAgain
            )
        case .nicotine(let entry):
            _ = viewModel.addNicotine(
                product: entry.product,
                quantity: entry.quantity,
                unit: entry.unit,
                note: entry.note,
                context: modelContext,
                actionKind: .loggedAgain
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
        persistenceIssues.attempt("Saving today's review") {
            try modelContext.save()
        }
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty else { return }
        persistenceIssues.attempt("Preparing the local profile") {
            _ = try UserProfileStore.resolve(in: modelContext)
        }
    }

    private func feedbackBanner(_ feedback: HomeViewModel.Feedback) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CXTheme.healthAccent)

            Text(feedback.message)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button("Undo") {
                Task { @MainActor in
                    _ = await viewModel.undoLastAdd(context: modelContext)
                }
            }
            .font(.subheadline.bold())
            .accessibilityIdentifier("undo-last-add-button")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .glassEffect(.regular.interactive())
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

private struct HomeEmptyStateCard: View {
    let healthState: HomeViewModel.HealthAccessState
    let startCaffeine: () -> Void
    let startNicotine: () -> Void
    let connectHealth: () -> Void

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CXTheme.healthAccent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start with one moment")
                            .font(.headline)
                        Text("Your first entry takes less than 10 seconds.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 10) {
                    Button(action: startCaffeine) {
                        Label("Log caffeine", systemImage: "cup.and.saucer.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CXTheme.caffeineAccent)
                    .accessibilityIdentifier("empty-state-log-caffeine-button")

                    Button(action: startNicotine) {
                        Label("Log nicotine", systemImage: "smoke.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(CXTheme.nicotineAccent)
                    .accessibilityIdentifier("empty-state-log-nicotine-button")
                }

                if healthState != .unavailable {
                    Button(action: connectHealth) {
                        Label(
                            healthState == .notRequested
                                ? "Connect Apple Health"
                                : "Sync Apple Health",
                            systemImage: "heart.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(CXTheme.healthAccent)
                    .accessibilityIdentifier("empty-state-connect-health-button")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-empty-state-card")
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
    .environment(SleepScheduleStore())
    .environment(CaffeineSensitivityStore())
    .environment(QuickAddCoordinator())
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
