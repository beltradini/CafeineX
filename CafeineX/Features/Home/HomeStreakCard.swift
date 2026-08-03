import SwiftUI

struct HomeStreakCard: View {
    let summary: StreakSummary
    let reviewToday: () -> Void

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Mindful consistency")
                            .font(.headline)
                        Text("Awareness, never consumption")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: summary.isTodayReviewed ? "checkmark.seal.fill" : "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(
                            summary.isTodayReviewed
                                ? CXTheme.healthAccent
                                : CXTheme.caffeineAccent
                        )
                }

                HStack(spacing: 12) {
                    metric(
                        value: summary.awarenessDays,
                        label: "Awareness",
                        symbol: "brain.head.profile",
                        tint: CXTheme.healthAccent
                    )
                    metric(
                        value: summary.sleepProtectionDays,
                        label: "Sleep protected",
                        symbol: "moon.stars.fill",
                        tint: CXTheme.nicotineAccent
                    )
                }

                if summary.isTodayReviewed {
                    Label("Today is reviewed", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CXTheme.healthAccent)
                } else {
                    Button(action: reviewToday) {
                        Label("Review Today", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CXTheme.healthAccent)
                }
            }
        }
    }

    private func metric(
        value: Int,
        label: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(value.formatted(), systemImage: symbol)
                .font(.title3.bold())
                .foregroundStyle(tint)
            Text(value == 1 ? "\(label) day" : "\(label) days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
