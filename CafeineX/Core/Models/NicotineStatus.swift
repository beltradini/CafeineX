import Foundation

nonisolated struct NicotineAmountSummary: Equatable, Sendable {
    var milligrams: Double = 0
    var pieces: Double = 0
    var puffs: Double = 0

    mutating func add(quantity: Double, unit: NicotineUnit) {
        let safeQuantity = max(quantity, 0)
        switch unit {
        case .milligrams:
            milligrams += safeQuantity
        case .pieces:
            pieces += safeQuantity
        case .puffs:
            puffs += safeQuantity
        }
    }

    var isEmpty: Bool {
        milligrams == 0 && pieces == 0 && puffs == 0
    }

    var displayText: String {
        var components: [String] = []
        if milligrams > 0 {
            components.append(NicotineUnit.milligrams.formatted(quantity: milligrams))
        }
        if pieces > 0 {
            components.append(NicotineUnit.pieces.formatted(quantity: pieces))
        }
        if puffs > 0 {
            components.append(NicotineUnit.puffs.formatted(quantity: puffs))
        }
        return components.isEmpty ? "No nicotine logged" : components.joined(separator: " • ")
    }
}

nonisolated enum NicotineSleepGuidance: String, Codable, Sendable {
    case noEvents
    case outsideWindow
    case nearBedtime

    var title: String {
        switch self {
        case .noEvents: "No events"
        case .outsideWindow: "Outside sleep window"
        case .nearBedtime: "Near bedtime"
        }
    }

    var message: String {
        switch self {
        case .noEvents:
            "No nicotine events are logged today."
        case .outsideWindow:
            "Logged nicotine events are outside the four-hour bedtime guidance window."
        case .nearBedtime:
            "Nicotine was logged close to bedtime. Consider avoiding another event and notice how your sleep responds."
        }
    }
}

nonisolated struct NicotineStatus: Sendable {
    let eventsToday: Int
    let amountsToday: NicotineAmountSummary
    let activeEventCount: Int
    let latestEventAt: Date?
    let targetBedtime: Date
    let suggestedPauseTime: Date
    let sleepGuidance: NicotineSleepGuidance
}
