import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(QuickAddCoordinator.self) private var quickAddCoordinator
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore
    @Environment(AppearanceStore.self) private var appearanceStore

    @Query private var caffeineEntries: [CaffeineEntry]
    @Query private var nicotineEntries: [NicotineEntry]

    @Bindable var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            CXBackgroundView()

            List {
                profileHeader

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
                    LabeledContent("Data model", value: "SwiftData V2")
                    LabeledContent("Purpose", value: "Exposure guidance")
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
            ToolbarItem(placement: .topBarTrailing) {
                QuickAddToolbarButton()
            }
        }
    }

    private var profileHeader: some View {
        Section {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [CXTheme.caffeineAccent, CXTheme.nicotineAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 82, height: 82)

                    Image(systemName: "waveform.path.ecg")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text("Your CafeineX")
                        .font(.title2.bold())
                    Text("Guidance tuned to your schedule and preferences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityElement(children: .combine)
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
}
