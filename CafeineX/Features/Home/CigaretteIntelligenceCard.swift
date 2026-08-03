import SwiftUI

struct CigaretteIntelligenceCard: View {
    let summary: CigaretteIntelligenceSummary
    let goal: CigaretteGoal
    let addCigarette: () -> Void

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Cigarette Intelligence", systemImage: "smoke.fill")
                        .font(.headline)
                        .foregroundStyle(CXTheme.nicotineAccent)
                    Spacer()
                    Text("Today").font(.caption).foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(summary.cigarettesToday.formatted(.number.precision(.fractionLength(0...1))))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(summary.cigarettesToday == 1 ? "cigarette" : "cigarettes")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    metric("Since last", value: sinceLastText, symbol: "timer")
                    metric("With caffeine", value: summary.caffeinePairingsToday.formatted(), symbol: "cup.and.saucer.fill")
                    metric("Sleep window", value: summary.sleepWindowEventsToday.formatted(), symbol: "moon.zzz.fill")
                }

                Label(goal.description, systemImage: goal.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: addCigarette) {
                    Label("Log One Cigarette", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CXTheme.nicotineAccent)
                .accessibilityIdentifier("cigarette-log-one-button")
                .accessibilityHint("Logs one cigarette now and offers Undo")
            }
        }
    }

    private var sinceLastText: String {
        guard let date = summary.latestEventAt else { return "—" }
        let seconds = max(Date.now.timeIntervalSince(date), 0)
        if seconds < 3_600 { return "\(max(Int(seconds / 60), 1))m" }
        return "\(Int(seconds / 3_600))h"
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(value, systemImage: symbol).font(.subheadline.bold())
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
