import Foundation
import WidgetKit

struct CafeineXWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CafeineXWidgetSnapshot
}

struct CafeineXWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CafeineXWidgetEntry {
        CafeineXWidgetEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (CafeineXWidgetEntry) -> Void
    ) {
        completion(CafeineXWidgetEntry(
            date: .now,
            snapshot: context.isPreview
                ? .preview
                : CafeineXWidgetStore.loadSnapshot()
        ))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<CafeineXWidgetEntry>) -> Void
    ) {
        let now = Date.now
        let snapshot = CafeineXWidgetStore.loadSnapshot()
        let refreshLimit = now.addingTimeInterval(2 * 60 * 60)
        var dates = stride(from: 0, through: 120, by: 30).map {
            now.addingTimeInterval(Double($0) * 60)
        }
        dates.append(contentsOf: [snapshot.cutoffTime, snapshot.bedtime].filter {
            $0 > now && $0 <= refreshLimit
        })
        let entries = Array(Set(dates))
            .sorted()
            .map { date in
                CafeineXWidgetEntry(
                    date: date,
                    snapshot: snapshot.projected(relativeTo: date)
                )
            }

        completion(Timeline(
            entries: entries,
            policy: .after(refreshLimit)
        ))
    }
}
