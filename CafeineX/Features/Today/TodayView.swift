//
//  TodayView.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore

    @Query private var entries: [CaffeineEntry]

    @State private var viewModel = TodayViewModel()
    @State private var isShowingCustomEntry = false
    @State private var isShowingSleepSettings = false

    init(referenceDate: Date = .now) {
        let historyStart = CaffeineHistoryPolicy.synchronizationStartDate(
            relativeTo: referenceDate
        )
        _entries = Query(
            filter: #Predicate<CaffeineEntry> { entry in
                entry.consumedAt >= historyStart
            },
            sort: \CaffeineEntry.consumedAt,
            order: .reverse
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CXBackgroundView()

                ScrollView {
                    LazyVStack(spacing: 20) {
                        headerSection
                        healthStatusCard

                        if let healthMessage = viewModel.healthMessage {
                            healthMessageCard(healthMessage)
                        }

                        if let status = viewModel.status {
                            caffeineSummary(status)
                            quickAddSection
                            timelineSection
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, CXTheme.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("CafeineX")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingSleepSettings = true
                    } label: {
                        Label("Sleep guidance", systemImage: "moon.zzz")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingCustomEntry = true
                    } label: {
                        Label("Add caffeine", systemImage: "plus")
                    }
                }
            }
            .task {
                updateGuidancePreferences()
                viewModel.load(entries: entries)
                viewModel.refreshHealthAccessState()

                if viewModel.healthAccessState != .notRequested {
                    await viewModel.synchronizeHealthKit(context: modelContext)
                }
            }
            .onChange(of: entries.count) {
                viewModel.load(entries: entries)
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
            .sheet(isPresented: $isShowingCustomEntry) {
                CustomCaffeineEntrySheet { name, milligrams, consumedAt in
                    viewModel.addDrink(
                        name: name,
                        caffeineMG: milligrams,
                        consumedAt: consumedAt,
                        context: modelContext
                    )
                }
            }
            .sheet(isPresented: $isShowingSleepSettings) {
                GuidanceSettingsView(
                    sleepScheduleStore: sleepScheduleStore,
                    sensitivityStore: sensitivityStore
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private func updateGuidancePreferences() {
        viewModel.updatePreferences(
            sleepSchedule: sleepScheduleStore.schedule,
            sensitivity: sensitivityStore.profile
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caffeine Intelligence")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Understand your energy, focus, and sleep impact.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    private var healthStatusCard: some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: healthSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(healthTint)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(healthStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()

                Button {
                    Task {
                        if viewModel.healthAccessState == .notRequested {
                            await viewModel.requestHealthAccess(context: modelContext)
                        } else {
                            await viewModel.synchronizeHealthKit(context: modelContext)
                        }
                    }
                } label: {
                    if viewModel.isSyncingHealth {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(viewModel.healthAccessState == .notRequested ? "Connect" : "Sync")
                            .font(.caption.weight(.semibold))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.healthAccessState == .unavailable || viewModel.isSyncingHealth)
            }
        }
    }

    private func healthMessageCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(CXTheme.caffeineAccent)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func caffeineSummary(_ status: CaffeineStatus) -> some View {
        CXGlassCard {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("\(Int(status.consumedTodayMG)) mg")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Consumed Today")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: status.dailyProgress)
                    .tint(CXTheme.caffeineAccent)

                HStack(spacing: 12) {
                    CXMetricCard(
                        title: "Active estimate",
                        value: "≈ \(Int(status.activeCaffeineMG.rounded())) mg",
                        symbol: "bolt.heart",
                        tint: CXTheme.caffeineAccent
                    )

                    CXMetricCard(
                        title: "Guidance",
                        value: status.riskLevel.title,
                        symbol: "waveform.path.ecg",
                        tint: riskTint(for: status.riskLevel)
                    )
                }

                VStack(spacing: 6) {
                    Text("Likely active range: \(Int(status.activeCaffeineLowMG.rounded()))–\(Int(status.activeCaffeineHighMG.rounded())) mg")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Estimated at \(status.targetBedtime, style: .time): \(Int(status.caffeineAtBedtimeLowMG.rounded()))–\(Int(status.caffeineAtBedtimeHighMG.rounded())) mg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                recommendationCard(for: status)
            }
        }
    }

    private func recommendationCard(for status: CaffeineStatus) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recommendationSymbol(for: status.riskLevel))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(riskTint(for: status.riskLevel))

            VStack(alignment: .leading, spacing: 6) {
                Text("Personal Guidance")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(recommendationText(for: status))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CXTheme.smallCornerRadius, style: .continuous))
        .modifier(CXLiquidGlassModifier(cornerRadius: CXTheme.smallCornerRadius))
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Add")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                quickAddButton(name: "Espresso", mg: 64)
                quickAddButton(name: "Americano", mg: 150)
            }

            HStack(spacing: 12) {
                quickAddButton(name: "Latte", mg: 120)
                quickAddButton(name: "Cold Brew", mg: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quickAddButton(name: String, mg: Double) -> some View {
        Button {
            viewModel.addDrink(
                name: name,
                caffeineMG: mg,
                context: modelContext
            )
        } label: {
            CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
                VStack(spacing: 10) {
                    Image(systemName: symbol(for: name))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(CXTheme.caffeineAccent)

                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(Int(mg)) mg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 86)
            }
        }
        .buttonStyle(.plain)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Timeline")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(dashboardEntries.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if entries.isEmpty {
                CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .foregroundStyle(CXTheme.caffeineAccent)

                        Text("Your caffeine timeline will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }
            } else {
                ForEach(dashboardEntries) { entry in
                    timelineRow(entry)
                }

                if entries.count > dashboardEntries.count {
                    Text("Showing the \(dashboardEntries.count) most recent entries from the 30-day sync window.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dashboardEntries: ArraySlice<CaffeineEntry> {
        entries.prefix(CaffeineHistoryPolicy.dashboardEntryLimit)
    }

    private func timelineRow(_ entry: CaffeineEntry) -> some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(CXTheme.caffeineAccent.opacity(0.18))
                        .frame(width: 42, height: 42)

                    Image(systemName: symbol(for: entry.drinkName))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(CXTheme.caffeineAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.drinkName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(entry.consumedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if entry.source == .healthKit {
                        Text("Apple Health")
                            .font(.caption2)
                            .foregroundStyle(CXTheme.healthAccent)
                    }
                }

                Spacer()

                Text("\(Int(entry.caffeineMG)) mg")
                    .font(.headline)
                    .foregroundStyle(CXTheme.caffeineAccent)
            }
        }
    }

    private var emptyState: some View {
        CXGlassCard {
            VStack(spacing: 16) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(CXTheme.caffeineAccent)

                VStack(spacing: 6) {
                    Text("No caffeine logged today")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Add your first drink to start tracking your caffeine intelligence.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                quickAddButton(name: "Espresso", mg: 64)
            }
        }
    }

    private func riskTint(for risk: CaffeineRiskLevel) -> Color {
        switch risk {
        case .low:
            return CXTheme.healthAccent
        case .moderate:
            return CXTheme.caffeineAccent
        case .high, .sleepRisk:
            return CXTheme.warningAccent
        }
    }

    private func recommendationSymbol(for risk: CaffeineRiskLevel) -> String {
        switch risk {
        case .low:
            return "checkmark.seal.fill"
        case .moderate:
            return "exclamationmark.circle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .sleepRisk:
            return "moon.zzz.fill"
        }
    }

    private func recommendationText(for status: CaffeineStatus) -> String {
        switch status.riskLevel {
        case .low:
            return "Your logged intake is below the general daily reference. Your personal response can still vary."
        case .moderate:
            return "Your estimated caffeine load is rising. Consider waiting before another serving."
        case .high:
            return "You reached the 400 mg general adult reference. Avoid more caffeine unless a clinician has advised otherwise."
        case .sleepRisk:
            return "The slower-metabolism estimate remains elevated near bedtime. Consider stopping caffeine for today."
        }
    }

    private var healthSymbol: String {
        switch viewModel.healthAccessState {
        case .writeEnabled:
            return "heart.fill"
        case .notRequested:
            return "heart.circle"
        case .writeDisabled, .unavailable:
            return "heart.slash.fill"
        }
    }

    private var healthTint: Color {
        viewModel.healthAccessState == .writeEnabled ? CXTheme.healthAccent : CXTheme.warningAccent
    }

    private var healthStatusText: String {
        switch viewModel.healthAccessState {
        case .unavailable:
            return "Apple Health is unavailable on this device."
        case .notRequested:
            return "Connect to import and save caffeine records."
        case .writeEnabled:
            return "Writing is enabled. Imported records depend on your read choice."
        case .writeDisabled:
            return "Writing is off. Read access remains private to Apple Health."
        }
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
    TodayView()
        .environment(SleepScheduleStore())
        .environment(CaffeineSensitivityStore())
        .modelContainer(for: [CaffeineEntry.self, Drink.self], inMemory: true)
}
