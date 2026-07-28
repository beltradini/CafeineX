import Foundation
import Testing
@testable import CafeineX

struct DailyExposureContextTests {
    @Test func overlappingObservationWindowsAreCountedWithoutCombiningAmounts() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 28, hour: 14)
        )!
        let caffeine = CaffeineDose(
            amountMG: 120,
            consumedAt: now.addingTimeInterval(-4 * 3_600)
        )
        let nicotine = NicotineEvent(
            id: UUID(),
            product: .vape,
            quantity: 6,
            unit: .puffs,
            usedAt: now.addingTimeInterval(-2 * 3_600)
        )

        let context = DailyExposureContext.make(
            caffeineDoses: [caffeine],
            nicotineEvents: [nicotine],
            currentDate: now,
            calendar: calendar
        )

        #expect(context.temporalOverlapCount == 1)
        #expect(context.hasTemporalOverlap)
        #expect(context.guidance == .temporalOverlap)
        #expect(context.caffeineStatus.consumedTodayMG == 120)
        #expect(context.nicotineStatus.amountsToday.puffs == 6)
    }

    @Test func separatedWindowsDoNotProduceAnOverlap() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 28, hour: 15)
        )!
        let caffeine = CaffeineDose(
            amountMG: 80,
            consumedAt: now.addingTimeInterval(-9 * 3_600)
        )
        let nicotine = NicotineEvent(
            id: UUID(),
            product: .cigarette,
            quantity: 1,
            unit: .pieces,
            usedAt: now.addingTimeInterval(-2 * 3_600)
        )

        let context = DailyExposureContext.make(
            caffeineDoses: [caffeine],
            nicotineEvents: [nicotine],
            currentDate: now,
            calendar: calendar
        )

        #expect(context.temporalOverlapCount == 0)
        #expect(!context.hasTemporalOverlap)
    }

    @Test func nicotineNearBedtimeTakesSleepPriorityOverOverlapGuidance() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 28, hour: 20)
        )!
        let caffeine = CaffeineDose(
            amountMG: 50,
            consumedAt: now.addingTimeInterval(-60 * 60)
        )
        let nicotine = NicotineEvent(
            id: UUID(),
            product: .pouch,
            quantity: 4,
            unit: .milligrams,
            usedAt: now.addingTimeInterval(-30 * 60)
        )

        let context = DailyExposureContext.make(
            caffeineDoses: [caffeine],
            nicotineEvents: [nicotine],
            currentDate: now,
            calendar: calendar
        )

        #expect(context.temporalOverlapCount == 1)
        #expect(context.nicotineStatus.sleepGuidance == .nearBedtime)
        #expect(context.guidance == .sleepPriority)
    }

    @Test func overlapsFromPreviousDaysAreNotCountedInDailyContext() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 28, hour: 12)
        )!
        let oldCaffeine = CaffeineDose(
            amountMG: 120,
            consumedAt: now.addingTimeInterval(-30 * 3_600)
        )
        let oldNicotine = NicotineEvent(
            id: UUID(),
            product: .vape,
            quantity: 5,
            unit: .puffs,
            usedAt: now.addingTimeInterval(-29 * 3_600)
        )

        let context = DailyExposureContext.make(
            caffeineDoses: [oldCaffeine],
            nicotineEvents: [oldNicotine],
            currentDate: now,
            calendar: calendar
        )

        #expect(context.temporalOverlapCount == 0)
        #expect(context.guidance == .clear)
    }
}
