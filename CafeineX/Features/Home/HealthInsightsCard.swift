import SwiftUI

struct HealthInsightsCard: View {
    let state: HomeViewModel.SleepDataState
    let summary: HealthInsightsSummary?
    let message: String?
    let isLoading: Bool
    let connect: () -> Void
    let refresh: () -> Void

    var body: some View {
        CXGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Sleep Context", systemImage: "moon.stars.fill")
                        .font(.headline)
                        .foregroundStyle(CXTheme.healthAccent)

                    Spacer()

                    if state == .available || state == .noData || state == .failed {
                        Button("Refresh", action: refresh)
                            .font(.caption.weight(.semibold))
                            .disabled(isLoading)
                    }
                }

                content
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("health-insights-card")
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .unavailable:
            stateMessage(
                title: "Apple Health unavailable",
                text: "Sleep context requires HealthKit on a supported device.",
                symbol: "heart.slash"
            )
        case .notRequested:
            stateMessage(
                title: "Add optional sleep context",
                text: "Allow read-only access to recent sleep analysis. CafeineX keeps the snapshot in memory and does not copy sleep samples into its database.",
                symbol: "lock.shield"
            )
            Button("Choose Sleep Access", action: connect)
                .buttonStyle(.borderedProminent)
                .tint(CXTheme.healthAccent)
                .accessibilityIdentifier("choose-sleep-access-button")
        case .loading:
            HStack(spacing: 12) {
                ProgressView()
                Text("Reading the latest available sleep period…")
                    .foregroundStyle(.secondary)
            }
        case .noData:
            stateMessage(
                title: "No readable recent sleep data",
                text: "This can mean there are no completed sleep samples in the last 14 days, access is limited, or read access was not granted. HealthKit does not reveal which applies.",
                symbol: "questionmark.circle"
            )
        case .failed:
            stateMessage(
                title: "Sleep context unavailable",
                text: message ?? "CafeineX could not read recent sleep data.",
                symbol: "exclamationmark.triangle"
            )
        case .available:
            if let summary {
                ForEach(summary.insights) { insight in
                    insightRow(insight)
                    if insight.id != summary.insights.last?.id {
                        Divider()
                    }
                }

                Text(HealthInsightsSummary.limitationText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func stateMessage(
        title: String,
        text: String,
        symbol: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func insightRow(_ insight: HealthInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.symbol)
                .foregroundStyle(tint(for: insight.tone))
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func tint(for tone: HealthInsightTone) -> Color {
        switch tone {
        case .neutral: .secondary
        case .supportive: CXTheme.healthAccent
        case .attention: CXTheme.warningAccent
        case .incomplete: .secondary
        }
    }
}
