//
//  CafeineXWidgetSnapshot.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/10/26.
//

import Foundation

nonisolated enum CafeineXWidgetConstants {
    static let appGroupID = "group.beltradini.CafeineX"
    static let snapshotKey = "cafeinex.widget.snapshot"
    static let commandKey = "cafeinex.widget.pending-command"

    // Preserve the original kind so installed Active Window widgets migrate
    // to the redesigned Overview configuration without being invalidated.
    static let overviewKind = "CafeineX.ActiveWindow"
    static let quickLogKind = "CafeineX.QuickLog"

    static let widgetKinds = [
        overviewKind,
        quickLogKind,
    ]
}

nonisolated struct CafeineXWidgetSnapshot: Codable, Sendable {
    let generatedAt: Date
    let activeCaffeineLowMG: Double?
    let activeCaffeineHighMG: Double?
    let caffeineTodayMG: Double
    let bedtime: Date
    let cutoffTime: Date
    let state: WidgetWindowState
    let recentExposures: [WidgetExposure]
    let favoriteDrinks: [WidgetFavoriteDrink]
    let activeRangePoints: [WidgetActiveRangePoint]

    static let empty = CafeineXWidgetSnapshot(
        generatedAt: .now,
        activeCaffeineLowMG: nil,
        activeCaffeineHighMG: nil,
        caffeineTodayMG: 0,
        bedtime: .now,
        cutoffTime: .now,
        state: .noRecentData,
        recentExposures: [],
        favoriteDrinks: [],
        activeRangePoints: []
    )

    var activeRangeText: String {
        guard let low = activeCaffeineLowMG,
              let high = activeCaffeineHighMG else {
            return "—"
        }

        let roundedLow = Int(low.rounded())
        let roundedHigh = Int(high.rounded())
        if roundedLow == roundedHigh {
            return "\(roundedLow) mg"
        }
        return "\(roundedLow)–\(roundedHigh) mg"
    }

    func isStale(relativeTo date: Date = .now) -> Bool {
        date.timeIntervalSince(generatedAt) > 2 * 60 * 60
    }

    func sleepProgress(relativeTo date: Date = .now) -> Double {
        let start = bedtime.addingTimeInterval(-12 * 60 * 60)
        let duration = bedtime.timeIntervalSince(start)
        guard duration > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / duration, 0), 1)
    }

    func projected(relativeTo date: Date) -> CafeineXWidgetSnapshot {
        let projectedRange = interpolatedActiveRange(relativeTo: date)
        let hasRecentCaffeine = recentExposures.contains { exposure in
            exposure.kind == .caffeine
                && date.timeIntervalSince(exposure.date) <= 24 * 60 * 60
        }
        let projectedState: WidgetWindowState
        if !hasRecentCaffeine {
            projectedState = .noRecentData
        } else if date >= cutoffTime {
            projectedState = .nearSleep
        } else {
            projectedState = .withinWindow
        }

        return CafeineXWidgetSnapshot(
            generatedAt: generatedAt,
            activeCaffeineLowMG: projectedRange?.low,
            activeCaffeineHighMG: projectedRange?.high,
            caffeineTodayMG: caffeineTodayMG,
            bedtime: bedtime,
            cutoffTime: cutoffTime,
            state: projectedState,
            recentExposures: recentExposures,
            favoriteDrinks: favoriteDrinks,
            activeRangePoints: activeRangePoints
        )
    }

    private func interpolatedActiveRange(
        relativeTo date: Date
    ) -> (low: Double, high: Double)? {
        let points = activeRangePoints.sorted { $0.date < $1.date }
        guard let first = points.first else {
            guard let low = activeCaffeineLowMG,
                  let high = activeCaffeineHighMG else {
                return nil
            }
            return (low, high)
        }

        guard date > first.date else {
            return (first.lowMG, first.highMG)
        }
        guard let last = points.last else {
            return (first.lowMG, first.highMG)
        }
        guard date < last.date else {
            return (last.lowMG, last.highMG)
        }

        guard let upperIndex = points.firstIndex(where: { $0.date >= date }),
              upperIndex > points.startIndex else {
            return (first.lowMG, first.highMG)
        }

        let lower = points[points.index(before: upperIndex)]
        let upper = points[upperIndex]
        let interval = upper.date.timeIntervalSince(lower.date)
        guard interval > 0 else {
            return (upper.lowMG, upper.highMG)
        }

        let progress = date.timeIntervalSince(lower.date) / interval
        return (
            lower.lowMG + (upper.lowMG - lower.lowMG) * progress,
            lower.highMG + (upper.highMG - lower.highMG) * progress
        )
    }

    static let preview: CafeineXWidgetSnapshot = {
        let now = Date.now
        let bedtime = Calendar.current.date(
            bySettingHour: 22,
            minute: 0,
            second: 0,
            of: now
        ) ?? now.addingTimeInterval(8 * 60 * 60)
        let resolvedBedtime = bedtime > now
            ? bedtime
            : bedtime.addingTimeInterval(24 * 60 * 60)
        let pointDates = (0...6).map {
            now.addingTimeInterval(
                resolvedBedtime.timeIntervalSince(now) * Double($0) / 6
            )
        }

        return CafeineXWidgetSnapshot(
            generatedAt: now,
            activeCaffeineLowMG: 59,
            activeCaffeineHighMG: 62,
            caffeineTodayMG: 150,
            bedtime: resolvedBedtime,
            cutoffTime: resolvedBedtime.addingTimeInterval(-8 * 60 * 60),
            state: .withinWindow,
            recentExposures: [
                WidgetExposure(
                    id: UUID(),
                    kind: .caffeine,
                    title: "Espresso",
                    amountText: "64 mg",
                    date: now.addingTimeInterval(-20 * 60),
                    symbolName: "cup.and.saucer.fill"
                ),
                WidgetExposure(
                    id: UUID(),
                    kind: .nicotine,
                    title: "Cigarette",
                    amountText: "1 cigarette",
                    date: now.addingTimeInterval(-95 * 60),
                    symbolName: "smoke.fill"
                ),
            ],
            favoriteDrinks: [
                WidgetFavoriteDrink(
                    id: UUID(),
                    name: "Espresso",
                    caffeineMG: 64,
                    symbolName: "cup.and.saucer.fill"
                ),
                WidgetFavoriteDrink(
                    id: UUID(),
                    name: "Americano",
                    caffeineMG: 150,
                    symbolName: "mug.fill"
                ),
            ],
            activeRangePoints: pointDates.enumerated().map { index, date in
                let factor = pow(0.78, Double(index))
                return WidgetActiveRangePoint(
                    date: date,
                    lowMG: 59 * factor,
                    highMG: 62 * factor
                )
            }
        )
    }()
}

extension CafeineXWidgetSnapshot {
    private enum CodingKeys: String, CodingKey {
        case generatedAt
        case activeCaffeineLowMG
        case activeCaffeineHighMG
        case caffeineTodayMG
        case bedtime
        case cutoffTime
        case state
        case recentExposures
        case favoriteDrinks
        case activeRangePoints
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        activeCaffeineLowMG = try container.decodeIfPresent(
            Double.self,
            forKey: .activeCaffeineLowMG
        )
        activeCaffeineHighMG = try container.decodeIfPresent(
            Double.self,
            forKey: .activeCaffeineHighMG
        )
        caffeineTodayMG = try container.decode(Double.self, forKey: .caffeineTodayMG)
        bedtime = try container.decode(Date.self, forKey: .bedtime)
        cutoffTime = try container.decode(Date.self, forKey: .cutoffTime)
        state = try container.decode(WidgetWindowState.self, forKey: .state)
        recentExposures = try container.decode([WidgetExposure].self, forKey: .recentExposures)
        favoriteDrinks = try container.decode([WidgetFavoriteDrink].self, forKey: .favoriteDrinks)
        activeRangePoints = try container.decodeIfPresent(
            [WidgetActiveRangePoint].self,
            forKey: .activeRangePoints
        ) ?? []
    }
}

nonisolated enum WidgetWindowState: String, Codable, Sendable {
    case withinWindow
    case nearSleep
    case noRecentData

    var title: String {
        switch self {
        case .withinWindow:
            "Before your cutoff"
        case .nearSleep:
            "Near your sleep time"
        case .noRecentData:
            "No recent caffeine"
        }
    }

    var symbolName: String {
        switch self {
        case .withinWindow:
            "clock.fill"
        case .nearSleep:
            "moon.zzz.fill"
        case .noRecentData:
            "questionmark.circle.fill"
        }
    }
}

nonisolated enum WidgetExposureKind: String, Codable, Sendable {
    case caffeine
    case nicotine
}

nonisolated struct WidgetExposure: Codable, Identifiable, Sendable {
    let id: UUID
    let kind: WidgetExposureKind
    let title: String
    let amountText: String
    let date: Date
    let symbolName: String
}

extension WidgetExposure {
    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case amountText
        case date
        case symbolName
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amountText = try container.decode(String.self, forKey: .amountText)
        date = try container.decode(Date.self, forKey: .date)
        symbolName = try container.decode(String.self, forKey: .symbolName)
        kind = try container.decodeIfPresent(
            WidgetExposureKind.self,
            forKey: .kind
        ) ?? (symbolName.contains("smoke") ? .nicotine : .caffeine)
    }
}

nonisolated struct WidgetActiveRangePoint: Codable, Identifiable, Sendable {
    var id: Date { date }

    let date: Date
    let lowMG: Double
    let highMG: Double
}

nonisolated struct WidgetFavoriteDrink: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let caffeineMG: Double
    let symbolName: String
}
