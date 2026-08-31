//
//  NotificationPolicy.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/8/26.
//

import Foundation

enum CafeineXNotificationID {
    static let habitualDrink = "cafeinex.notifications.habitual-drink"
    static let sleepWindow = "cafeinex.notifications.sleep-window"
    static let forgottenExposure = "cafeinex.notifications.forgotten-exposure"

    static let all = [
        habitualDrink,
        sleepWindow,
        forgottenExposure,
    ]
}

nonisolated struct NotificationPolicy {
    static func sleepReviewTime(
        schedule: SleepSchedule,
        calendar: Calendar = .current,
        relativeTo date: Date = .now
    ) -> NotificationTime {
        let bedtime = schedule.bedtimeDate(
            relativeTo: date,
            calendar: calendar
        )

        let reviewDate = bedtime.addingTimeInterval(-Double(schedule.cutoffHoursBeforeBedtime) * 60 * 60)

        let components = calendar.dateComponents(
            [.hour, .minute],
            from: reviewDate
        )

        return NotificationTime(
            hour: components.hour ?? 14,
            minute: components.minute ?? 0
        )
    }
}
