import SwiftUI
import WidgetKit

struct CafeineXWidgetPreviews: PreviewProvider {
    private static let entry = CafeineXWidgetEntry(
        date: .now,
        snapshot: .preview
    )

    static var previews: some View {
        Group {
            CafeineXOverviewEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Overview · Small")

            CafeineXOverviewEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Overview · Medium")

            CafeineXOverviewEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Overview · Large")

            CafeineXOverviewEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Lock Screen Inline")

            CafeineXOverviewEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Lock Screen Circular")

            CafeineXOverviewEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Lock Screen Rectangular")

            CafeineXQuickLogView(snapshot: entry.snapshot)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Quick Log")

        }
    }
}
