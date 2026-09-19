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
                        HomeEmptyStateCard()
                    }

                    if !entries.isEmpty, let status = viewModel.status {
                        ExposureHeroView(status: status)
                    }

                    HomeQuickAddView(
                        favoriteDrinks: favoriteDrinks,
                        addDrink: addFavorite,
                        openQuickAdd: quickAddCoordinator.present,
                        nicotineProduct: quickNicotineProduct,
                        nicotineQuantity: quickNicotineQuantity,
                        logNicotine: logQuickNicotine
                    )

                    if let context = viewModel.dailyExposureContext,
                       shouldShowDailyExposureContext(context) {
                        DailyExposureCard(context: context)
                    }

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

            updateWidgetSnapshot()
        }
        .onChange(of: exposureSignature) {
            viewModel.load(entries: entries, nicotineEntries: nicotineEntries)

            updateWidgetSnapshot()
        }
        .onChange(of: favoriteDrinkSignature) {
            updateWidgetSnapshot()
        }
        .onChange(of: sleepScheduleStore.schedule) { _, schedule in
            viewModel.updatePreferences(
                sleepSchedule: schedule,
                sensitivity: sensitivityStore.profile
            )

            updateWidgetSnapshot()
        }
        .onChange(of: sensitivityStore.profile) { _, sensitivity in
            viewModel.updatePreferences(
                sleepSchedule: sleepScheduleStore.schedule,
                sensitivity: sensitivity
            )

            updateWidgetSnapshot()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.largeTitle.bold())

            Text("See what matters now, then log in one tap.")
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

    private var exposureSignature: [String] {
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

    private var favoriteDrinkSignature: [String] {
        favoriteDrinks.map {
            "\($0.id)|\($0.name)|\($0.caffeineMG)|\($0.categoryRawValue)"
        }
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

    private func shouldShowDailyExposureContext(_ context: DailyExposureContext) -> Bool {
        !context.nicotineStatus.amountsToday.isEmpty
            || context.hasTemporalOverlap
            || context.guidance == .sleepPriority
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

    // MARK: - Widget Snapshot

    private func updateWidgetSnapshot() {
        CafeineXWidgetPublisher.publish(context: modelContext)
    }
}

private struct HomeEmptyStateCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CXTheme.healthAccent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Start with one moment")
                    .font(.headline)
                Text("Tap a favorite below or use Quick Add for something else.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
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
