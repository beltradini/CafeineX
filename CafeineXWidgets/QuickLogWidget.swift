import AppIntents
import SwiftUI
import WidgetKit

struct CafeineXQuickLogWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: CafeineXWidgetConstants.quickLogKind,
            provider: CafeineXWidgetProvider()
        ) { entry in
            CafeineXQuickLogView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Quick Log")
        .description("Record one of your favorite drinks.")
        .supportedFamilies([.systemSmall])
    }
}

struct CafeineXQuickLogView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Log")
                .font(.headline)

            if snapshot.favoriteDrinks.isEmpty {
                noFavorites
            } else {
                favoriteRows
            }
        }
        .containerBackground(for: .widget) {
            CafeineXWidgetBackground()
        }
        .widgetURL(URL(string: "cafeinex://quick-add"))
    }

    private var favoriteRows: some View {
        let favorites = Array(snapshot.favoriteDrinks.prefix(2))

        return VStack(spacing: 0) {
            ForEach(Array(favorites.enumerated()), id: \.element.id) { index, drink in
                CafeineXFavoriteButton(drink: drink)
                    .privacySensitive()

                if index < favorites.count - 1 {
                    Divider()
                }
            }
        }
    }

    private var noFavorites: some View {
        Link(destination: URL(string: "cafeinex://quick-add")!) {
            VStack(alignment: .leading, spacing: 5) {
                Spacer(minLength: 0)

                Text("No favorites yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Choose drinks in CafeineX")
                    .font(.caption)
                    .foregroundStyle(CafeineXWidgetPalette.caffeine)
                    .widgetAccentable()

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open CafeineX to choose favorite drinks")
    }
}
