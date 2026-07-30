import Foundation

nonisolated struct WeeklyGoalProgress: Equatable, Sendable {
    let title: String
    let completedDays: Int
    let availableDays: Int

    var fraction: Double {
        guard availableDays > 0 else { return 0 }
        return min(max(Double(completedDays) / Double(availableDays), 0), 1)
    }

    var accessibilityValue: String {
        "\(completedDays) of \(availableDays) days"
    }
}

nonisolated struct WeeklySummary: Equatable, Sendable {
    let interval: DateInterval
    let caffeineMG: Double
    let previousWeekCaffeineMG: Double
    let caffeineEvents: Int
    let nicotineEvents: Int
    let trackedDays: Int
    let reviewedDays: Int
    let sleepProtectedDays: Int
    let lateCaffeineEvents: Int
    let elapsedDays: Int
    let completedDays: Int

    var caffeineChangeMG: Double {
        caffeineMG - previousWeekCaffeineMG
    }

    func progress(for goal: ProfileGoal) -> WeeklyGoalProgress {
        switch goal {
        case .protectSleep:
            WeeklyGoalProgress(
                title: goal.metricTitle,
                completedDays: sleepProtectedDays,
                availableDays: completedDays
            )
        case .understandPatterns:
            WeeklyGoalProgress(
                title: goal.metricTitle,
                completedDays: trackedDays,
                availableDays: elapsedDays
            )
        case .reduceLateCaffeine:
            WeeklyGoalProgress(
                title: goal.metricTitle,
                completedDays: sleepProtectedDays,
                availableDays: completedDays
            )
        case .mindfulTracking:
            WeeklyGoalProgress(
                title: goal.metricTitle,
                completedDays: reviewedDays,
                availableDays: elapsedDays
            )
        }
    }
}

nonisolated struct WeeklySummaryEngine: Sendable {
    func makeSummary(
        caffeineDoses: [CaffeineDose],
        nicotineEvents: [NicotineEvent],
        checkInDates: [Date],
        sleepSchedule: SleepSchedule,
        currentDate: Date = .now,
        calendar: Calendar = .current
    ) -> WeeklySummary {
        let interval = calendar.dateInterval(
            of: .weekOfYear,
            for: currentDate
        ) ?? fallbackWeek(containing: currentDate, calendar: calendar)
        let previousStart = calendar.date(
            byAdding: .weekOfYear,
            value: -1,
            to: interval.start
        ) ?? interval.start.addingTimeInterval(-7 * 86_400)
        let previousInterval = DateInterval(
            start: previousStart,
            end: interval.start
        )

        let currentCaffeine = caffeineDoses.filter {
            interval.contains($0.consumedAt) && $0.consumedAt <= currentDate
        }
        let previousCaffeine = caffeineDoses.filter {
            previousInterval.contains($0.consumedAt)
        }
        let currentNicotine = nicotineEvents.filter {
            interval.contains($0.usedAt) && $0.usedAt <= currentDate
        }
        let currentCheckIns = checkInDates.filter {
            interval.contains($0) && $0 <= currentDate
        }

        let today = calendar.startOfDay(for: currentDate)
        let reviewedDays = Set(
            currentCheckIns.map { calendar.startOfDay(for: $0) }
        )
        let trackedDays = Set(
            currentCaffeine.map { calendar.startOfDay(for: $0.consumedAt) }
                + currentNicotine.map { calendar.startOfDay(for: $0.usedAt) }
        )
        let lateCaffeine = currentCaffeine.filter {
            isLate(
                $0.consumedAt,
                sleepSchedule: sleepSchedule,
                calendar: calendar
            )
        }
        let protectedDays = reviewedDays.filter { day in
            day < today && !lateCaffeine.contains {
                calendar.isDate($0.consumedAt, inSameDayAs: day)
            }
        }
        let elapsedDays = dayCount(
            from: interval.start,
            through: today,
            calendar: calendar
        )

        return WeeklySummary(
            interval: interval,
            caffeineMG: currentCaffeine.reduce(0) { $0 + max($1.amountMG, 0) },
            previousWeekCaffeineMG: previousCaffeine.reduce(0) {
                $0 + max($1.amountMG, 0)
            },
            caffeineEvents: currentCaffeine.count,
            nicotineEvents: currentNicotine.count,
            trackedDays: trackedDays.count,
            reviewedDays: reviewedDays.count,
            sleepProtectedDays: protectedDays.count,
            lateCaffeineEvents: lateCaffeine.count,
            elapsedDays: elapsedDays,
            completedDays: max(elapsedDays - 1, 0)
        )
    }

    private func isLate(
        _ date: Date,
        sleepSchedule: SleepSchedule,
        calendar: Calendar
    ) -> Bool {
        let day = calendar.startOfDay(for: date)
        let bedtime = sleepSchedule.bedtimeDate(relativeTo: day, calendar: calendar)
        let cutoff = calendar.date(
            byAdding: .hour,
            value: -sleepSchedule.cutoffHoursBeforeBedtime,
            to: bedtime
        ) ?? bedtime
        return date >= cutoff
    }

    private func dayCount(
        from start: Date,
        through end: Date,
        calendar: Calendar
    ) -> Int {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: end)
        ).day ?? 0
        return min(max(days + 1, 1), 7)
    }

    private func fallbackWeek(
        containing date: Date,
        calendar: Calendar
    ) -> DateInterval {
        let start = calendar.date(
            byAdding: .day,
            value: -6,
            to: calendar.startOfDay(for: date)
        ) ?? date
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? date
        return DateInterval(start: start, end: end)
    }
}
