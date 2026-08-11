import AppIntents
import SwiftUI
import WidgetKit

enum CafeineXWidgetPalette {
    static let caffeine = Color(red: 1.00, green: 0.56, blue: 0.18)
    static let nicotine = Color(red: 0.58, green: 0.43, blue: 1.00)
    static let sleep = Color(red: 0.23, green: 0.78, blue: 0.76)
    static let warmDark = Color(red: 0.13, green: 0.08, blue: 0.05)
    static let deepDark = Color(red: 0.025, green: 0.035, blue: 0.045)
    static let petroleum = Color(red: 0.02, green: 0.15, blue: 0.15)
}

struct CafeineXWidgetBackground: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch renderingMode {
        case .fullColor:
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .accented, .vibrant:
            Color.clear
        default:
            Color.clear
        }
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                CafeineXWidgetPalette.warmDark,
                CafeineXWidgetPalette.deepDark,
                CafeineXWidgetPalette.petroleum,
            ]
        }

        return [
            Color(red: 1.00, green: 0.96, blue: 0.91),
            Color(red: 0.95, green: 0.98, blue: 0.97),
            Color(red: 0.89, green: 0.96, blue: 0.95),
        ]
    }
}

struct CafeineXBrandMark: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            Image(systemName: "sparkles")
                .foregroundStyle(CafeineXWidgetPalette.caffeine)
                .widgetAccentable()
                .accessibilityHidden(true)

            Text("CafeineX")
                .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

struct CafeineXStateLabel: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let snapshot: CafeineXWidgetSnapshot
    var compact = false

    var body: some View {
        Label(statusTitle, systemImage: statusSymbol)
            .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            .foregroundStyle(statusColor)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .widgetAccentable()
            .accessibilityLabel(statusTitle)
    }

    private var statusTitle: String {
        snapshot.isStale() ? "Data may be outdated" : snapshot.state.title
    }

    private var statusSymbol: String {
        snapshot.isStale() ? "clock.badge.exclamationmark" : snapshot.state.symbolName
    }

    private var statusColor: Color {
        guard !snapshot.isStale() else { return .secondary }

        guard renderingMode == .fullColor else {
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

struct CafeineXTimelineBar: View {
    let snapshot: CafeineXWidgetSnapshot

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { proxy in
                let progress = snapshot.sleepProgress()

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.2))

                    Capsule()
                        .fill(CafeineXWidgetPalette.sleep)
                        .frame(width: max(proxy.size.width * progress, 6))
                        .widgetAccentable()

                    Circle()
                        .fill(.primary)
                        .frame(width: 7, height: 7)
                        .offset(x: max(min(proxy.size.width * progress - 3.5, proxy.size.width - 7), 0))
                }
            }
            .frame(height: 5)

            HStack {
                Text("Now")
                Spacer()
                Text("Sleep \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Now to configured sleep time, \(snapshot.bedtime.formatted(date: .omitted, time: .shortened))"
        )
    }
}

struct CafeineXFavoriteButton: View {
    let drink: WidgetFavoriteDrink
    var compact = false

    var body: some View {
        Button(intent: LogFavoriteDrinkIntent(
            name: drink.name,
            caffeineMG: drink.caffeineMG
        )) {
            HStack(spacing: compact ? 5 : 7) {
                Image(systemName: drink.symbolName)
                    .foregroundStyle(CafeineXWidgetPalette.caffeine)
                    .widgetAccentable()

                VStack(alignment: .leading, spacing: 0) {
                    Text(drink.name)
                        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                        .lineLimit(1)
                    if !compact {
                        Text("\(Int(drink.caffeineMG.rounded())) mg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "plus.circle.fill")
                    .imageScale(.small)
                    .foregroundStyle(CafeineXWidgetPalette.caffeine)
                    .widgetAccentable()
            }
            .padding(.horizontal, compact ? 8 : 10)
            .frame(maxWidth: .infinity, minHeight: compact ? 28 : 34)
            .background(.secondary.opacity(0.14), in: ContainerRelativeShape())
        }
        .buttonStyle(.plain)
        .invalidatableContent()
        .accessibilityLabel("Log \(drink.name), \(Int(drink.caffeineMG.rounded())) milligrams")
    }
}

extension WidgetExposure {
    var accentColor: Color {
        kind == .caffeine
            ? CafeineXWidgetPalette.caffeine
            : CafeineXWidgetPalette.nicotine
    }
}
