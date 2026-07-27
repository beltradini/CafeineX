import Foundation

nonisolated struct SleepSchedule: Equatable, Sendable {
    static let `default` = SleepSchedule(
        bedtimeHour: 22,
        bedtimeMinute: 0,
        cutoffHoursBeforeBedtime: 8
    )

    let bedtimeHour: Int
    let bedtimeMinute: Int
    let cutoffHoursBeforeBedtime: Int

    init(
        bedtimeHour: Int,
        bedtimeMinute: Int,
        cutoffHoursBeforeBedtime: Int
    ) {
        self.bedtimeHour = min(max(bedtimeHour, 0), 23)
        self.bedtimeMinute = min(max(bedtimeMinute, 0), 59)
        self.cutoffHoursBeforeBedtime = min(max(cutoffHoursBeforeBedtime, 1), 16)
    }

    func bedtimeDate(
        relativeTo date: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(
            bySettingHour: bedtimeHour,
            minute: bedtimeMinute,
            second: 0,
            of: date
        ) ?? date
    }
}

