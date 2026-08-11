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
        .description("Record a favorite drink with one tap.")
        .supportedFamilies([.systemSmall])
    }
}

struct CafeineXQuickLogView: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Quick Log", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("Favorites")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if snapshot.favoriteDrinks.isEmpty {
                noFavorites
            } else {
                ForEach(snapshot.favoriteDrinks.prefix(2)) { drink in
                    CafeineXFavoriteButton(drink: drink)
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            CafeineXWidgetBackground()
        }
        .widgetURL(URL(string: "cafeinex://quick-add"))
    }

    private var noFavorites: some View {
        Link(destination: URL(string: "cafeinex://quick-add")!) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "cup.and.saucer")
                    .font(.title2)
                    .foregroundStyle(CafeineXWidgetPalette.caffeine)
                    .widgetAccentable()
                Text("Choose a favorite drink")
                    .font(.headline)
                Text("Open CafeineX to configure Quick Log.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
