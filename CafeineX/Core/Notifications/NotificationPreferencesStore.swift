//
//  NotificationPreferencesStore.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/7/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class NotificationPreferencesStore {
    private let defaults: UserDefaults
    private let key = "cafeineX.notificationPreferences"

    private(set) var preferences: NotificationPreferences

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data
            )
                else {
            self.preferences = NotificationPreferences()
            return
        }

        self.preferences = decoded
    }

    func update(_ update: (inout NotificationPreferences) -> Void) {
        var copy = preferences
        update(&copy)
        preferences = copy
        persist()
    }

    func reset() {
        preferences = NotificationPreferences()
        persist()
    }

    func clearPersistedData() {
        defaults.removeObject(forKey: key)
        preferences = NotificationPreferences()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
