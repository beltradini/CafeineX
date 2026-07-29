import Foundation
import SwiftData

@MainActor
enum DrinkLibrary {
    static func bootstrapIfNeeded(
        drinks: [Drink],
        context: ModelContext
    ) {
        guard drinks.isEmpty,
              (try? context.fetchCount(FetchDescriptor<Drink>())) == 0 else {
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

        defaults.forEach(context.insert)
        try? context.save()
    }

    static func recordUse(
        of drink: Drink,
        at date: Date,
        metadataValues: [DrinkMetadata],
        context: ModelContext
    ) {
        let metadata = metadata(
            for: drink,
            in: metadataValues,
            context: context
        )
        metadata.useCount += 1
        metadata.lastUsedAt = date
        metadata.updatedAt = .now
        try? context.save()
    }

    static func archive(
        _ drink: Drink,
        metadataValues: [DrinkMetadata],
        context: ModelContext
    ) {
        let metadata = metadata(
            for: drink,
            in: metadataValues,
            context: context
        )
        metadata.isArchived = true
        drink.isFavorite = false
        metadata.updatedAt = .now
        try? context.save()
    }

    static func restore(
        _ drink: Drink,
        metadataValues: [DrinkMetadata],
        context: ModelContext
    ) {
        let metadata = metadata(
            for: drink,
            in: metadataValues,
            context: context
        )
        metadata.isArchived = false
        metadata.updatedAt = .now
        try? context.save()
    }

    static func metadata(
        for drink: Drink,
        in values: [DrinkMetadata],
        context: ModelContext
    ) -> DrinkMetadata {
        if let existing = values.first(where: { $0.drinkID == drink.id }) {
            return existing
        }

        let drinkID = drink.id
        let descriptor = FetchDescriptor<DrinkMetadata>(
            predicate: #Predicate { $0.drinkID == drinkID }
        )
        if let persisted = try? context.fetch(descriptor).first {
            return persisted
        }

        let created = DrinkMetadata(drinkID: drink.id)
        context.insert(created)
        return created
    }

    static func existingMetadata(
        for drink: Drink,
        in values: [DrinkMetadata]
    ) -> DrinkMetadata? {
        values.first { $0.drinkID == drink.id }
    }
}
