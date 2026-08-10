import Foundation
import Testing
@testable import CafeineX

struct NotificationPolicyTests {
    @Test
    func calculatesReviewBeforeBedtime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(
            calendar: calendar,
            year: 2026,
            month: 8,
            day: 10,
            hour: 9,
            minute: 0
        ))!

        let time = NotificationPolicy.sleepReviewTime(
            schedule: SleepSchedule(
                bedtimeHour: 22,
                bedtimeMinute: 0,
                cutoffHoursBeforeBedtime: 8
            ),
            calendar: calendar,
            relativeTo: date
        )

        #expect(time.hour == 14)
        #expect(time.minute == 0)
    }

    @Test
    func calculatesReviewForBedtimeAfterMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(
            calendar: calendar,
            year: 2026,
            month: 8,
            day: 10,
            hour: 9,
            minute: 0
        ))!

        let time = NotificationPolicy.sleepReviewTime(
            schedule: SleepSchedule(
                bedtimeHour: 1,
                bedtimeMinute: 0,
                cutoffHoursBeforeBedtime: 8
            ),
            calendar: calendar,
            relativeTo: date
        )

        #expect(time.hour == 17)
        #expect(time.minute == 0)
    }
}

