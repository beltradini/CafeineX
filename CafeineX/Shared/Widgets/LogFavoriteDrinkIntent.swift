//
//  LogFavoriteDrinkIntent.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/10/26.
//

import AppIntents
import Foundation
import WidgetKit

nonisolated struct PendingWidgetDrinkCommand: Codable, Sendable {
    let id: UUID
    let name: String
    let caffeineMG: Double
    let createdAt: Date
}

nonisolated enum WidgetCommandStore {
    static func enqueueDrink(
        name: String,
        caffeineMG: Double
    ) {
        let command = PendingWidgetDrinkCommand(
            id: UUID(),
            name: name,
            caffeineMG: caffeineMG,
            createdAt: .now
        )

        guard let defaults else {
            return
        }

        var commands = pendingDrinkCommands(defaults: defaults)
            .filter { _ in command.createdAt.timeIntervalSinceNow > -24 * 60 * 60 }
        let isAccidentalRepeat = commands.contains { existing in
            existing.name == command.name
                && abs(existing.caffeineMG - command.caffeineMG) < 0.01
                && abs(existing.createdAt.timeIntervalSince(command.createdAt)) < 3
        }
        guard !isAccidentalRepeat else { return }

        commands.append(command)
        persist(Array(commands.suffix(20)), defaults: defaults)
    }

    static func pendingDrinkCommands() -> [PendingWidgetDrinkCommand] {
        guard let defaults else { return [] }
        return pendingDrinkCommands(defaults: defaults)
            .sorted { $0.createdAt < $1.createdAt }
    }

    static func acknowledgeDrinkCommand(id: UUID) {
        guard let defaults else { return }
        let remaining = pendingDrinkCommands(defaults: defaults)
            .filter { $0.id != id }
        persist(remaining, defaults: defaults)
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: CafeineXWidgetConstants.appGroupID)
    }

    private static func pendingDrinkCommands(
        defaults: UserDefaults
    ) -> [PendingWidgetDrinkCommand] {
        guard let data = defaults.data(forKey: CafeineXWidgetConstants.commandKey) else {
            return []
        }

        if let commands = try? JSONDecoder().decode(
            [PendingWidgetDrinkCommand].self,
            from: data
        ) {
            return commands
        }

        // Migrate the original single-command payload without dropping a tap.
        if let legacyCommand = try? JSONDecoder().decode(
            PendingWidgetDrinkCommand.self,
            from: data
        ) {
            return [legacyCommand]
        }

        return []
    }

    private static func persist(
        _ commands: [PendingWidgetDrinkCommand],
        defaults: UserDefaults
    ) {
        guard !commands.isEmpty else {
            defaults.removeObject(forKey: CafeineXWidgetConstants.commandKey)
            return
        }

        guard let data = try? JSONEncoder().encode(commands) else { return }
        defaults.set(data, forKey: CafeineXWidgetConstants.commandKey)
    }
}

struct LogFavoriteDrinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Log favorite drink"

    static let description = IntentDescription(
        "Records a favorite CafeineX drink at the current time."
    )

    static var openAppWhenRun: Bool {
        true
    }

    let name: String
    let caffeineMG: Double

    init() {
        self.name = "Espresso"
        self.caffeineMG = 64
    }

    init(
        name: String,
        caffeineMG: Double
    ) {
        self.name = name
        self.caffeineMG = caffeineMG
    }

    func perform() async throws -> some IntentResult {
        WidgetCommandStore.enqueueDrink(
            name: name,
            caffeineMG: caffeineMG
        )

        return .result()
    }
}
