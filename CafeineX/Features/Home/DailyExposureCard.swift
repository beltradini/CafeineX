import SwiftUI

struct DailyExposureCard: View {
    let context: DailyExposureContext

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nicotine context")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(context.guidance.title)
                            .font(.title3.bold())
                    }

                    Spacer()

                    Image(systemName: guidanceSymbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(guidanceTint)
                        .accessibilityHidden(true)
                }

                HStack(spacing: 18) {
                    Label(
                        context.nicotineStatus.amountsToday.displayText,
                        systemImage: "waveform.path.ecg"
                    )

                    if context.nicotineStatus.activeEventCount > 0 {
                        Label(
                            "\(context.nicotineStatus.activeEventCount) active",
                            systemImage: "clock"
                        )
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CXTheme.nicotineAccent)

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
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-nicotine-context-card")
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
