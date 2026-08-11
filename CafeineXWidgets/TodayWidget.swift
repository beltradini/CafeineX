import SwiftUI
import WidgetKit

struct CafeineXTodayView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            metrics
            CafeineXTimelineBar(snapshot: snapshot)
            recentExposureRow
        }
        .containerBackground(for: .widget) {
            CafeineXWidgetBackground()
        }
        .widgetURL(URL(string: "cafeinex://history"))
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack {
            CafeineXBrandMark(compact: true)

            Spacer()

            CafeineXStateLabel(snapshot: snapshot, compact: true)

            Link(destination: URL(string: "cafeinex://quick-add")!) {
                Image(systemName: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(CafeineXWidgetPalette.caffeine)
                    .widgetAccentable()
            }
            .accessibilityLabel("Open Quick Add")
        }
    }

    private var metrics: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 0) {
                Text(snapshot.activeRangeText)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("active estimate · \(Int(snapshot.caffeineTodayMG.rounded())) mg today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 0) {
                Text(snapshot.bedtime.formatted(date: .omitted, time: .shortened))
                    .font(.headline)
                    .lineLimit(1)
                Text("configured sleep")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var recentExposureRow: some View {
        if snapshot.recentExposures.isEmpty {
            Label("No recent exposure", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            let exposure = snapshot.recentExposures[0]
            HStack(spacing: 6) {
                Image(systemName: exposure.symbolName)
                    .foregroundStyle(exposure.accentColor)
                    .widgetAccentable()
                    .accessibilityHidden(true)

                Text("Last: \(exposure.title)")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text("\(exposure.amountText) · \(exposure.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
