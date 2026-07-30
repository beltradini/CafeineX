import Foundation
import Testing
@testable import CafeineX

struct WeeklySummaryEngineTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    @Test func summaryRespectsWeekBoundariesCutoffAndCurrentTime() {
        let now = date(day: 29, hour: 12)
        let schedule = SleepSchedule(
            bedtimeHour: 22,
            bedtimeMinute: 0,
            cutoffHoursBeforeBedtime: 8
        )
        let summary = WeeklySummaryEngine().makeSummary(
            caffeineDoses: [
                CaffeineDose(amountMG: 300, consumedAt: date(day: 24, hour: 10)),
                CaffeineDose(amountMG: 100, consumedAt: date(day: 27, hour: 9)),
                CaffeineDose(amountMG: 150, consumedAt: date(day: 28, hour: 16)),
                CaffeineDose(amountMG: 50, consumedAt: date(day: 29, hour: 13)),
            ],
            nicotineEvents: [
                nicotineEvent(day: 28, hour: 11),
            ],
            checkInDates: [
                date(day: 27, hour: 20),
                date(day: 28, hour: 20),
            ],
            sleepSchedule: schedule,
            currentDate: now,
            calendar: calendar
        )

        #expect(summary.caffeineMG == 250)
        #expect(summary.previousWeekCaffeineMG == 300)
        #expect(summary.caffeineEvents == 2)
        #expect(summary.nicotineEvents == 1)
        #expect(summary.trackedDays == 2)
        #expect(summary.reviewedDays == 2)
        #expect(summary.sleepProtectedDays == 1)
        #expect(summary.lateCaffeineEvents == 1)
        #expect(summary.elapsedDays == 3)
        #expect(summary.completedDays == 2)
        #expect(summary.progress(for: .protectSleep).completedDays == 1)
        #expect(summary.progress(for: .protectSleep).availableDays == 2)
        #expect(summary.progress(for: .mindfulTracking).completedDays == 2)
        #expect(summary.progress(for: .mindfulTracking).availableDays == 3)
    }

    @Test func firstDayOfWeekNeverInventsCompletedGoalProgress() {
        let summary = WeeklySummaryEngine().makeSummary(
            caffeineDoses: [],
            nicotineEvents: [],
            checkInDates: [],
            sleepSchedule: .default,
            currentDate: date(day: 27, hour: 8),
            calendar: calendar
        )

        let progress = summary.progress(for: .protectSleep)
        #expect(summary.elapsedDays == 1)
        #expect(summary.completedDays == 0)
        #expect(progress.availableDays == 0)
        #expect(progress.fraction == 0)
    }

    private func date(day: Int, hour: Int) -> Date {
        calendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: day,
                hour: hour
            )
        )!
    }

    private func nicotineEvent(day: Int, hour: Int) -> NicotineEvent {
        NicotineEvent(
            id: UUID(),
            product: .pouch,
            quantity: 2,
            unit: .milligrams,
            usedAt: date(day: day, hour: hour)
        )
    }
}
