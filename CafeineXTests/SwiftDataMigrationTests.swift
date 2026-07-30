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

        let versionedSchema = Schema(versionedSchema: CafeineXSchemaV4.self)
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
        DrinkLibrary.backfillDetailsIfNeeded(context: migratedContext)
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

        let details = try #require(
            migratedContext.fetch(FetchDescriptor<DrinkDetails>()).first
        )
        #expect(details.drinkID == drinkID)
        #expect(details.drink?.id == drinkID)
        #expect(details.favoriteOrder == 0)
        #expect(
            try migratedContext.fetchCount(
                FetchDescriptor<PhaseCSchemaState>()
            ) == 1
        )
    }

    @Test func migrationPlanDeclaresCurrentSchemaAsItsBaseline() {
        #expect(CafeineXMigrationPlan.schemas.count == 4)
        #expect(CafeineXMigrationPlan.schemas.first == CafeineXSchemaV1.self)
        #expect(CafeineXMigrationPlan.schemas.last == CafeineXSchemaV4.self)
        #expect(CafeineXMigrationPlan.stages.count == 3)
        #expect(CafeineXSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(CafeineXSchemaV2.versionIdentifier == Schema.Version(2, 0, 0))
        #expect(CafeineXSchemaV3.versionIdentifier == Schema.Version(3, 0, 0))
        #expect(CafeineXSchemaV4.versionIdentifier == Schema.Version(4, 0, 0))
    }

    @Test func v1StoreMigratesToV2AndAcceptsNicotineEntries() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appending(path: "CafeineXV2MigrationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let storeURL = storeDirectory.appending(path: "CafeineX.store")
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }

        let caffeineID = UUID()
        let consumedAt = Date(timeIntervalSince1970: 1_753_722_000)

        do {
            let v1Schema = Schema(versionedSchema: CafeineXSchemaV1.self)
            let v1Configuration = ModelConfiguration(
                schema: v1Schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let v1Container = try ModelContainer(
                for: v1Schema,
                configurations: [v1Configuration]
            )
            v1Container.mainContext.insert(
                CaffeineEntry(
                    id: caffeineID,
                    drinkName: "Migration Espresso",
                    caffeineMG: 64,
                    consumedAt: consumedAt
                )
            )
            try v1Container.mainContext.save()
        }

        let v2Schema = Schema(versionedSchema: CafeineXSchemaV2.self)
        let v2Configuration = ModelConfiguration(
            schema: v2Schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let v2Container = try ModelContainer(
            for: v2Schema,
            migrationPlan: CafeineXMigrationPlan.self,
            configurations: [v2Configuration]
        )
        let context = v2Container.mainContext

        let caffeineEntries = try context.fetch(FetchDescriptor<CaffeineEntry>())
        let migratedEntry = try #require(caffeineEntries.first)
        #expect(caffeineEntries.count == 1)
        #expect(migratedEntry.id == caffeineID)
        #expect(migratedEntry.drinkName == "Migration Espresso")
        #expect(migratedEntry.caffeineMG == 64)

        let nicotineEntry = NicotineEntry(
            product: .pouch,
            quantity: 4,
            unit: .milligrams,
            usedAt: consumedAt.addingTimeInterval(600)
        )
        context.insert(nicotineEntry)
        try context.save()

        let nicotineEntries = try context.fetch(FetchDescriptor<NicotineEntry>())
        let persistedNicotine = try #require(nicotineEntries.first)
        #expect(nicotineEntries.count == 1)
        #expect(persistedNicotine.product == .pouch)
        #expect(persistedNicotine.quantity == 4)
        #expect(persistedNicotine.unit == .milligrams)
    }

    @Test func v2StoreMigratesToV3AndAcceptsProfileAndCheckIns() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appending(path: "CafeineXV3MigrationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let storeURL = storeDirectory.appending(path: "CafeineX.store")
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }

        let drinkID = UUID()
        do {
            let schema = Schema(versionedSchema: CafeineXSchemaV2.self)
            let configuration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: CafeineXMigrationPlan.self,
                configurations: [configuration]
            )
            container.mainContext.insert(
                Drink(
                    id: drinkID,
                    name: "V2 Tea",
                    caffeineMG: 40,
                    category: .tea,
                    isFavorite: true
                )
            )
            try container.mainContext.save()
        }

        let schema = Schema(versionedSchema: CafeineXSchemaV3.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: CafeineXMigrationPlan.self,
            configurations: [configuration]
        )
        let context = container.mainContext

        let migratedDrink = try #require(
            context.fetch(FetchDescriptor<Drink>()).first
        )
        #expect(migratedDrink.id == drinkID)
        #expect(
            try context.fetchCount(FetchDescriptor<DrinkMetadata>()) == 0
        )

        context.insert(UserProfile(displayName: "Alex", goal: .protectSleep))
        context.insert(AwarenessCheckIn(day: Date(timeIntervalSince1970: 1_753_722_000)))
        context.insert(DrinkMetadata(drinkID: migratedDrink.id))
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<AwarenessCheckIn>()) == 1)
    }

    @Test func v3StoreMigratesMetadataIntoRelatedDrinkDetails() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appending(
                path: "CafeineXV4MigrationTests-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
        let storeURL = storeDirectory.appending(path: "CafeineX.store")
        try FileManager.default.createDirectory(
            at: storeDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }

        let favoriteID = UUID()
        let archivedID = UUID()
        let archivedAt = Date(timeIntervalSince1970: 1_753_722_000)

        do {
            let schema = Schema(versionedSchema: CafeineXSchemaV3.self)
            let configuration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: CafeineXMigrationPlan.self,
                configurations: [configuration]
            )
            let context = container.mainContext
            let favorite = Drink(
                id: favoriteID,
                name: "Favorite V3",
                caffeineMG: 90,
                category: .coffee,
                isFavorite: true
            )
            let archived = Drink(
                id: archivedID,
                name: "Archived V3",
                caffeineMG: 35,
                category: .tea,
                isFavorite: false
            )
            context.insert(favorite)
            context.insert(archived)
            context.insert(
                DrinkMetadata(
                    drinkID: favoriteID,
                    useCount: 4,
                    lastUsedAt: archivedAt.addingTimeInterval(-3_600),
                    updatedAt: archivedAt
                )
            )
            context.insert(
                DrinkMetadata(
                    drinkID: archivedID,
                    isArchived: true,
                    useCount: 2,
                    updatedAt: archivedAt
                )
            )
            try context.save()
        }

        let schema = Schema(versionedSchema: CafeineXSchemaV4.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: CafeineXMigrationPlan.self,
            configurations: [configuration]
        )
        DrinkLibrary.backfillDetailsIfNeeded(context: container.mainContext)
        let details = try container.mainContext.fetch(
            FetchDescriptor<DrinkDetails>()
        )
        let favoriteDetails = try #require(
            details.first { $0.drinkID == favoriteID }
        )
        let archivedDetails = try #require(
            details.first { $0.drinkID == archivedID }
        )

        #expect(details.count == 2)
        #expect(favoriteDetails.drink?.id == favoriteID)
        #expect(favoriteDetails.favoriteOrder == 0)
        #expect(favoriteDetails.useCount == 4)
        #expect(!favoriteDetails.isArchived)
        #expect(archivedDetails.drink?.id == archivedID)
        #expect(archivedDetails.favoriteOrder == nil)
        #expect(archivedDetails.isArchived)
        #expect(archivedDetails.archivedAt == archivedAt)
        #expect(archivedDetails.useCount == 2)
        #expect(
            try container.mainContext.fetchCount(
                FetchDescriptor<PhaseCSchemaState>()
            ) == 1
        )
    }
}
