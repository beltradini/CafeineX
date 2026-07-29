import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore
    @Environment(AppearanceStore.self) private var appearanceStore

    @Query private var profiles: [UserProfile]
    @Query private var caffeineEntries: [CaffeineEntry]
    @Query private var nicotineEntries: [NicotineEntry]
    @Query private var checkIns: [AwarenessCheckIn]
    @Query private var drinks: [Drink]
    @Query private var drinkMetadata: [DrinkMetadata]

    @Bindable var viewModel: HomeViewModel
    @State private var editingProfile: UserProfile?

    private let streakEngine = StreakEngine()

    var body: some View {
        ZStack {
            CXBackgroundView()

            List {
                profileHeader
                streakSection
                librarySection

                Section("Personalization") {
                    NavigationLink {
                        GuidanceSettingsView(
                            sleepScheduleStore: sleepScheduleStore,
                            sensitivityStore: sensitivityStore
                        )
                    } label: {
                        settingsRow(
                            title: "Personal Guidance",
                            subtitle: "Bedtime \(bedtimeText) • \(sensitivityStore.profile.title) response",
                            symbol: "moon.zzz",
                            tint: CXTheme.caffeineAccent
                        )
                    }

                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        settingsRow(
                            title: "Appearance",
                            subtitle: appearanceStore.selection.title,
                            symbol: appearanceStore.selection.symbol,
                            tint: CXTheme.nicotineAccent
                        )
                    }
                }

                Section("Connections") {
                    NavigationLink {
                        HealthConnectionSettingsView(viewModel: viewModel)
                    } label: {
                        settingsRow(
                            title: "Apple Health",
                            subtitle: healthSubtitle,
                            symbol: "heart.fill",
                            tint: CXTheme.healthAccent
                        )
                    }

                    settingsRow(
                        title: "Apple ID Sync",
                        subtitle: "Local profile ready • Not connected",
                        symbol: "person.crop.circle.badge.checkmark",
                        tint: .primary
                    )
                    .accessibilityHint("Sign in with Apple will be added in a future release")
                }

                Section("Data") {
                    NavigationLink {
                        PrivacyAndDataView()
                    } label: {
                        settingsRow(
                            title: "Privacy & Data",
                            subtitle: "\(caffeineEntries.count + nicotineEntries.count) local events",
                            symbol: "hand.raised.fill",
                            tint: CXTheme.healthAccent
                        )
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "CafeineX")
                    LabeledContent("Data model", value: "SwiftData V3")
                    LabeledContent("Purpose", value: "Mindful exposure guidance")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, 32, for: .scrollContent)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if let profile {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        editingProfile = profile
                    }
                }
            }
        }
        .sheet(item: $editingProfile) { profile in
            EditProfileView(profile: profile)
        }
        .task {
            ensureProfileExists()
            DrinkLibrary.bootstrapIfNeeded(drinks: drinks, context: modelContext)
        }
    }

    private var profileHeader: some View {
        Section {
            Button {
                if let profile {
                    editingProfile = profile
                }
            } label: {
                VStack(spacing: 14) {
                    ProfileAvatarView(data: profile?.avatarData)

                    VStack(spacing: 4) {
                        Text(profileName)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Label(
                            profile?.goal.title ?? ProfileGoal.protectSleep.title,
                            systemImage: profile?.goal.symbol ?? ProfileGoal.protectSleep.symbol
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityHint("Edit name, photo, and goal")
        }
    }

    private var streakSection: some View {
        Section("Mindful Streaks") {
            HStack(spacing: 12) {
                streakMetric(
                    value: streakSummary.awarenessDays,
                    title: "Awareness",
                    symbol: "brain.head.profile",
                    tint: CXTheme.healthAccent
                )

                streakMetric(
                    value: streakSummary.sleepProtectionDays,
                    title: "Sleep protection",
                    symbol: "moon.stars.fill",
                    tint: CXTheme.nicotineAccent
                )
            }

            Text("Awareness counts reviewed days. Sleep protection counts completed, reviewed days without caffeine after your cutoff. Missing data never counts as success.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var librarySection: some View {
        Section("Your Library") {
            NavigationLink {
                MyDrinksView()
            } label: {
                settingsRow(
                    title: "My Drinks",
                    subtitle: "\(activeDrinks.count) active • \(favoriteDrinks.count) favorites",
                    symbol: "mug.fill",
                    tint: CXTheme.caffeineAccent
                )
            }
        }
    }

    private func streakMetric(
        value: Int,
        title: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text("\(value)")
                .font(.title.bold())
                .contentTransition(.numericText())
            Text(value == 1 ? "\(title) day" : "\(title) days")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func settingsRow(
        title: String,
        subtitle: String,
        symbol: String,
        tint: Color
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(tint)
        }
    }

    private var profile: UserProfile? { profiles.first }

    private var profileName: String {
        guard let name = profile?.displayName, !name.isEmpty else {
            return "Your CafeineX"
        }
        return name
    }

    private var activeDrinks: [Drink] {
        drinks.filter {
            !(DrinkLibrary.existingMetadata(
                for: $0,
                in: drinkMetadata
            )?.isArchived ?? false)
        }
    }

    private var favoriteDrinks: [Drink] {
        activeDrinks.filter(\.isFavorite)
    }

    private var streakSummary: StreakSummary {
        streakEngine.makeSummary(
            checkInDates: checkIns.map(\.day),
            caffeineDates: caffeineEntries.map(\.consumedAt),
            sleepSchedule: sleepScheduleStore.schedule
        )
    }

    private var bedtimeText: String {
        sleepScheduleStore
            .bedtimeDate()
            .formatted(date: .omitted, time: .shortened)
    }

    private var healthSubtitle: String {
        switch viewModel.healthAccessState {
        case .unavailable: "Unavailable"
        case .notRequested: "Not connected"
        case .writeEnabled: "Connected"
        case .writeDisabled: "Write access off"
        }
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty,
              (try? modelContext.fetchCount(FetchDescriptor<UserProfile>())) == 0 else {
            return
        }
        modelContext.insert(UserProfile())
        try? modelContext.save()
    }
}
