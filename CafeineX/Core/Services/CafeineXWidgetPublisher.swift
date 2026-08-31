import Foundation
import OSLog
import SwiftData

/// Reads the committed app store. Background intents do not depend on Home being mounted.
@MainActor
enum CafeineXWidgetPublisher {
    static func publish(context: ModelContext) {
        do {
            let snapshot = try makeSnapshot(context: context)
            CafeineXWidgetStore.saveSnapshot(snapshot)
        } catch {
            // A snapshot failure must not turn a successful log into a retryable write.
            Logger(subsystem: "beltradini.CafeineX", category: "Widgets")
                .error("Snapshot refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func makeSnapshot(
        context: ModelContext,
        now: Date = .now,
        schedule: SleepSchedule = SleepScheduleStore().schedule,
        sensitivity: CaffeineSensitivityProfile = CaffeineSensitivityStore().profile
    ) throws -> CafeineXWidgetSnapshot {
        let start = CaffeineHistoryPolicy.synchronizationStartDate(relativeTo: now)
        let entries = try context.fetch(FetchDescriptor<CaffeineEntry>(
            predicate: #Predicate { $0.consumedAt >= start && $0.consumedAt <= now }
        ))
        let nicotine = try context.fetch(FetchDescriptor<NicotineEntry>(
            predicate: #Predicate { $0.usedAt >= start && $0.usedAt <= now }
        ))
        let drinks = try context.fetch(FetchDescriptor<Drink>())
        let details = try context.fetch(FetchDescriptor<DrinkDetails>())
        let favorites = drinks.filter {
            $0.isFavorite && !(DrinkLibrary.existingDetails(for: $0, in: details)?.isArchived ?? false)
        }.sorted {
            let lhs = DrinkLibrary.existingDetails(for: $0, in: details)
            let rhs = DrinkLibrary.existingDetails(for: $1, in: details)
            if lhs?.favoriteOrder != rhs?.favoriteOrder {
                return (lhs?.favoriteOrder ?? .max) < (rhs?.favoriteOrder ?? .max)
            }
            return (lhs?.lastUsedAt ?? .distantPast) > (rhs?.lastUsedAt ?? .distantPast)
        }.prefix(4).map {
            WidgetFavoriteDrink(id: $0.id, name: $0.name, caffeineMG: $0.caffeineMG,
                                symbolName: $0.category.symbol)
        }
        let engine = CaffeineEngine(configuration: .init(sleepSchedule: schedule, sensitivity: sensitivity))
        let doses = entries.map(\.dose)
        let status = engine.makeStatus(doses: doses, currentDate: now)
        let duration = max(status.targetBedtime.timeIntervalSince(now), 0)
        let points: [WidgetActiveRangePoint] = entries.isEmpty ? [] : (0...6).map { index in
            let date = now.addingTimeInterval(duration * Double(index) / 6)
            let range = engine.estimateActiveCaffeineRange(doses: doses, currentDate: date)
            return WidgetActiveRangePoint(date: date, lowMG: range.lowerBound, highMG: range.upperBound)
        }
        let exposures = ExposureItem.combined(caffeineEntries: entries, nicotineEntries: nicotine)
            .sorted { $0.date > $1.date }.prefix(4).map {
                WidgetExposure(id: $0.modelID, kind: $0.kind == .caffeine ? .caffeine : .nicotine,
                               title: $0.title, amountText: $0.amountText, date: $0.date,
                               symbolName: $0.symbol)
            }
        return CafeineXWidgetSnapshot(
            generatedAt: now,
            activeCaffeineLowMG: entries.isEmpty ? nil : status.activeCaffeineLowMG,
            activeCaffeineHighMG: entries.isEmpty ? nil : status.activeCaffeineHighMG,
            caffeineTodayMG: status.consumedTodayMG,
            bedtime: status.targetBedtime, cutoffTime: status.suggestedCutoffTime,
            state: entries.isEmpty ? .noRecentData : (now >= status.suggestedCutoffTime ? .nearSleep : .withinWindow),
            recentExposures: exposures, favoriteDrinks: favorites, activeRangePoints: points
        )
    }
}
