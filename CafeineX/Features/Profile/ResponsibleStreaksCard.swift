import SwiftUI

struct ResponsibleStreaksCard: View {
    let summary: StreakSummary

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Responsible Streaks")
                            .font(.headline)
                        Text("Consistency without pressure")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "flame.fill")
                        .foregroundStyle(CXTheme.caffeineAccent)
                }

                metric(
                    title: "Awareness",
                    current: summary.awarenessDays,
                    best: summary.bestAwarenessDays,
                    thisWeek: summary.reviewedDaysThisWeek,
                    symbol: "brain.head.profile",
                    tint: CXTheme.healthAccent
                )

                Divider()

                metric(
                    title: "Sleep protection",
                    current: summary.sleepProtectionDays,
                    best: summary.bestSleepProtectionDays,
                    thisWeek: summary.protectedDaysThisWeek,
                    symbol: "moon.stars.fill",
                    tint: CXTheme.nicotineAccent
                )

                Text("A missed review pauses the current streak; it never erases your best. Sleep protection only counts completed, reviewed days without caffeine after your cutoff.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func metric(
        title: String,
        current: Int,
        best: Int,
        thisWeek: Int,
        symbol: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text("\(thisWeek) days this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(current) current")
                    .font(.subheadline.bold())
                    .monospacedDigit()
                Text("Best \(best)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}
