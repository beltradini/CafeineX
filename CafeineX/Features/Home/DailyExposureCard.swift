import SwiftUI

struct DailyExposureCard: View {
    let context: DailyExposureContext

    var body: some View {
        CXGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Exposure")
                            .font(.headline)

                        Text(context.guidance.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(guidanceTint)
                    }

                    Spacer()

                    Image(systemName: guidanceSymbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(guidanceTint)
                        .accessibilityHidden(true)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 145), spacing: 12)],
                    spacing: 12
                ) {
                    CXMetricCard(
                        title: "Nicotine today",
                        value: context.nicotineStatus.amountsToday.displayText,
                        symbol: "waveform.path.ecg",
                        tint: CXTheme.nicotineAccent
                    )

                    CXMetricCard(
                        title: "Active windows",
                        value: context.nicotineStatus.activeEventCount.formatted(),
                        symbol: "clock.badge",
                        tint: CXTheme.nicotineAccent
                    )
                }

                Text(context.guidance.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if context.hasTemporalOverlap {
                    Label(
                        "\(context.temporalOverlapCount) timing \(context.temporalOverlapCount == 1 ? "overlap" : "overlaps")",
                        systemImage: "arrow.triangle.branch"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CXTheme.warningAccent)
                }

                Text(context.nicotineStatus.sleepGuidance.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var guidanceTint: Color {
        switch context.guidance {
        case .clear: CXTheme.healthAccent
        case .caffeineOnly: CXTheme.caffeineAccent
        case .nicotineOnly: CXTheme.nicotineAccent
        case .temporalOverlap, .sleepPriority: CXTheme.warningAccent
        }
    }

    private var guidanceSymbol: String {
        switch context.guidance {
        case .clear: "checkmark.seal.fill"
        case .caffeineOnly: "cup.and.saucer.fill"
        case .nicotineOnly: "waveform.path.ecg"
        case .temporalOverlap: "arrow.triangle.branch"
        case .sleepPriority: "moon.zzz.fill"
        }
    }
}
