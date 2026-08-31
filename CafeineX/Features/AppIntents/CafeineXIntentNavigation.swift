//
//  CafeineXIntentNavigation.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/18/26.
//

import AppIntents
import Foundation

enum CafeineXIntentDestination: String, AppEnum {
    case quickAdd
    case history

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "CafeineX Destination"
    )

    static let caseDisplayRepresentations: [
        CafeineXIntentDestination: DisplayRepresentation
    ] = [
        .quickAdd: DisplayRepresentation(
            title: "Quick Add",
            image: .init(systemName: "plus.circle.fill")
        ),
        .history: DisplayRepresentation(
            title: "History",
            image: .init(systemName: "clock.arrow.circlepath")
        ),
    ]
}

enum OpenQuickAddIntentTarget: String, AppEnum {
    case quickAdd

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Quick Add Destination"
    )

    static let caseDisplayRepresentations: [
        OpenQuickAddIntentTarget: DisplayRepresentation
    ] = [
        .quickAdd: DisplayRepresentation(
            title: "Quick Add",
            image: .init(systemName: "plus.circle.fill")
        ),
    ]
}

enum OpenHistoryIntentTarget: String, AppEnum {
    case history

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "History Destination"
    )

    static let caseDisplayRepresentations: [
        OpenHistoryIntentTarget: DisplayRepresentation
    ] = [
        .history: DisplayRepresentation(
            title: "History",
            image: .init(systemName: "clock.arrow.circlepath")
        ),
    ]
}

nonisolated enum CafeineXIntentRouteStore {
    private static let key = "cafeinex.pending-intent-route"
    static let didChange = Notification.Name("CafeineX.intentRouteDidChange")

    static func set(_ destination: CafeineXIntentDestination) {
        UserDefaults(
            suiteName: CafeineXWidgetConstants.appGroupID
        )?.set(destination.rawValue, forKey: key)
        NotificationCenter.default.post(name: didChange, object: nil)
    }

    static func consume() -> CafeineXIntentDestination? {
        guard let defaults = UserDefaults(
            suiteName: CafeineXWidgetConstants.appGroupID
        ) else {
            return nil
        }

        guard let rawValue = defaults.string(forKey: key) else {
            return nil
        }

        defaults.removeObject(forKey: key)
        return CafeineXIntentDestination(rawValue: rawValue)
    }
}
