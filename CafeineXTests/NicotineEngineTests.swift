import Foundation
import Testing
@testable import CafeineX

struct NicotineEngineTests {
    private let engine = NicotineEngine()

    @Test func quantitiesRemainSeparatedByUnit() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let events = [
            NicotineEvent(
                id: UUID(),
                product: .pouch,
                quantity: 6,
                unit: .milligrams,
                usedAt: now.addingTimeInterval(-1_800)
            ),
            NicotineEvent(
                id: UUID(),
                product: .cigarette,
                quantity: 2,
                unit: .pieces,
                usedAt: now.addingTimeInterval(-1_200)
            ),
            NicotineEvent(
                id: UUID(),
                product: .vape,
                quantity: 8,
                unit: .puffs,
                usedAt: now.addingTimeInterval(-600)
            ),
        ]

        let status = engine.makeStatus(events: events, currentDate: now)

        #expect(status.amountsToday.milligrams == 6)
        #expect(status.amountsToday.pieces == 2)
        #expect(status.amountsToday.puffs == 8)
    }

    @Test func futureEventsDoNotAffectTodayOrActiveWindows() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let futureEvent = NicotineEvent(
            id: UUID(),
            product: .vape,
            quantity: 10,
            unit: .puffs,
            usedAt: now.addingTimeInterval(3_600)
        )

        let status = engine.makeStatus(events: [futureEvent], currentDate: now)

        #expect(status.eventsToday == 0)
        #expect(status.activeEventCount == 0)
        #expect(status.latestEventAt == nil)
    }

    @Test func patchUsesLongerObservationWindow() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let event = NicotineEvent(
            id: UUID(),
            product: .patch,
            quantity: 14,
            unit: .milligrams,
            usedAt: now.addingTimeInterval(-12 * 3_600)
        )

        let status = engine.makeStatus(events: [event], currentDate: now)

        #expect(status.activeEventCount == 1)
    }

    @Test func eventWithinFourHoursOfBedtimeProducesSleepGuidance() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 28, hour: 20)
        )!
        let event = NicotineEvent(
            id: UUID(),
            product: .pouch,
            quantity: 4,
            unit: .milligrams,
            usedAt: now.addingTimeInterval(-30 * 60)
        )

        let status = engine.makeStatus(
            events: [event],
            currentDate: now,
            calendar: calendar
        )

        #expect(status.sleepGuidance == .nearBedtime)
        #expect(status.suggestedPauseTime == now.addingTimeInterval(-2 * 3_600))
    }

    @Test func activePatchFromPreviousDayCanStillProduceSleepGuidance() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 28, hour: 20)
        )!
        let patch = NicotineEvent(
            id: UUID(),
            product: .patch,
            quantity: 14,
            unit: .milligrams,
            usedAt: now.addingTimeInterval(-22 * 3_600)
        )

        let status = engine.makeStatus(
            events: [patch],
            currentDate: now,
            calendar: calendar
        )

        #expect(status.eventsToday == 0)
        #expect(status.activeEventCount == 1)
        #expect(status.sleepGuidance == .nearBedtime)
    }
}
