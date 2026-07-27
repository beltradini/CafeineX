import Foundation
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct SwiftDataMigrationTests {
    @Test func versionedPlanOpensLegacyStoreWithoutLosingData() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appending(path: "CafeineXMigrationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let storeURL = storeDirectory.appending(path: "CafeineX.store")
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }

        let entryID = UUID()
        let drinkID = UUID()
        let healthKitID = UUID()
        let consumedAt = Date(timeIntervalSince1970: 1_753_636_200)
        let createdAt = consumedAt.addingTimeInterval(-60)

        do {
            // Reproduce the exact unversioned schema used before a migration
            // plan was introduced.
            let legacySchema = Schema([CaffeineEntry.self, Drink.self])
            let legacyConfiguration = ModelConfiguration(
                schema: legacySchema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let legacyContainer = try ModelContainer(
                for: legacySchema,
                configurations: [legacyConfiguration]
            )
            let context = legacyContainer.mainContext

            context.insert(
                CaffeineEntry(
                    id: entryID,
                    drinkName: "Flat White",
                    caffeineMG: 130,
                    consumedAt: consumedAt,
                    source: .healthKit,
                    healthKitUUID: healthKitID,
                    createdAt: createdAt
                )
            )
            context.insert(
                Drink(
                    id: drinkID,
                    name: "Morning Flat White",
                    caffeineMG: 130,
                    category: .coffee,
                    isFavorite: true,
                    createdAt: createdAt
                )
            )
            try context.save()
        }

        let versionedSchema = Schema(versionedSchema: CafeineXSchemaV1.self)
        let versionedConfiguration = ModelConfiguration(
            schema: versionedSchema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let migratedContainer = try ModelContainer(
            for: versionedSchema,
            migrationPlan: CafeineXMigrationPlan.self,
            configurations: [versionedConfiguration]
        )
        let migratedContext = migratedContainer.mainContext
        let entries = try migratedContext.fetch(FetchDescriptor<CaffeineEntry>())
        let drinks = try migratedContext.fetch(FetchDescriptor<Drink>())

        let entry = try #require(entries.first)
        #expect(entries.count == 1)
        #expect(entry.id == entryID)
        #expect(entry.drinkName == "Flat White")
        #expect(entry.caffeineMG == 130)
        #expect(entry.consumedAt == consumedAt)
        #expect(entry.source == .healthKit)
        #expect(entry.createdAt == createdAt)
        #expect(entry.healthKitUUID == healthKitID)

        let drink = try #require(drinks.first)
        #expect(drinks.count == 1)
        #expect(drink.id == drinkID)
        #expect(drink.name == "Morning Flat White")
        #expect(drink.caffeineMG == 130)
        #expect(drink.category == .coffee)
        #expect(drink.isFavorite)
        #expect(drink.createdAt == createdAt)
    }

    @Test func migrationPlanDeclaresCurrentSchemaAsItsBaseline() {
        #expect(CafeineXMigrationPlan.schemas.count == 1)
        #expect(CafeineXMigrationPlan.schemas.first == CafeineXSchemaV1.self)
        #expect(CafeineXMigrationPlan.stages.isEmpty)
        #expect(CafeineXSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }
}

