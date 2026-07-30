import Foundation
import SwiftData

nonisolated enum DrinkServingUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case milliliters
    case fluidOunces

    var id: Self { self }

    var title: String {
        switch self {
        case .milliliters: "Milliliters"
        case .fluidOunces: "Fluid ounces"
        }
    }

    var shortLabel: String {
        switch self {
        case .milliliters: "mL"
        case .fluidOunces: "fl oz"
        }
    }
}

@Model
final class DrinkDetails {
    @Attribute(.unique) var drinkID: UUID
    @Attribute(hashModifier: "CafeineXPhaseCDrinkDetailsV4")
    var brand: String
    var servingAmount: Double
    var servingUnitRawValue: String
    var personalNotes: String
    var isArchived: Bool
    var archivedAt: Date?
    var favoriteOrder: Int?
    var useCount: Int
    var lastUsedAt: Date?
    var updatedAt: Date
    @Relationship(deleteRule: .nullify) var drink: Drink?

    init(
        drinkID: UUID,
        brand: String = "",
        servingAmount: Double = 0,
        servingUnit: DrinkServingUnit = .milliliters,
        personalNotes: String = "",
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        favoriteOrder: Int? = nil,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        updatedAt: Date = .now,
        drink: Drink? = nil
    ) {
        self.drinkID = drinkID
        self.brand = brand
        self.servingAmount = servingAmount
        self.servingUnitRawValue = servingUnit.rawValue
        self.personalNotes = personalNotes
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.favoriteOrder = favoriteOrder
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.updatedAt = updatedAt
        self.drink = drink
    }

    var servingUnit: DrinkServingUnit {
        get {
            DrinkServingUnit(rawValue: servingUnitRawValue) ?? .milliliters
        }
        set {
            servingUnitRawValue = newValue.rawValue
        }
    }

    var servingDescription: String? {
        guard servingAmount > 0 else { return nil }
        return "\(servingAmount.formatted(.number.precision(.fractionLength(0...1)))) \(servingUnit.shortLabel)"
    }
}

/// Persists the completion of the one-time Phase C metadata backfill.
///
/// Keeping this V4-only model also gives the released schema an explicit,
/// stable identity without modifying any model that belongs to V1...V3.
@Model
final class PhaseCSchemaState {
    @Attribute(.unique) var key: String
    var completedAt: Date?

    init(key: String = "drink-details-backfill", completedAt: Date? = nil) {
        self.key = key
        self.completedAt = completedAt
    }
}
