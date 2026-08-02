import Foundation
import SwiftData

nonisolated enum CigaretteContext: String, Codable, CaseIterable, Identifiable, Sendable {
    case withCoffee
    case afterMeal
    case social
    case stress
    case routine
    case beforeSleep
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .withCoffee: "With coffee"
        case .afterMeal: "After a meal"
        case .social: "Social"
        case .stress: "Stress"
        case .routine: "Routine"
        case .beforeSleep: "Before sleep"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .withCoffee: "cup.and.saucer.fill"
        case .afterMeal: "fork.knife"
        case .social: "person.2.fill"
        case .stress: "bolt.heart.fill"
        case .routine: "repeat"
        case .beforeSleep: "moon.zzz.fill"
        case .other: "ellipsis.circle.fill"
        }
    }
}

nonisolated enum CigaretteGoal: String, Codable, CaseIterable, Identifiable, Sendable {
    case awareness
    case reducePairings
    case protectSleep
    case extendGaps

    var id: Self { self }

    var title: String {
        switch self {
        case .awareness: "Build awareness"
        case .reducePairings: "Separate caffeine and cigarettes"
        case .protectSleep: "Protect the sleep window"
        case .extendGaps: "Create longer pauses"
        }
    }

    var description: String {
        switch self {
        case .awareness: "Notice timing and context without judgment."
        case .reducePairings: "See when caffeine and cigarettes happen close together."
        case .protectSleep: "Keep cigarette events farther from your planned bedtime."
        case .extendGaps: "Use your own recent rhythm to make pauses more visible."
        }
    }

    var symbol: String {
        switch self {
        case .awareness: "eye.fill"
        case .reducePairings: "arrow.left.and.right"
        case .protectSleep: "moon.zzz.fill"
        case .extendGaps: "timer"
        }
    }
}

@Model
final class CigaretteProfile {
    var id: UUID
    var name: String
    var cigarettesPerPack: Int
    var manufacturerNicotineMG: Double?
    var isFavorite: Bool
    var favoriteOrder: Int?
    var isArchived: Bool
    var archivedAt: Date?
    var useCount: Int
    var lastUsedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        cigarettesPerPack: Int = 20,
        manufacturerNicotineMG: Double? = nil,
        isFavorite: Bool = false,
        favoriteOrder: Int? = nil,
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cigarettesPerPack = max(cigarettesPerPack, 1)
        self.manufacturerNicotineMG = manufacturerNicotineMG
        self.isFavorite = isFavorite
        self.favoriteOrder = favoriteOrder
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.useCount = max(useCount, 0)
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class CigaretteEventDetails {
    var id: UUID
    var nicotineEntryID: UUID
    var cigaretteProfileID: UUID?
    var contextRawValue: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        nicotineEntryID: UUID,
        cigaretteProfileID: UUID? = nil,
        context: CigaretteContext? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.nicotineEntryID = nicotineEntryID
        self.cigaretteProfileID = cigaretteProfileID
        self.contextRawValue = context?.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var context: CigaretteContext? {
        get { contextRawValue.flatMap(CigaretteContext.init(rawValue:)) }
        set { contextRawValue = newValue?.rawValue }
    }
}

@Model
final class CigarettePreferences {
    var id: UUID
    var goalRawValue: String
    var optionalDailyTarget: Int?
    var pairingWindowMinutes: Int
    var sleepProtectionMinutes: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        goal: CigaretteGoal = .awareness,
        optionalDailyTarget: Int? = nil,
        pairingWindowMinutes: Int = 30,
        sleepProtectionMinutes: Int = 240,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.goalRawValue = goal.rawValue
        self.optionalDailyTarget = optionalDailyTarget
        self.pairingWindowMinutes = max(pairingWindowMinutes, 5)
        self.sleepProtectionMinutes = max(sleepProtectionMinutes, 30)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var goal: CigaretteGoal {
        get { CigaretteGoal(rawValue: goalRawValue) ?? .awareness }
        set { goalRawValue = newValue.rawValue }
    }
}
