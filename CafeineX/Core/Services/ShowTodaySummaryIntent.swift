//
//  ShowTodaySummaryIntent.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/18/26.
//

import AppIntents

struct ShowTodaySummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Today’s Summary"

    static let description = IntentDescription(
        "Shows today’s logged caffeine and estimated active range.",
        categoryName: "Caffeine"
    )

    static var supportedModes: IntentModes {
        .background
    }

    @MainActor
    func perform() async throws
        -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let service = try CafeineXIntentEnvironment.makeSummaryService()
        let summary = try service.makeTodaySummary()

        return .result(
            value: summary.text,
            dialog: "\(summary.text)"
        )
    }
}
