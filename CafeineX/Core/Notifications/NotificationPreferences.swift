//
//  NotificationPreferences.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/7/26.
//

import Foundation

struct NotificationTime: Codable, Equatable, Sendable {
    var hour: Int
    var minute: Int

    init(hour: Int = 20, minute: Int = 0) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(
            hour: components.hour ?? 20,
            minute: components.minute ?? 0
        )
    }

    var dateComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    var date: Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: .now
        ) ?? .now
    }
}

struct NotificationPreferences: Codable, Equatable, Sendable {
    var habitualDrinkEnabled = false
    var habitualDrinkID: UUID?
    var habitualDrinkTime = NotificationTime(hour: 10, minute: 0)

    var sleepWindowEnabled = false
    var forgottenExposureEnabled = false
    var forgottenExposureTime = NotificationTime(hour: 20, minute: 0)
}
