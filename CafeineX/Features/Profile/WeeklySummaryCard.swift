import SwiftUI

struct WeeklySummaryCard: View {
    let summary: WeeklySummary
    let goal: ProfileGoal

    private var progress: WeeklyGoalProgress {
        summary.progress(for: goal)
    }

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("This Week")
                            .font(.headline)
                        Text(periodText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(CXTheme.caffeineAccent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(progress.title, systemImage: goal.symbol)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Text(progress.accessibilityValue)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: progress.fraction)
                        .tint(CXTheme.healthAccent)
                        .accessibilityLabel(progress.title)
                        .accessibilityValue(progress.accessibilityValue)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 120), spacing: 10)],
                    spacing: 10
                ) {
                    metric(
                        value: "\(Int(summary.caffeineMG.rounded())) mg",
                        label: "Caffeine",
                        symbol: "cup.and.saucer.fill",
                        tint: CXTheme.caffeineAccent
                    )
                    metric(
                        value: summary.trackedDays.formatted(),
                        label: "Tracked days",
                        symbol: "calendar",
                        tint: CXTheme.healthAccent
                    )
                    metric(
                        value: summary.lateCaffeineEvents.formatted(),
                        label: "After cutoff",
                        symbol: "moon.zzz.fill",
                        tint: CXTheme.nicotineAccent
                    )
                    metric(
                        value: summary.nicotineEvents.formatted(),
                        label: "Nicotine events",
                        symbol: "waveform.path.ecg",
                        tint: CXTheme.nicotineAccent
                    )
                }

                Label(comparisonText, systemImage: comparisonSymbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func metric(
        value: String,
        label: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(value, systemImage: symbol)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var periodText: String {
        let finalDay = summary.interval.end.addingTimeInterval(-1)
        return "\(summary.interval.start.formatted(.dateTime.month(.abbreviated).day()))–\(finalDay.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var comparisonText: String {
        let change = summary.caffeineChangeMG
        if abs(change) < 1 {
            return "Caffeine exposure is level with last week so far."
        }

        let amount = Int(abs(change).rounded())
        let direction = change > 0 ? "more" : "less"
        return "\(amount) mg \(direction) caffeine than the previous full week. Context matters more than a lower number."
    }

    private var comparisonSymbol: String {
        if abs(summary.caffeineChangeMG) < 1 {
            return "equal.circle"
        }
        return summary.caffeineChangeMG > 0
            ? "arrow.up.right.circle"
            : "arrow.down.right.circle"
    }
}
