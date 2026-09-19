import SwiftUI
import WidgetKit

struct CafeineXWidgetPreviews: PreviewProvider {
    private static let currentEntry = CafeineXWidgetEntry(
        date: .now,
        snapshot: .preview
    )

    private static let staleEntry = CafeineXWidgetEntry(
        date: .now,
        snapshot: makeSnapshot(
            generatedAt: .now.addingTimeInterval(-3 * 60 * 60)
        )
    )

    private static let emptySnapshot = makeSnapshot(
        activeCaffeineLowMG: nil,
        activeCaffeineHighMG: nil,
        caffeineTodayMG: 0,
        state: .noRecentData,
        recentExposures: [],
        activeRangePoints: []
    )

    private static let noFavoritesSnapshot = makeSnapshot(
        favoriteDrinks: []
    )

    static var previews: some View {
        Group {
            CafeineXActiveWindowEntryView(entry: currentEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Active Window · Current")

            CafeineXActiveWindowEntryView(entry: staleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Active Window · Stale")

            CafeineXActiveWindowEntryView(entry: currentEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Active Window · Inline")

            CafeineXActiveWindowEntryView(entry: currentEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Active Window · Circular")

            CafeineXActiveWindowEntryView(entry: currentEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Active Window · Rectangular")

            CafeineXQuickLogView(snapshot: currentEntry.snapshot)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Quick Log · Favorites")

            CafeineXQuickLogView(snapshot: noFavoritesSnapshot)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Quick Log · Empty")

            CafeineXTodayView(snapshot: currentEntry.snapshot)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Today · Current")

            CafeineXTodayView(snapshot: emptySnapshot)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Today · Empty")

            CafeineXDailyRhythmView(snapshot: currentEntry.snapshot)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Daily Rhythm · Current")

            CafeineXDailyRhythmView(snapshot: emptySnapshot)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Daily Rhythm · Empty")
        }
    }

    private static func makeSnapshot(
        generatedAt: Date = CafeineXWidgetSnapshot.preview.generatedAt,
        activeCaffeineLowMG: Double? = CafeineXWidgetSnapshot.preview.activeCaffeineLowMG,
        activeCaffeineHighMG: Double? = CafeineXWidgetSnapshot.preview.activeCaffeineHighMG,
        caffeineTodayMG: Double = CafeineXWidgetSnapshot.preview.caffeineTodayMG,
        state: WidgetWindowState = CafeineXWidgetSnapshot.preview.state,
        recentExposures: [WidgetExposure] = CafeineXWidgetSnapshot.preview.recentExposures,
        favoriteDrinks: [WidgetFavoriteDrink] = CafeineXWidgetSnapshot.preview.favoriteDrinks,
        activeRangePoints: [WidgetActiveRangePoint] = CafeineXWidgetSnapshot.preview.activeRangePoints
    ) -> CafeineXWidgetSnapshot {
        CafeineXWidgetSnapshot(
            generatedAt: generatedAt,
            activeCaffeineLowMG: activeCaffeineLowMG,
            activeCaffeineHighMG: activeCaffeineHighMG,
            caffeineTodayMG: caffeineTodayMG,
            bedtime: CafeineXWidgetSnapshot.preview.bedtime,
            cutoffTime: CafeineXWidgetSnapshot.preview.cutoffTime,
            state: state,
            recentExposures: recentExposures,
            favoriteDrinks: favoriteDrinks,
            activeRangePoints: activeRangePoints
        )
    }
}
