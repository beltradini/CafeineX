import Foundation

nonisolated struct StreakSummary: Equatable, Sendable {
    let awarenessDays: Int
    let sleepProtectionDays: Int
    let bestAwarenessDays: Int
    let bestSleepProtectionDays: Int
    let reviewedDaysThisWeek: Int
    let protectedDaysThisWeek: Int
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
        let today = calendar.startOfDay(for: currentDate)
        let checkedDays = Set(
            checkInDates
                .map { calendar.startOfDay(for: $0) }
                .filter { $0 <= today }
        )
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
        let week = calendar.dateInterval(of: .weekOfYear, for: currentDate)
        let reviewedDaysThisWeek = checkedDays.count {
            week?.contains($0) ?? false
        }
        let protectedDaysThisWeek = protectedDays.count {
            week?.contains($0) ?? false
        }

        return StreakSummary(
            awarenessDays: awarenessDays,
            sleepProtectionDays: sleepProtectionDays,
            bestAwarenessDays: longestConsecutiveCount(
                qualifyingDays: checkedDays,
                calendar: calendar
            ),
            bestSleepProtectionDays: longestConsecutiveCount(
                qualifyingDays: protectedDays,
                calendar: calendar
            ),
            reviewedDaysThisWeek: reviewedDaysThisWeek,
            protectedDaysThisWeek: protectedDaysThisWeek,
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

    private func longestConsecutiveCount(
        qualifyingDays: Set<Date>,
        calendar: Calendar
    ) -> Int {
        guard !qualifyingDays.isEmpty else { return 0 }

        var best = 0
        var current = 0
        var previous: Date?

        for day in qualifyingDays.sorted() {
            if let previous,
               calendar.date(byAdding: .day, value: 1, to: previous) == day {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
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
