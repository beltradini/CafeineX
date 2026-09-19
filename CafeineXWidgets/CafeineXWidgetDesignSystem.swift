import AppIntents
import SwiftUI
import WidgetKit

enum CafeineXWidgetPalette {
    static let caffeine = Color(red: 1.00, green: 0.56, blue: 0.18)
    static let nicotine = Color(red: 0.58, green: 0.43, blue: 1.00)
    static let sleep = Color(red: 0.23, green: 0.78, blue: 0.76)

    static let lightBackground = Color(red: 0.985, green: 0.975, blue: 0.96)
    static let darkBackground = Color(red: 0.045, green: 0.05, blue: 0.06)
}

/// A quiet canvas that keeps CafeineX recognizable in full color and lets the
/// system supply tinted, clear, vibrant, StandBy, and Lock Screen materials.
struct CafeineXWidgetBackground: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        switch renderingMode {
        case .fullColor:
            if isLuminanceReduced {
                CafeineXWidgetPalette.darkBackground
            } else {
                ZStack {
                    colorScheme == .dark
                        ? CafeineXWidgetPalette.darkBackground
                        : CafeineXWidgetPalette.lightBackground

                    LinearGradient(
                        colors: [
                            CafeineXWidgetPalette.caffeine.opacity(colorScheme == .dark ? 0.10 : 0.07),
                            .clear,
                            CafeineXWidgetPalette.sleep.opacity(colorScheme == .dark ? 0.07 : 0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        case .accented, .vibrant:
            Color.clear
        default:
            Color.clear
        }
    }
}

struct CafeineXStateLabel: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        Label(snapshot.state.title, systemImage: snapshot.state.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(statusColor)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .widgetAccentable()
            .accessibilityLabel(snapshot.state.title)
    }

    private var statusColor: Color {
        guard renderingMode == .fullColor, !isLuminanceReduced else {
            return .primary
        }

        switch snapshot.state {
        case .withinWindow:
            return CafeineXWidgetPalette.sleep
        case .nearSleep:
            return CafeineXWidgetPalette.caffeine
        case .noRecentData:
            return .secondary
        }
    }
}

struct CafeineXFreshnessLabel: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        if snapshot.isStale() {
            Label {
                HStack(spacing: 3) {
                    Text("Updated")
                    Text(snapshot.generatedAt, style: .relative)
                }
            } icon: {
                Image(systemName: "clock.badge.exclamationmark")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .accessibilityElement(children: .combine)
        }
    }
}

struct CafeineXFavoriteButton: View {
    let drink: WidgetFavoriteDrink

    var body: some View {
        Button(intent: LogFavoriteDrinkIntent(
            name: drink.name,
            caffeineMG: drink.caffeineMG
        )) {
            HStack(spacing: 8) {
                Text(drink.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CafeineXWidgetPalette.caffeine)
                    .lineLimit(1)
                    .widgetAccentable()

                Spacer(minLength: 8)

                Text("\(Int(drink.caffeineMG.rounded())) mg")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .invalidatableContent()
        .accessibilityLabel("Log \(drink.name), \(Int(drink.caffeineMG.rounded())) milligrams")
        .accessibilityHint("Records this favorite in CafeineX")
    }
}

extension WidgetExposure {
    var accentColor: Color {
        kind == .caffeine
            ? CafeineXWidgetPalette.caffeine
            : CafeineXWidgetPalette.nicotine
    }
}
