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
    @Query private var drinkDetails: [DrinkDetails]
    @Query private var cigaretteProfiles: [CigaretteProfile]
    @Query private var cigarettePreferences: [CigarettePreferences]

    @Bindable var viewModel: HomeViewModel
    @State private var editingProfile: UserProfile?

    private let streakEngine = StreakEngine()

    var body: some View {
        ZStack {
            CXBackgroundView()

            List {
                profileHeader
                goalSection
                weeklySection
                responsibleStreaksSection
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
                        PrivacyAndDataView(viewModel: viewModel)
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
                    LabeledContent("Data model", value: "SwiftData V5")
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
            CigaretteLibrary.bootstrapIfNeeded(
                profiles: cigaretteProfiles,
                preferences: cigarettePreferences,
                context: modelContext
            )
        }
    }

    private var profileHeader: some View {
        Section {
            Button {
                if let profile {
                    editingProfile = profile
                }
            } label: {
                HStack(spacing: 16) {
                    ProfileAvatarView(data: profile?.avatarData, size: 82)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(profileName)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Text(profile?.displayName.isEmpty == false
                            ? "Your personal CafeineX profile"
                            : "Add your name and photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Label("Edit Profile", systemImage: "pencil")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CXTheme.healthAccent)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityHint("Edit name, photo, and goal")
        }
    }

    private var goalSection: some View {
        Section("Your Focus") {
            Button {
                if let profile {
                    editingProfile = profile
                }
            } label: {
                settingsRow(
                    title: selectedGoal.title,
                    subtitle: selectedGoal.description,
                    symbol: selectedGoal.symbol,
                    tint: CXTheme.caffeineAccent
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Change your personal goal")
        }
    }

    private var weeklySection: some View {
        Section {
            WeeklySummaryCard(
                summary: weeklySummary,
                goal: selectedGoal
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var responsibleStreaksSection: some View {
        Section {
            ResponsibleStreaksCard(summary: streakSummary)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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

            NavigationLink {
                MyCigarettesView()
            } label: {
                settingsRow(
                    title: "My Cigarettes",
                    subtitle: "\(activeCigarettes.count) active • \(favoriteCigarettes.count) favorites",
                    symbol: "smoke.fill",
                    tint: CXTheme.nicotineAccent
                )
            }
        }
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
            return "Set Up Your Profile"
        }
        return name
    }

    private var selectedGoal: ProfileGoal {
        profile?.goal ?? .protectSleep
    }

    private var activeDrinks: [Drink] {
        drinks.filter {
            !(DrinkLibrary.existingDetails(
                for: $0,
                in: drinkDetails
            )?.isArchived ?? false)
        }
    }

    private var favoriteDrinks: [Drink] {
        activeDrinks.filter(\.isFavorite)
    }

    private var activeCigarettes: [CigaretteProfile] {
        cigaretteProfiles.filter { !$0.isArchived }
    }

    private var favoriteCigarettes: [CigaretteProfile] {
        activeCigarettes.filter(\.isFavorite)
    }

    private var streakSummary: StreakSummary {
        streakEngine.makeSummary(
            checkInDates: checkIns.map(\.day),
            caffeineDates: caffeineEntries.map(\.consumedAt),
            sleepSchedule: sleepScheduleStore.schedule
        )
    }

    private var weeklySummary: WeeklySummary {
        WeeklySummaryEngine().makeSummary(
            caffeineDoses: caffeineEntries.map(\.dose),
            nicotineEvents: nicotineEntries.map(\.event),
            checkInDates: checkIns.map(\.day),
            sleepSchedule: sleepScheduleStore.schedule
        )
    }

    private var bedtimeText: String {
        sleepScheduleStore
            .bedtimeDate()
            .formatted(date: .omitted, time: .shortened)
    }

    private var healthSubtitle: String {
        let caffeine: String = switch viewModel.healthAccessState {
        case .unavailable: "Unavailable"
        case .notRequested: "Caffeine not connected"
        case .writeEnabled: "Caffeine connected"
        case .writeDisabled: "Caffeine write off"
        }
        let sleep: String = switch viewModel.sleepDataState {
        case .unavailable: "sleep unavailable"
        case .notRequested: "sleep optional"
        case .loading: "reading sleep"
        case .noData: "no readable sleep"
        case .available: "sleep snapshot ready"
        case .failed: "sleep unavailable"
        }
        return "\(caffeine) • \(sleep)"
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty else { return }
        _ = try? UserProfileStore.resolve(in: modelContext)
    }
}
