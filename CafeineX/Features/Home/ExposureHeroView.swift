import SwiftUI

struct ExposureHeroView: View {
    let status: CaffeineStatus

    var body: some View {
        CXGlassCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(Int(status.consumedTodayMG.rounded())) mg")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    Text("Caffeine consumed today")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: status.dailyProgress)
                    .tint(CXTheme.caffeineAccent)
                    .accessibilityLabel("Daily caffeine reference")
                    .accessibilityValue(
                        Text(status.dailyProgress, format: .percent)
                    )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 145), spacing: 12)],
                    spacing: 12
                ) {
                    CXMetricCard(
                        title: "Active estimate",
                        value: "≈ \(Int(status.activeCaffeineMG.rounded())) mg",
                        symbol: "bolt.heart",
                        tint: CXTheme.caffeineAccent
                    )

                    CXMetricCard(
                        title: "Guidance",
                        value: status.riskLevel.title,
                        symbol: recommendationSymbol,
                        tint: riskTint
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Likely active: \(Int(status.activeCaffeineLowMG.rounded()))–\(Int(status.activeCaffeineHighMG.rounded())) mg")
                        .font(.subheadline.weight(.semibold))

                    Text("At \(status.targetBedtime, style: .time): \(Int(status.caffeineAtBedtimeLowMG.rounded()))–\(Int(status.caffeineAtBedtimeHighMG.rounded())) mg estimated")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(recommendationText, systemImage: recommendationSymbol)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
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
}
