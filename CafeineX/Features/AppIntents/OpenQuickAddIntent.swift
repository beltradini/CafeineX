//
//  OpenQuickAddIntent.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/18/26.
//

import AppIntents

struct OpenQuickAddIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Quick Add"

    static let description = IntentDescription(
        "Opens CafeineX ready to record an exposure."
    )

    @Parameter(title: "Destination")
    var target: OpenQuickAddIntentTarget

    init() {
        target = .quickAdd
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        CafeineXIntentRouteStore.set(.quickAdd)
        return .result()
    }
}
