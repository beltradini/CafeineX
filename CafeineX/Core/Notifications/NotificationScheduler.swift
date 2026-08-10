//
//  NotificationScheduler.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/8/26.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(
            options: [.alert, .sound]
        )
    }

    func reschedule(
        preferences: NotificationPreferences,
        sleepSchedule: SleepSchedule,
        drinkName: String?
    ) async throws {
        center.removePendingNotificationRequests(
            withIdentifiers: CafeineXNotificationID.all
        )

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else {
            return
        }

        if preferences.habitualDrinkEnabled,
           let drinkName,
           let request = habitualDrinkRequest(
                time: preferences.habitualDrinkTime,
                drinkName: drinkName
           ) {
            try await center.add(request)
        }

        if preferences.sleepWindowEnabled {
            let time = NotificationPolicy.sleepReviewTime(
                schedule: sleepSchedule
            )

            try await center.add(
                dailyRequest(
                    identifier: CafeineXNotificationID.sleepWindow,
                    time: time,
                    title: "Sleep window",
                    body: "Review your caffeine window for tonight."
                )
            )
        }

        if preferences.forgottenExposureEnabled {
            try await center.add(
                dailyRequest(
                    identifier: CafeineXNotificationID.forgottenExposure,
                    time: preferences.forgottenExposureTime,
                    title: "Daily exposure check-in",
                    body: "Did you record all of today's exposures?"
                )
            )
        }
    }

    func cancelAll() {
        center.removePendingNotificationRequests(
            withIdentifiers: CafeineXNotificationID.all
        )
    }

    private func habitualDrinkRequest(
        time: NotificationTime,
        drinkName: String
    ) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        content.title = "Usual drink?"
        content.body = "If you had your \(drinkName), log it in CafeineX."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time.dateComponents,
            repeats: true
        )

        return UNNotificationRequest(
            identifier: CafeineXNotificationID.habitualDrink,
            content: content,
            trigger: trigger
        )
    }

    private func dailyRequest(
        identifier: String,
        time: NotificationTime,
        title: String,
        body: String
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time.dateComponents,
            repeats: true
        )

        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
    }
}
