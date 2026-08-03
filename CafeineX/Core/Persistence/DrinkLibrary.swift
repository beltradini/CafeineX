import Foundation
import SwiftData

@MainActor
enum DrinkLibrary {
    static func bootstrapIfNeeded(
        drinks: [Drink],
        context: ModelContext
    ) throws {
        guard drinks.isEmpty,
              try context.fetchCount(FetchDescriptor<Drink>()) == 0 else {
            try backfillDetailsIfNeeded(context: context)
            return
        }

        let defaults = [
            Drink(
                name: "Espresso",
                caffeineMG: 64,
                category: .espresso,
                isFavorite: true
            ),
            Drink(
                name: "Americano",
                caffeineMG: 150,
                category: .coffee,
                isFavorite: true
            ),
            Drink(
                name: "Latte",
                caffeineMG: 120,
                category: .coffee,
                isFavorite: true
            ),
            Drink(
                name: "Cold Brew",
                caffeineMG: 200,
                category: .coffee,
                isFavorite: true
            ),
            Drink(
                name: "Green Tea",
                caffeineMG: 35,
                category: .tea
            ),
        ]

        for (index, drink) in defaults.enumerated() {
            context.insert(drink)
            context.insert(
                DrinkDetails(
                    drinkID: drink.id,
                    favoriteOrder: drink.isFavorite ? index : nil,
                    drink: drink
                )
            )
        }
        try context.save()
    }

    static func backfillDetailsIfNeeded(context: ModelContext) throws {
        let drinks = try context.fetch(
            FetchDescriptor<Drink>(
                sortBy: [
                    SortDescriptor(\.createdAt),
                    SortDescriptor(\.name),
                ]
            )
        )
        guard !drinks.isEmpty else {
            return
        }

        let existingDetails = try context.fetch(
            FetchDescriptor<DrinkDetails>()
        )
        let existingIDs = Set(existingDetails.map(\.drinkID))
        let legacyMetadata = try context.fetch(
            FetchDescriptor<DrinkMetadata>()
        )
        let legacyByDrinkID = Dictionary(
            uniqueKeysWithValues: legacyMetadata.map { ($0.drinkID, $0) }
        )
        let schemaState = try context.fetch(
            FetchDescriptor<PhaseCSchemaState>()
        ).first
        var favoriteOrder = nextFavoriteOrder(in: existingDetails)
        var insertedAny = false
        var updatedSchemaState = false

        for drink in drinks where !existingIDs.contains(drink.id) {
            let legacy = legacyByDrinkID[drink.id]
            let order: Int?
            if drink.isFavorite, legacy?.isArchived != true {
                order = favoriteOrder
                favoriteOrder += 1
            } else {
                order = nil
            }

            context.insert(
                DrinkDetails(
                    drinkID: drink.id,
                    isArchived: legacy?.isArchived ?? false,
                    archivedAt: legacy?.isArchived == true
                        ? legacy?.updatedAt
                        : nil,
                    favoriteOrder: order,
                    useCount: legacy?.useCount ?? 0,
                    lastUsedAt: legacy?.lastUsedAt,
                    updatedAt: legacy?.updatedAt ?? drink.createdAt,
                    drink: drink
                )
            )
            insertedAny = true
        }

        if schemaState == nil {
            context.insert(PhaseCSchemaState(completedAt: .now))
            updatedSchemaState = true
        } else if schemaState?.completedAt == nil {
            schemaState?.completedAt = .now
            updatedSchemaState = true
        }

        if insertedAny || updatedSchemaState {
            try context.save()
        }
    }

    static func recordUse(
        of drink: Drink,
        at date: Date,
        detailsValues: [DrinkDetails],
        context: ModelContext
    ) throws {
        let details = details(
            for: drink,
            in: detailsValues,
            context: context
        )
        details.useCount += 1
        details.lastUsedAt = date
        details.updatedAt = .now
        try context.save()
    }

    static func archive(
        _ drink: Drink,
        detailsValues: [DrinkDetails],
        context: ModelContext
    ) throws {
        let details = details(
            for: drink,
            in: detailsValues,
            context: context
        )
        details.isArchived = true
        details.archivedAt = .now
        details.favoriteOrder = nil
        drink.isFavorite = false
        details.updatedAt = .now
        try context.save()
    }

    static func restore(
        _ drink: Drink,
        detailsValues: [DrinkDetails],
        context: ModelContext
    ) throws {
        let details = details(
            for: drink,
            in: detailsValues,
            context: context
        )
        details.isArchived = false
        details.archivedAt = nil
        details.updatedAt = .now
        try context.save()
    }

    static func setFavorite(
        _ isFavorite: Bool,
        for drink: Drink,
        detailsValues: [DrinkDetails],
        context: ModelContext
    ) throws {
        let details = details(
            for: drink,
            in: detailsValues,
            context: context
        )
        guard !details.isArchived else { return }

        if isFavorite {
            if !drink.isFavorite || details.favoriteOrder == nil {
                details.favoriteOrder = nextFavoriteOrder(
                    in: detailsValues + [details]
                )
            }
        } else {
            details.favoriteOrder = nil
        }
        drink.isFavorite = isFavorite
        details.updatedAt = .now
        try context.save()
    }

    static func reorderFavorites(
        _ drinks: [Drink],
        detailsValues: [DrinkDetails],
        context: ModelContext
    ) throws {
        for (index, drink) in drinks.enumerated() {
            let details = details(
                for: drink,
                in: detailsValues,
                context: context
            )
            details.favoriteOrder = index
            details.updatedAt = .now
        }
        try context.save()
    }

    static func nextFavoriteOrder(in values: [DrinkDetails]) -> Int {
        (values.compactMap(\.favoriteOrder).max() ?? -1) + 1
    }

    static func details(
        for drink: Drink,
        in values: [DrinkDetails],
        context: ModelContext
    ) -> DrinkDetails {
        if let existing = values.first(where: { $0.drinkID == drink.id }) {
            if existing.drink == nil {
                existing.drink = drink
            }
            return existing
        }

        let drinkID = drink.id
        let descriptor = FetchDescriptor<DrinkDetails>(
            predicate: #Predicate { $0.drinkID == drinkID }
        )
        if let persisted = try? context.fetch(descriptor).first {
            if persisted.drink == nil {
                persisted.drink = drink
            }
            return persisted
        }

        let created = DrinkDetails(
            drinkID: drink.id,
            favoriteOrder: drink.isFavorite
                ? nextFavoriteOrder(in: values)
                : nil,
            drink: drink
        )
        context.insert(created)
        return created
    }

    static func existingDetails(
        for drink: Drink,
        in values: [DrinkDetails]
    ) -> DrinkDetails? {
        values.first { $0.drinkID == drink.id }
    }
}
