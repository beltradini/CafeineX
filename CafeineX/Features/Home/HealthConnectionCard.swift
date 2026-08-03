import SwiftUI

struct HealthConnectionCard: View {
    let state: HomeViewModel.HealthAccessState
    let isSyncing: Bool
    let lastSyncDate: Date?
    let message: String?
    let sleepState: HomeViewModel.SleepDataState
    let action: () -> Void

    var body: some View {
        CXSurfaceCard(cornerRadius: CXTheme.smallCornerRadius) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Health & sync status")
                            .font(.headline)
                        Text("Your data stays visible and under your control.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Button(action: action) {
                        if isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(state == .notRequested ? "Connect" : "Sync")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(state == .unavailable || isSyncing)
                    .accessibilityHint("Imports caffeine records and updates eligible entries")
                }

                VStack(alignment: .leading, spacing: 10) {
                    statusRow(
                        title: "Saved on this device",
                        detail: "Local caffeine and nicotine logs remain available offline.",
                        symbol: "checkmark.circle.fill",
                        color: CXTheme.healthAccent
                    )

                    statusRow(
                        title: healthConnectionTitle,
                        detail: healthConnectionDetail,
                        symbol: healthConnectionSymbol,
                        color: healthConnectionColor
                    )

                    statusRow(
                        title: syncTitle,
                        detail: syncDetail,
                        symbol: isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise.circle.fill",
                        color: isSyncing ? CXTheme.caffeineAccent : .secondary
                    )

                    statusRow(
                        title: sleepTitle,
                        detail: sleepDetail,
                        symbol: sleepSymbol,
                        color: sleepColor
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("health-connection-card")
    }

    private var symbol: String {
        switch state {
        case .writeEnabled: "heart.fill"
        case .notRequested: "heart.circle"
        case .writeDisabled, .unavailable: "heart.slash.fill"
        }
    }

    private var tint: Color {
        state == .writeEnabled ? CXTheme.healthAccent : CXTheme.warningAccent
    }

    private var healthConnectionTitle: String {
        switch state {
        case .unavailable: "Apple Health unavailable"
        case .notRequested: "Apple Health not connected"
        case .writeEnabled: "Apple Health connected"
        case .writeDisabled: "Apple Health write access is off"
        }
    }

    private var healthConnectionDetail: String {
        switch state {
        case .unavailable: "HealthKit is unavailable on this device."
        case .notRequested: "Connect to import and save eligible caffeine records."
        case .writeEnabled: "Caffeine records can sync with Apple Health."
        case .writeDisabled: "Saved on this device. You can enable writing in Apple Health settings."
        }
    }

    private var healthConnectionSymbol: String {
        switch state {
        case .writeEnabled: "heart.fill"
        case .notRequested: "heart.circle"
        case .writeDisabled, .unavailable: "heart.slash.fill"
        }
    }

    private var healthConnectionColor: Color {
        state == .writeEnabled ? CXTheme.healthAccent : CXTheme.warningAccent
    }

    private var syncTitle: String {
        if isSyncing { return "Syncing Apple Health…" }
        guard let lastSyncDate else { return "Apple Health not synced yet" }
        return "Last synced \(syncDateDescription(lastSyncDate))"
    }

    private var syncDetail: String {
        if let message, !message.isEmpty { return message }
        return state == .unavailable
            ? "Local tracking remains available."
            : "Tap Sync to check for the latest records."
    }

    private var sleepTitle: String {
        switch sleepState {
        case .available: "Sleep snapshot updated"
        case .loading: "Updating sleep snapshot…"
        case .notRequested: "Sleep snapshot not connected"
        case .noData: "No recent sleep snapshot"
        case .failed: "Sleep snapshot needs attention"
        case .unavailable: "Sleep data unavailable"
        }
    }

    private var sleepDetail: String {
        switch sleepState {
        case .available: "Recent sleep data is available for context."
        case .loading: "Reading the latest available sleep data."
        case .notRequested: "Sleep access is optional and read-only."
        case .noData: "Check Apple Health for recent sleep records."
        case .failed: "Review sleep access in Apple Health and try again."
        case .unavailable: "Sleep analysis is unavailable on this device."
        }
    }

    private var sleepSymbol: String {
        switch sleepState {
        case .available: "moon.stars.fill"
        case .loading: "arrow.triangle.2.circlepath"
        case .notRequested, .noData, .failed, .unavailable: "moon.zzz.fill"
        }
    }

    private var sleepColor: Color {
        switch sleepState {
        case .available: CXTheme.healthAccent
        case .loading: CXTheme.caffeineAccent
        case .notRequested, .noData, .failed, .unavailable: .secondary
        }
    }

    @ViewBuilder
    private func statusRow(
        title: String,
        detail: String,
        symbol: String,
        color: Color
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .symbolEffect(.pulse, options: .repeating, isActive: isSyncing && symbol.contains("arrow"))
        }
    }

    private func syncDateDescription(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "today at \(date.formatted(date: .omitted, time: .shortened))"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
