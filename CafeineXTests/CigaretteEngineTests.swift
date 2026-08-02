import Foundation
import Testing
@testable import CafeineX

struct CigaretteEngineTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func summarizesCountGapsContextAndCaffeinePairings() throws {
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 31, hour: 18
        )))
        let events = [
            CigaretteEvent(id: UUID(), usedAt: now.addingTimeInterval(-8 * 3_600), quantity: 1, context: .withCoffee),
            CigaretteEvent(id: UUID(), usedAt: now.addingTimeInterval(-6 * 3_600), quantity: 1, context: .afterMeal),
            CigaretteEvent(id: UUID(), usedAt: now.addingTimeInterval(-2 * 3_600), quantity: 1, context: .withCoffee),
        ]
        let caffeine = [
            CaffeineDose(amountMG: 80, consumedAt: events[0].usedAt.addingTimeInterval(10 * 60)),
            CaffeineDose(amountMG: 40, consumedAt: events[2].usedAt.addingTimeInterval(-20 * 60)),
        ]

        let summary = CigaretteEngine().makeSummary(
            cigaretteEvents: events,
            caffeineDoses: caffeine,
            currentDate: now,
            calendar: calendar
        )

        #expect(summary.cigarettesToday == 3)
        #expect(summary.eventsToday == 3)
        #expect(abs((summary.averageGap ?? 0) - 3 * 3_600) < 0.001)
        #expect(abs((summary.longestGap ?? 0) - 4 * 3_600) < 0.001)
        #expect(summary.caffeinePairingsToday == 2)
        #expect(summary.mostFrequentContext == .withCoffee)
    }

    @Test func sleepProtectionUsesNextBedtimeAcrossMidnight() throws {
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 31, hour: 21
        )))
        let nearBedtime = now.addingTimeInterval(90 * 60)
        let event = CigaretteEvent(
            id: UUID(),
            usedAt: nearBedtime,
            quantity: 1,
            context: .beforeSleep
        )
        let schedule = SleepSchedule(
            bedtimeHour: 23,
            bedtimeMinute: 30,
            cutoffHoursBeforeBedtime: 8
        )
        let engine = CigaretteEngine(configuration: .init(
            pairingWindow: 30 * 60,
            sleepProtectionWindow: 4 * 3_600,
            sleepSchedule: schedule
        ))

        let summary = engine.makeSummary(
            cigaretteEvents: [event],
            caffeineDoses: [],
            currentDate: nearBedtime,
            calendar: calendar
        )

        #expect(summary.sleepWindowEventsToday == 1)
    }

    @Test func futureEventsNeverInfluenceSummary() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let future = CigaretteEvent(
            id: UUID(),
            usedAt: now.addingTimeInterval(60),
            quantity: 12,
            context: .stress
        )

        let summary = CigaretteEngine().makeSummary(
            cigaretteEvents: [future],
            caffeineDoses: [],
            currentDate: now,
            calendar: calendar
        )

        #expect(summary.eventsToday == 0)
        #expect(summary.cigarettesToday == 0)
        #expect(summary.latestEventAt == nil)
    }
}
