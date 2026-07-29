import Foundation

nonisolated struct StreakSummary: Equatable, Sendable {
    let awarenessDays: Int
    let sleepProtectionDays: Int
    let isTodayReviewed: Bool
    let isTodaySleepProtectedSoFar: Bool
}

nonisolated struct StreakEngine: Sendable {
    func makeSummary(
        checkInDates: [Date],
        caffeineDates: [Date],
        sleepSchedule: SleepSchedule,
        currentDate: Date = .now,
        calendar: Calendar = .current
    ) -> StreakSummary {
        let checkedDays = Set(checkInDates.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: currentDate)
        let isTodayReviewed = checkedDays.contains(today)

        let awarenessDays = consecutiveCount(
            qualifyingDays: checkedDays,
            anchor: today,
            allowPendingToday: true,
            calendar: calendar
        )

        let protectedDays = Set(checkedDays.filter { day in
            guard day < today else { return false }
            return !hasLateCaffeine(
                on: day,
                caffeineDates: caffeineDates,
                sleepSchedule: sleepSchedule,
                calendar: calendar
            )
        })

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let sleepProtectionDays = consecutiveCount(
            qualifyingDays: protectedDays,
            anchor: yesterday,
            allowPendingToday: false,
            calendar: calendar
        )

        return StreakSummary(
            awarenessDays: awarenessDays,
            sleepProtectionDays: sleepProtectionDays,
            isTodayReviewed: isTodayReviewed,
            isTodaySleepProtectedSoFar: isTodayReviewed
                && !hasLateCaffeine(
                    on: today,
                    caffeineDates: caffeineDates,
                    sleepSchedule: sleepSchedule,
                    calendar: calendar
                )
        )
    }

    private func consecutiveCount(
        qualifyingDays: Set<Date>,
        anchor: Date,
        allowPendingToday: Bool,
        calendar: Calendar
    ) -> Int {
        var cursor = anchor
        if allowPendingToday, !qualifyingDays.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        var count = 0
        while qualifyingDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return count
    }

    private func hasLateCaffeine(
        on day: Date,
        caffeineDates: [Date],
        sleepSchedule: SleepSchedule,
        calendar: Calendar
    ) -> Bool {
        let bedtime = sleepSchedule.bedtimeDate(relativeTo: day, calendar: calendar)
        let cutoff = calendar.date(
            byAdding: .hour,
            value: -sleepSchedule.cutoffHoursBeforeBedtime,
            to: bedtime
        ) ?? bedtime

        return caffeineDates.contains {
            calendar.isDate($0, inSameDayAs: day) && $0 >= cutoff
        }
    }
}
