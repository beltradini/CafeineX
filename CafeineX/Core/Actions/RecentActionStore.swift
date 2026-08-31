//
//  RecentActionStore.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class RecentActionStore {
    static let shared = RecentActionStore()

    private let defaults: UserDefaults
    private let storageKey = "cafeinex.recentActions"

    private let maximumCount = 20
    private let retentionInterval: TimeInterval = 14 * 24 * 60 * 60

    private(set) var actions: [RecentAction]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let retentionInterval = self.retentionInterval
        let maximumCount = self.maximumCount

        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(
                [RecentAction].self,
                from: data
            )
        else {
            self.actions = []
            return
        }

        self.actions = decoded
            .filter {
                Date.now.timeIntervalSince($0.occurredAt) <= retentionInterval
            }
            .sorted { $0.occurredAt > $1.occurredAt }
            .prefix(maximumCount)
            .map { $0 }
    }

    func record(
        kind: RecentActionKind,
        title: String,
        detail: String? = nil,
        relatedEntryID: UUID? = nil,
        occurredAt: Date = .now
    ) {
        let action = RecentAction(
            kind: kind,
            title: title,
            detail: detail,
            occurredAt: occurredAt,
            relatedEntryID: relatedEntryID
        )

        actions.insert(action, at: 0)

        actions = actions
            .filter {
                Date.now.timeIntervalSince($0.occurredAt) <= retentionInterval
            }
            .prefix(maximumCount)
            .map { $0 }

        persist()
    }

    func removeAll() {
        actions.removeAll()
        defaults.removeObject(forKey: storageKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(actions) else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }
}
