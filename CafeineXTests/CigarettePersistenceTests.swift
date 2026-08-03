import Foundation
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct CigarettePersistenceTests {
    @Test func v4StoreMigratesToV5AndPreservesExistingEvents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "CafeineXV5Migration-\(UUID().uuidString)", directoryHint: .isDirectory)
        let storeURL = directory.appending(path: "CafeineX.store")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let eventID = UUID()
        do {
            let schema = Schema(versionedSchema: CafeineXSchemaV4.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: CafeineXMigrationPlan.self,
                configurations: [configuration]
            )
            container.mainContext.insert(NicotineEntry(
                id: eventID,
                product: .cigarette,
                quantity: 1,
                unit: .pieces
            ))
            try container.mainContext.save()
        }

        let schema = Schema(versionedSchema: CafeineXSchemaV5.self)
        let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: CafeineXMigrationPlan.self,
            configurations: [configuration]
        )
        let context = container.mainContext
        let entry = try #require(context.fetch(FetchDescriptor<NicotineEntry>()).first)
        #expect(entry.id == eventID)
        #expect(entry.product == .cigarette)

        let profile = CigaretteProfile(name: "Test Profile", isFavorite: true)
        let details = CigaretteEventDetails(
            nicotineEntryID: entry.id,
            cigaretteProfileID: profile.id,
            context: .withCoffee
        )
        context.insert(profile)
        context.insert(details)
        context.insert(CigarettePreferences(goal: .protectSleep, optionalDailyTarget: 5))
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<CigaretteProfile>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CigaretteEventDetails>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CigarettePreferences>()) == 1)
    }

    @Test func libraryBootstrapsOnceAndArchivesInsteadOfDeleting() throws {
        let schema = Schema(versionedSchema: CafeineXSchemaV5.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        try CigaretteLibrary.bootstrapIfNeeded(profiles: [], preferences: [], context: context)
        var profiles = try context.fetch(FetchDescriptor<CigaretteProfile>())
        var preferences = try context.fetch(FetchDescriptor<CigarettePreferences>())
        try CigaretteLibrary.bootstrapIfNeeded(profiles: profiles, preferences: preferences, context: context)
        profiles = try context.fetch(FetchDescriptor<CigaretteProfile>())
        preferences = try context.fetch(FetchDescriptor<CigarettePreferences>())

        #expect(profiles.count == 1)
        #expect(preferences.count == 1)
        let profile = try #require(profiles.first)
        CigaretteLibrary.archive(profile)
        try context.save()
        #expect(profile.isArchived)
        #expect(!profile.isFavorite)
        #expect(profile.archivedAt != nil)
    }
}
