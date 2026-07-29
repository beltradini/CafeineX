import Foundation
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct DrinkLibraryTests {
    @Test func bootstrapCreatesOneReusableLibrary() throws {
        let container = try makeContainer()
        let context = container.mainContext

        DrinkLibrary.bootstrapIfNeeded(drinks: [], context: context)
        let first = try context.fetch(FetchDescriptor<Drink>())
        #expect(first.count == 5)
        #expect(first.filter(\.isFavorite).count == 4)

        DrinkLibrary.bootstrapIfNeeded(drinks: first, context: context)
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

        DrinkLibrary.recordUse(
            of: drink,
            at: .now,
            metadataValues: [],
            context: context
        )
        var metadata = try #require(
            context.fetch(FetchDescriptor<DrinkMetadata>()).first
        )
        DrinkLibrary.archive(
            drink,
            metadataValues: [metadata],
            context: context
        )
        #expect(metadata.isArchived)
        #expect(!drink.isFavorite)
        #expect(metadata.useCount == 1)
        #expect(metadata.lastUsedAt != nil)

        DrinkLibrary.restore(
            drink,
            metadataValues: [metadata],
            context: context
        )
        metadata = try #require(
            context.fetch(FetchDescriptor<DrinkMetadata>()).first
        )
        #expect(!metadata.isArchived)
        #expect(metadata.useCount == 1)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CafeineXSchemaV3.self)
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
