//
//  LogCaffeineIntent.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/17/26.
//

import AppIntents
import Foundation

struct LogCaffeineIntent: AppIntent, UndoableIntent {
    static let title: LocalizedStringResource = "Log Caffeine"

    static let description = IntentDescription(
        "Records a caffeine exposure in CafeineX after asking for confirmation.",
        categoryName: "Caffeine"
    )

    static var supportedModes: IntentModes {
        .background
    }

    @Parameter(
        title: "Drink",
        description: "The name of the drink.",
        requestValueDialog: "Which drink would you like to record?"
    )
    var drinkName: String

    @Parameter(
        title: "Caffeine",
        description: "The amount of caffeine in milligrams.",
        requestValueDialog: "How many milligrams of caffeine?"
    )
    var caffeineMG: Double

    @Parameter(
        title: "Time",
        description: "When you consumed the drink."
    )
    var consumedAt: Date?

    static var parameterSummary: some ParameterSummary {
        Summary(
            "Log \(\.$drinkName), \(\.$caffeineMG) mg at \(\.$consumedAt)"
        )
    }

    init() {}

    init(
        drinkName: String,
        caffeineMG: Double,
        consumedAt: Date? = nil
    ) {
        self.drinkName = drinkName
        self.caffeineMG = caffeineMG
        self.consumedAt = consumedAt
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let date = consumedAt ?? .now
        let request = CaffeineLogRequest(
            drinkName: drinkName, caffeineMG: caffeineMG, consumedAt: date, source: .siri
        )
        // Validate before converting to Int or presenting a confirmation.
        try request.validate()
        let roundedAmount = Int(caffeineMG.rounded())

        try await requestConfirmation(
            conditions: [],
            actionName: .log,
            dialog: "Log \(drinkName) with \(roundedAmount) mg of caffeine?"
        )

        let service = try CafeineXIntentEnvironment.makeLoggingService()

        let receipt = try service.log(request)

        if receipt.createdNewEntry, let undoManager {
            let undoTarget = CaffeineIntentUndoTarget(
                entryID: receipt.entryID
            )

            undoManager.registerUndo(withTarget: undoTarget) { target in
                target.performUndo()
            }
            undoManager.setActionName("Log Caffeine")
        }

        let identifier = receipt.entryID.uuidString

        if receipt.createdNewEntry {
            return .result(value: identifier, dialog: "Recorded \(drinkName), \(roundedAmount) milligrams.")
        }

        return .result(value: identifier, dialog: "That entry was already recorded.")
    }
}

@MainActor
private final class CaffeineIntentUndoTarget: Sendable {
    let entryID: UUID

    init(entryID: UUID) {
        self.entryID = entryID
    }

    func performUndo() {
        Task { @MainActor in
            await IntentUndoFailureStore.shared.attempt(entryID: entryID) {
                let service = try CafeineXIntentEnvironment
                    .makeLoggingService()
                try await service.undo(entryID: entryID)
            }
        }
    }
}
