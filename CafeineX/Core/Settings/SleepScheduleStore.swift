import Foundation
import Observation

@MainActor
@Observable
final class SleepScheduleStore {
    private enum Key {
        static let bedtimeHour = "sleep.bedtimeHour"
        static let bedtimeMinute = "sleep.bedtimeMinute"
        static let cutoffHoursBeforeBedtime = "sleep.cutoffHoursBeforeBedtime"
    }

    private let defaults: UserDefaults

    private(set) var schedule: SleepSchedule

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.schedule = SleepSchedule(
            bedtimeHour: defaults.object(forKey: Key.bedtimeHour) as? Int
                ?? SleepSchedule.default.bedtimeHour,
            bedtimeMinute: defaults.object(forKey: Key.bedtimeMinute) as? Int
                ?? SleepSchedule.default.bedtimeMinute,
            cutoffHoursBeforeBedtime: defaults.object(forKey: Key.cutoffHoursBeforeBedtime) as? Int
                ?? SleepSchedule.default.cutoffHoursBeforeBedtime
        )
    }

    func setBedtime(_ date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        update(
            bedtimeHour: components.hour ?? schedule.bedtimeHour,
            bedtimeMinute: components.minute ?? schedule.bedtimeMinute,
            cutoffHoursBeforeBedtime: schedule.cutoffHoursBeforeBedtime
        )
    }

    func setCutoffHoursBeforeBedtime(_ hours: Int) {
        update(
            bedtimeHour: schedule.bedtimeHour,
            bedtimeMinute: schedule.bedtimeMinute,
            cutoffHoursBeforeBedtime: hours
        )
    }

    func reset() {
        apply(.default)
    }

    func clearPersistedData() {
        defaults.removeObject(forKey: Key.bedtimeHour)
        defaults.removeObject(forKey: Key.bedtimeMinute)
        defaults.removeObject(forKey: Key.cutoffHoursBeforeBedtime)
        schedule = .default
    }

    func bedtimeDate(
        relativeTo date: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        schedule.bedtimeDate(relativeTo: date, calendar: calendar)
    }

    private func update(
        bedtimeHour: Int,
        bedtimeMinute: Int,
        cutoffHoursBeforeBedtime: Int
    ) {
        apply(
            SleepSchedule(
                bedtimeHour: bedtimeHour,
                bedtimeMinute: bedtimeMinute,
                cutoffHoursBeforeBedtime: cutoffHoursBeforeBedtime
            )
        )
    }

    private func apply(_ newSchedule: SleepSchedule) {
        schedule = newSchedule
        defaults.set(newSchedule.bedtimeHour, forKey: Key.bedtimeHour)
        defaults.set(newSchedule.bedtimeMinute, forKey: Key.bedtimeMinute)
        defaults.set(
            newSchedule.cutoffHoursBeforeBedtime,
            forKey: Key.cutoffHoursBeforeBedtime
        )
    }
}
