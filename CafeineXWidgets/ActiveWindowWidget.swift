import SwiftUI
import WidgetKit

struct CafeineXOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: CafeineXWidgetConstants.overviewKind,
            provider: CafeineXWidgetProvider()
        ) { entry in
            CafeineXOverviewEntryView(entry: entry)
        }
        .configurationDisplayName("CafeineX Overview")
        .description("See your active caffeine estimate in context with your configured sleep window.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

struct CafeineXOverviewEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CafeineXWidgetEntry

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemMedium:
            CafeineXTodayView(snapshot: entry.snapshot)
        case .systemLarge:
            CafeineXDailyRhythmView(snapshot: entry.snapshot)
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
    @Environment(\.showsWidgetContainerBackground) private var showsBackground
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: showsBackground ? 9 : 13) {
            if showsBackground {
                CafeineXBrandMark()
            }

            Spacer(minLength: 0)

            Text(snapshot.activeRangeText)
                .font(.system(
                    size: showsBackground ? 31 : 36,
                    weight: .bold,
                    design: .rounded
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .contentTransition(.numericText())

            Text("estimated active caffeine")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            CafeineXStateLabel(snapshot: snapshot, compact: true)

            Label(
                "Sleep \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))",
                systemImage: "bed.double.fill"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .containerBackground(for: .widget) {
            CafeineXWidgetBackground()
        }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        "CafeineX, \(snapshot.activeRangeText) active estimate, \(snapshot.state.title), configured sleep time \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))"
    }
}

private struct CafeineXInlineWindowView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        Label(
            "\(snapshot.activeRangeText) · Sleep \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))",
            systemImage: "sparkles"
        )
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "cafeinex://history"))
    }
}

private struct CafeineXCircularWindowView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: -2) {
                Text(centralAmount)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text("mg")
                    .font(.system(size: 9, weight: .semibold))
            }
            .widgetAccentable()
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityLabel("\(snapshot.activeRangeText) active estimate")
    }

    private var centralAmount: String {
        guard let low = snapshot.activeCaffeineLowMG,
              let high = snapshot.activeCaffeineHighMG else {
            return "—"
        }
        return Int(((low + high) / 2).rounded()).formatted()
    }
}

private struct CafeineXRectangularWindowView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(snapshot.activeRangeText)
                .font(.headline)
                .lineLimit(1)

            CafeineXStateLabel(snapshot: snapshot, compact: true)

            Label(
                "Sleep \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))",
                systemImage: "bed.double.fill"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityElement(children: .combine)
    }
}
