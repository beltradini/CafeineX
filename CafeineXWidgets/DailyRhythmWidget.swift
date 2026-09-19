import SwiftUI
import WidgetKit

struct CafeineXDailyRhythmWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: CafeineXWidgetConstants.dailyRhythmKind,
            provider: CafeineXWidgetProvider()
        ) { entry in
            CafeineXDailyRhythmView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Daily Rhythm")
        .description("See how your active estimate changes toward sleep.")
        .supportedFamilies([.systemLarge])
    }
}

struct CafeineXDailyRhythmView: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAILY RHYTHM")
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CafeineXWidgetPalette.caffeine)
                .widgetAccentable()

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(snapshot.activeRangeText)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .contentTransition(.numericText())
                    Text("active now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                CafeineXStateLabel(snapshot: snapshot)
            }
            .privacySensitive()

            ActiveRangeBand(points: snapshot.activeRangePoints)
                .frame(maxWidth: .infinity, minHeight: 132)
                .privacySensitive()

            HStack {
                Text("Now")
                Spacer()
                Label(
                    "Sleep \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))",
                    systemImage: "bed.double.fill"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .privacySensitive()

            Spacer(minLength: 0)
            Divider()

            HStack(spacing: 12) {
                Text("\(Int(snapshot.caffeineTodayMG.rounded())) mg today")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                if !isLuminanceReduced {
                    latestExposure
                }
            }
            .privacySensitive()
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
            Text("Latest: \(exposure.title) · \(exposure.date.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        } else {
            Text("No recent exposures")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ActiveRangeBand: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let points: [WidgetActiveRangePoint]

    var body: some View {
        GeometryReader { proxy in
            if points.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "chart.xyaxis.line")
                    Text("No recent caffeine data")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack(alignment: .trailing) {
                    bandPath(in: proxy.size)
                        .fill(bandColor.opacity(isLuminanceReduced ? 0.12 : 0.18))

                    bandPath(in: proxy.size)
                        .stroke(
                            bandColor.opacity(isLuminanceReduced ? 0.65 : 0.82),
                            style: StrokeStyle(lineWidth: 1.5, lineJoin: .round)
                        )

                    Rectangle()
                        .fill(sleepMarkerColor)
                        .frame(width: 2)
                }
                .widgetAccentable()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estimated active caffeine range from now to configured sleep time")
    }

    private var bandColor: Color {
        renderingMode == .fullColor && !isLuminanceReduced
            ? CafeineXWidgetPalette.caffeine
            : .primary
    }

    private var sleepMarkerColor: Color {
        renderingMode == .fullColor && !isLuminanceReduced
            ? CafeineXWidgetPalette.sleep
            : .secondary
    }

    private func bandPath(in size: CGSize) -> Path {
        Path { path in
            for (index, point) in points.enumerated() {
                let location = chartPoint(
                    index: index,
                    value: point.highMG,
                    size: size
                )
                if index == 0 {
                    path.move(to: location)
                } else {
                    path.addLine(to: location)
                }
            }

            for (index, point) in points.enumerated().reversed() {
                path.addLine(to: chartPoint(
                    index: index,
                    value: point.lowMG,
                    size: size
                ))
            }
            path.closeSubpath()
        }
    }

    private func chartPoint(index: Int, value: Double, size: CGSize) -> CGPoint {
        let maximum = max(points.map(\.highMG).max() ?? 1, 1)
        let x = points.count > 1
            ? size.width * CGFloat(index) / CGFloat(points.count - 1)
            : 0
        let y = size.height * (1 - CGFloat(max(value, 0) / maximum))
        return CGPoint(x: x, y: y)
    }
}
