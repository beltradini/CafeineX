import Foundation
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct DrinkLibraryTests {
    @Test func bootstrapCreatesOneReusableLibrary() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try DrinkLibrary.bootstrapIfNeeded(drinks: [], context: context)
        let first = try context.fetch(FetchDescriptor<Drink>())
        #expect(first.count == 5)
        #expect(first.filter(\.isFavorite).count == 4)

        try DrinkLibrary.bootstrapIfNeeded(drinks: first, context: context)
        #expect(try context.fetchCount(FetchDescriptor<Drink>()) == 5)
    }

    @Test func archiveRemovesFavoriteAndRestorePreservesHistoryMetadata() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let drink = Drink(
            name: "Test Latte",
            caffeineMG: 90,
            category: .coffee,
            isFavorite: true
        )
        context.insert(drink)
        try context.save()

        try DrinkLibrary.recordUse(
            of: drink,
            at: .now,
            detailsValues: [],
            context: context
        )
        var details = try #require(
            context.fetch(FetchDescriptor<DrinkDetails>()).first
        )
        try DrinkLibrary.archive(
            drink,
            detailsValues: [details],
            context: context
        )
        #expect(details.isArchived)
        #expect(details.archivedAt != nil)
        #expect(details.favoriteOrder == nil)
        #expect(!drink.isFavorite)
        #expect(details.useCount == 1)
        #expect(details.lastUsedAt != nil)
        #expect(details.drink?.id == drink.id)

        try DrinkLibrary.restore(
            drink,
            detailsValues: [details],
            context: context
        )
        details = try #require(
            context.fetch(FetchDescriptor<DrinkDetails>()).first
        )
        #expect(!details.isArchived)
        #expect(details.archivedAt == nil)
        #expect(details.useCount == 1)
    }

    @Test func favoriteOrderPersistsAndRelationshipLinksDrink() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let first = Drink(
            name: "First",
            caffeineMG: 80,
            category: .coffee,
            isFavorite: true
        )
        let second = Drink(
            name: "Second",
            caffeineMG: 40,
            category: .tea,
            isFavorite: true
        )
        context.insert(first)
        context.insert(second)
        let firstDetails = DrinkDetails(
            drinkID: first.id,
            favoriteOrder: 0,
            drink: first
        )
        let secondDetails = DrinkDetails(
            drinkID: second.id,
            favoriteOrder: 1,
            drink: second
        )
        context.insert(firstDetails)
        context.insert(secondDetails)
        try context.save()

        try DrinkLibrary.reorderFavorites(
            [second, first],
            detailsValues: [firstDetails, secondDetails],
            context: context
        )

        let persisted = try context.fetch(FetchDescriptor<DrinkDetails>())
        #expect(
            persisted.first { $0.drinkID == second.id }?.favoriteOrder == 0
        )
        #expect(
            persisted.first { $0.drinkID == first.id }?.favoriteOrder == 1
        )
        #expect(
            persisted.first { $0.drinkID == first.id }?.drink?.id == first.id
        )
    }

    @Test func detailsPersistNewAttributesAndDeletingDetailsPreservesDrink() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let drink = Drink(
            name: "Phase C Cold Brew",
            caffeineMG: 180,
            category: .coffee
        )
        let details = DrinkDetails(
            drinkID: drink.id,
            brand: "CafeineX Lab",
            servingAmount: 355,
            servingUnit: .milliliters,
            personalNotes: "Single origin",
            drink: drink
        )
        context.insert(drink)
        context.insert(details)
        try context.save()

        let persisted = try #require(
            context.fetch(FetchDescriptor<DrinkDetails>()).first
        )
        #expect(persisted.brand == "CafeineX Lab")
        #expect(persisted.servingAmount == 355)
        #expect(persisted.servingUnit == .milliliters)
        #expect(persisted.personalNotes == "Single origin")
        #expect(persisted.drink?.id == drink.id)

        context.delete(persisted)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<DrinkDetails>()) == 0)
        let preservedDrink = try #require(
            context.fetch(FetchDescriptor<Drink>()).first
        )
        #expect(preservedDrink.id == drink.id)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CafeineXSchemaV4.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
