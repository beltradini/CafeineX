import SwiftUI
import WidgetKit

struct CafeineXActiveWindowWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: CafeineXWidgetConstants.activeWindowKind,
            provider: CafeineXWidgetProvider()
        ) { entry in
            CafeineXActiveWindowEntryView(entry: entry)
        }
        .configurationDisplayName("Active Window")
        .description("See your active estimate and sleep context.")
        .supportedFamilies([
            .systemSmall,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

struct CafeineXActiveWindowEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CafeineXWidgetEntry

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryInline:
            CafeineXInlineWindowView(snapshot: entry.snapshot)
        case .accessoryCircular:
            CafeineXCircularWindowView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            CafeineXRectangularWindowView(snapshot: entry.snapshot)
        default:
            CafeineXSmallWindowView(snapshot: entry.snapshot)
        }
    }
}

private struct CafeineXSmallWindowView: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.activeRangeText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
                .privacySensitive()

            if !isLuminanceReduced {
                if snapshot.isStale() {
                    CafeineXFreshnessLabel(snapshot: snapshot)
                        .privacySensitive()
                } else {
                    Text("Active estimate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            CafeineXStateLabel(snapshot: snapshot)
                .privacySensitive()

            if !isLuminanceReduced {
                Label(
                    "Sleep \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))",
                    systemImage: "bed.double.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .privacySensitive()
            }
        }
        .containerBackground(for: .widget) {
            CafeineXWidgetBackground()
        }
        .privacySensitive()
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        "\(snapshot.activeRangeText) active estimate. \(snapshot.state.title). Configured sleep time \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))."
    }
}

private struct CafeineXInlineWindowView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        Label(
            "\(snapshot.activeRangeText) active",
            systemImage: snapshot.state.symbolName
        )
        .privacySensitive()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityLabel("\(snapshot.activeRangeText) active estimate. \(snapshot.state.title).")
    }
}

private struct CafeineXCircularWindowView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            Image(systemName: snapshot.state.symbolName)
                .font(.title3.weight(.semibold))
                .widgetAccentable()
        }
        .privacySensitive()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityLabel("\(snapshot.state.title). \(snapshot.activeRangeText) active estimate.")
    }
}

private struct CafeineXRectangularWindowView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(snapshot.activeRangeText)
                .font(.headline)
                .lineLimit(1)

            CafeineXStateLabel(snapshot: snapshot)
        }
        .privacySensitive()
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.activeRangeText) active estimate. \(snapshot.state.title).")
    }
}
