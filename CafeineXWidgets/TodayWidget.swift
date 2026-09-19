import SwiftUI
import WidgetKit

struct CafeineXTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: CafeineXWidgetConstants.todayKind,
            provider: CafeineXWidgetProvider()
        ) { entry in
            CafeineXTodayView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Today")
        .description("See today's caffeine and latest entry.")
        .supportedFamilies([.systemMedium])
    }
}

struct CafeineXTodayView: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("TODAY")
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CafeineXWidgetPalette.caffeine)
                .widgetAccentable()

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Int(snapshot.caffeineTodayMG.rounded())) mg")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                    Text("logged today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .privacySensitive()

                Spacer(minLength: 16)

                CafeineXStateLabel(snapshot: snapshot)
                    .privacySensitive()
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Label(
                    snapshot.bedtime.formatted(date: .omitted, time: .shortened),
                    systemImage: "bed.double.fill"
                )
                .lineLimit(1)

                if !isLuminanceReduced {
                    Text("configured sleep")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .privacySensitive()

            if !isLuminanceReduced {
                Divider()
                latestExposure
                    .privacySensitive()
            }
        }
        .containerBackground(for: .widget) {
            CafeineXWidgetBackground()
        }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var latestExposure: some View {
        if let exposure = snapshot.recentExposures.first {
            HStack(spacing: 6) {
                Text("Latest:")
                    .foregroundStyle(.secondary)

                Text(exposure.title)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(exposure.date, style: .time)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .accessibilityElement(children: .combine)
        } else {
            Label("No recent exposures", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
