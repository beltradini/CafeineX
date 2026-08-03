import SwiftUI

struct ExposureHeroView: View {
    let status: CaffeineStatus

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Right now")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(actionTitle)
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                            .contentTransition(.interpolate)
                    }

                    Spacer()

                    Label(status.riskLevel.title, systemImage: recommendationSymbol)
                        .font(.caption.bold())
                        .foregroundStyle(riskTint)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(riskTint.opacity(0.12), in: Capsule())
                }

                Label(recommendationText, systemImage: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 145), spacing: 12)],
                    spacing: 12
                ) {
                    CXMetricTile(
                        title: "Active estimate",
                        value: "≈ \(Int(status.activeCaffeineMG.rounded())) mg",
                        symbol: "bolt.heart",
                        tint: CXTheme.caffeineAccent
                    )

                    CXMetricTile(
                        title: "Suggested cutoff",
                        value: status.suggestedCutoffTime.formatted(
                            date: .omitted,
                            time: .shortened
                        ),
                        symbol: "clock.badge.checkmark",
                        tint: CXTheme.nicotineAccent
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(Int(status.consumedTodayMG.rounded())) mg today")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("400 mg reference")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: status.dailyProgress)
                        .tint(riskTint)
                        .accessibilityLabel("Daily caffeine reference")
                        .accessibilityValue(
                            Text(status.dailyProgress, format: .percent)
                        )

                    Text("Likely active range: \(Int(status.activeCaffeineLowMG.rounded()))–\(Int(status.activeCaffeineHighMG.rounded())) mg")
                        .font(.subheadline.weight(.semibold))
                        .padding(.top, 6)

                    Text("At \(status.targetBedtime, style: .time): \(Int(status.caffeineAtBedtimeLowMG.rounded()))–\(Int(status.caffeineAtBedtimeHighMG.rounded())) mg estimated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var riskTint: Color {
        switch status.riskLevel {
        case .low: CXTheme.healthAccent
        case .moderate: CXTheme.caffeineAccent
        case .high, .sleepRisk: CXTheme.warningAccent
        }
    }

    private var recommendationSymbol: String {
        switch status.riskLevel {
        case .low: "checkmark.seal.fill"
        case .moderate: "exclamationmark.circle.fill"
        case .high: "exclamationmark.triangle.fill"
        case .sleepRisk: "moon.zzz.fill"
        }
    }

    private var recommendationText: String {
        switch status.riskLevel {
        case .low:
            "Your logged intake is below the general daily reference. Personal response can still vary."
        case .moderate:
            "Your estimated caffeine load is rising. Consider waiting before another serving."
        case .high:
            "You reached the 400 mg general adult reference. Consider avoiding more caffeine today."
        case .sleepRisk:
            "The slower-metabolism estimate remains elevated near bedtime. Consider stopping caffeine for today."
        }
    }

    private var actionTitle: String {
        switch status.riskLevel {
        case .low: "Your window is open"
        case .moderate: "Pause before another"
        case .high: "Stop caffeine for today"
        case .sleepRisk: "Protect tonight's sleep"
        }
    }
}
