//
//  OpenHistoryIntent.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/18/26.
//

import AppIntents

struct OpenHistoryIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open History"

    static let description = IntentDescription(
        "Opens your CafeineX exposure history."
    )

    @Parameter(title: "Destination")
    var target: OpenHistoryIntentTarget

    init() {
        target = .history
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        CafeineXIntentRouteStore.set(.history)
        return .result()
    }
}
