import SwiftUI
import WidgetKit

struct CafeineXDailyRhythmView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            primaryMetric
            activeRangeChart
            recentExposures
        }
        .containerBackground(for: .widget) {
            CafeineXWidgetBackground()
        }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack {
            CafeineXBrandMark()
            Spacer()
            CafeineXStateLabel(snapshot: snapshot)
            Link(destination: URL(string: "cafeinex://quick-add")!) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(CafeineXWidgetPalette.caffeine)
                    .widgetAccentable()
            }
            .accessibilityLabel("Open Quick Add")
        }
    }

    private var primaryMetric: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.activeRangeText)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Text("estimated active caffeine")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(snapshot.caffeineTodayMG.rounded())) mg")
                    .font(.title3.weight(.bold))
                Text("logged today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activeRangeChart: some View {
        VStack(spacing: 5) {
            ActiveRangeBand(points: snapshot.activeRangePoints)
                .frame(height: 112)

            HStack {
                Text("Now")
                Spacer()
                Text(cutoffLabel)
                Spacer()
                Text("Sleep \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.secondary.opacity(0.10), in: ContainerRelativeShape())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Estimated active caffeine range from now through configured sleep time"
        )
    }

    private var cutoffLabel: String {
        if snapshot.cutoffTime <= .now {
            return "After cutoff"
        }
        return "Cutoff \(snapshot.cutoffTime.formatted(date: .omitted, time: .shortened))"
    }

    @ViewBuilder
    private var recentExposures: some View {
        if snapshot.recentExposures.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("Recent exposures")
                    .font(.headline)
                Text("No recent caffeine or nicotine exposures are available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 7) {
                Text("Recent exposures")
                    .font(.headline)

                ForEach(snapshot.recentExposures.prefix(2)) { exposure in
                    HStack(spacing: 9) {
                        Image(systemName: exposure.symbolName)
                            .frame(width: 20)
                            .foregroundStyle(exposure.accentColor)
                            .widgetAccentable()
                            .accessibilityHidden(true)

                        Text(exposure.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        Spacer()

                        Text(exposure.amountText)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(exposure.date, style: .time)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

}

private struct ActiveRangeBand: View {
    let points: [WidgetActiveRangePoint]

    var body: some View {
        GeometryReader { proxy in
            if points.isEmpty {
                VStack(spacing: 5) {
                    Image(systemName: "chart.xyaxis.line")
                    Text("No recent caffeine")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    horizontalGuides
                    bandPath(in: proxy.size)
                        .fill(CafeineXWidgetPalette.caffeine.opacity(0.16))
                        .widgetAccentable()
                    linePath(\.highMG, in: proxy.size)
                        .stroke(
                            CafeineXWidgetPalette.caffeine,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        .widgetAccentable()
                    linePath(\.lowMG, in: proxy.size)
                        .stroke(
                            CafeineXWidgetPalette.sleep.opacity(0.85),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                        )
                }
            }
        }
    }

    private var horizontalGuides: some View {
        VStack {
            Divider().opacity(0.25)
            Spacer()
            Divider().opacity(0.16)
            Spacer()
            Divider().opacity(0.12)
        }
    }

    private func linePath(
        _ keyPath: KeyPath<WidgetActiveRangePoint, Double>,
        in size: CGSize
    ) -> Path {
        Path { path in
            for (index, point) in points.enumerated() {
                let location = chartPoint(
                    index: index,
                    value: point[keyPath: keyPath],
                    size: size
                )
                if index == 0 {
                    path.move(to: location)
                } else {
                    path.addLine(to: location)
                }
            }
        }
    }

    private func bandPath(in size: CGSize) -> Path {
        Path { path in
            for (index, point) in points.enumerated() {
                let location = chartPoint(index: index, value: point.highMG, size: size)
                if index == 0 {
                    path.move(to: location)
                } else {
                    path.addLine(to: location)
                }
            }

            for (index, point) in points.enumerated().reversed() {
                path.addLine(to: chartPoint(index: index, value: point.lowMG, size: size))
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
