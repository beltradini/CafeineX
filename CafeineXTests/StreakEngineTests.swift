import Foundation
import Testing
@testable import CafeineX

struct StreakEngineTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func awarenessAllowsTodayToRemainPendingWithoutBreakingYesterday() {
        let now = date(day: 10, hour: 12)
        let summary = StreakEngine().makeSummary(
            checkInDates: [
                date(day: 7, hour: 8),
                date(day: 8, hour: 8),
                date(day: 9, hour: 8),
            ],
            caffeineDates: [],
            sleepSchedule: .default,
            currentDate: now,
            calendar: calendar
        )

        #expect(summary.awarenessDays == 3)
        #expect(!summary.isTodayReviewed)
    }

    @Test func sleepProtectionRequiresReviewAndRejectsLateCaffeine() {
        let schedule = SleepSchedule(
            bedtimeHour: 22,
            bedtimeMinute: 0,
            cutoffHoursBeforeBedtime: 8
        )
        let summary = StreakEngine().makeSummary(
            checkInDates: [
                date(day: 7, hour: 8),
                date(day: 8, hour: 8),
                date(day: 9, hour: 8),
            ],
            caffeineDates: [
                date(day: 7, hour: 10),
                date(day: 8, hour: 15),
                date(day: 9, hour: 10),
            ],
            sleepSchedule: schedule,
            currentDate: date(day: 10, hour: 12),
            calendar: calendar
        )

        #expect(summary.sleepProtectionDays == 1)
    }

    @Test func missingDaysNeverCountAsSleepProtection() {
        let summary = StreakEngine().makeSummary(
            checkInDates: [],
            caffeineDates: [],
            sleepSchedule: .default,
            currentDate: date(day: 10, hour: 12),
            calendar: calendar
        )

        #expect(summary.awarenessDays == 0)
        #expect(summary.sleepProtectionDays == 0)
        #expect(!summary.isTodaySleepProtectedSoFar)
    }

    @Test func bestStreakPreservesHistoryAfterAGap() {
        let summary = StreakEngine().makeSummary(
            checkInDates: [
                date(day: 1, hour: 8),
                date(day: 2, hour: 8),
                date(day: 3, hour: 8),
                date(day: 8, hour: 8),
                date(day: 9, hour: 8),
            ],
            caffeineDates: [],
            sleepSchedule: .default,
            currentDate: date(day: 10, hour: 12),
            calendar: calendar
        )

        #expect(summary.awarenessDays == 2)
        #expect(summary.sleepProtectionDays == 2)
        #expect(summary.bestAwarenessDays == 3)
        #expect(summary.bestSleepProtectionDays == 3)
    }

    private func date(day: Int, hour: Int) -> Date {
        calendar.date(
            from: DateComponents(year: 2026, month: 7, day: day, hour: hour)
        )!
    }
}
