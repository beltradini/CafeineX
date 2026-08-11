//
//  CafeineXWidgetStore.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/10/26.
//

import Foundation
import WidgetKit

enum CafeineXWidgetStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: CafeineXWidgetConstants.appGroupID)
    }

    static func loadSnapshot() -> CafeineXWidgetSnapshot {
        guard
            let data = defaults?.data(forKey: CafeineXWidgetConstants.snapshotKey),
            let snapshot = try? JSONDecoder().decode(CafeineXWidgetSnapshot.self, from: data
            )
                else {
            return .empty
        }

        return snapshot
    }

    static func saveSnapshot(_ snapshot: CafeineXWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults?.set(data, forKey: CafeineXWidgetConstants.snapshotKey)
        reloadTimelines()
    }

    static func reloadTimelines() {
        for kind in CafeineXWidgetConstants.widgetKinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }
}
