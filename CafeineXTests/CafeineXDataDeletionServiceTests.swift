import Foundation
import HealthKit
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct CafeineXDataDeletionServiceTests {
    @Test func deletesEveryLocalDataCategoryAndOnlyOwnedHealthSamples() async throws {
        let schema = Schema(versionedSchema: CafeineXSchemaV5.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let ownedHealthID = UUID()
        let importedHealthID = UUID()
        let drink = Drink(name: "Personal Drink", caffeineMG: 90, category: .custom)
        let nicotine = NicotineEntry(product: .cigarette, quantity: 1, unit: .pieces)
        let cigaretteProfile = CigaretteProfile(name: "Personal Cigarette")

        context.insert(CaffeineEntry(
            drinkName: "Owned",
            caffeineMG: 80,
            source: .manual,
            healthKitUUID: ownedHealthID
        ))
        context.insert(CaffeineEntry(
            drinkName: "Imported",
            caffeineMG: 100,
            source: .healthKit,
            healthKitUUID: importedHealthID
        ))
        context.insert(nicotine)
        context.insert(drink)
        context.insert(DrinkMetadata(drinkID: drink.id))
        context.insert(DrinkDetails(drinkID: drink.id, drink: drink))
        context.insert(UserProfile(displayName: "Alex", avatarData: Data([1, 2, 3])))
        context.insert(AwarenessCheckIn(day: .now))
        context.insert(HealthSyncOutboxItem(entryID: UUID()))
        context.insert(PhaseCSchemaState(completedAt: .now))
        context.insert(cigaretteProfile)
        context.insert(CigaretteEventDetails(
            nicotineEntryID: nicotine.id,
            cigaretteProfileID: cigaretteProfile.id,
            context: .withCoffee
        ))
        context.insert(CigarettePreferences(goal: .protectSleep, optionalDailyTarget: 4))
        try context.save()

        let suiteName = "CafeineXDataDeletionServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let sleepStore = SleepScheduleStore(defaults: defaults)
        let sensitivityStore = CaffeineSensitivityStore(defaults: defaults)
        let appearanceStore = AppearanceStore(defaults: defaults)
        sleepStore.setCutoffHoursBeforeBedtime(8)
        sensitivityStore.setProfile(.higher)
        appearanceStore.setSelection(.dark)

        let recoveryRoot = FileManager.default.temporaryDirectory.appending(
            path: "CafeineXDeletionRecovery-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: recoveryRoot,
            withIntermediateDirectories: true
        )
        try Data([1]).write(to: recoveryRoot.appending(path: "default.store"))
        defer { try? FileManager.default.removeItem(at: recoveryRoot) }

        let healthKit = DataDeletionHealthKitMock()
        let service = CafeineXDataDeletionService(
            healthKitService: healthKit,
            recoveryRootURL: recoveryRoot,
            defaults: defaults
        )
        defaults.set(true, forKey: CafeineXOnboarding.completionKey)
        defaults.set(true, forKey: CafeineXWhatsNew.completionKey)
        let result = try await service.deleteAllData(
            from: context,
            sleepScheduleStore: sleepStore,
            sensitivityStore: sensitivityStore,
            appearanceStore: appearanceStore,
            deleteOwnedHealthKitSamples: true
        )

        #expect(result.localRecordCount == 13)
        #expect(result.healthKitSampleCount == 1)
        #expect(result.removedRecoveryBackups)
        #expect(healthKit.deletedIDs == [ownedHealthID])
        #expect(!healthKit.deletedIDs.contains(importedHealthID))
        #expect(!FileManager.default.fileExists(atPath: recoveryRoot.path))
        #expect(sleepStore.schedule == .default)
        #expect(sensitivityStore.profile == .typical)
        #expect(appearanceStore.selection == .system)
        #expect(defaults.object(forKey: "sleep.cutoffHoursBeforeBedtime") == nil)
        #expect(defaults.object(forKey: "caffeine.sensitivityProfile") == nil)
        #expect(defaults.object(forKey: "appearance.selection") == nil)
        #expect(defaults.object(forKey: CafeineXOnboarding.completionKey) == nil)
        #expect(defaults.object(forKey: CafeineXWhatsNew.completionKey) == nil)

        #expect(try context.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<NicotineEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Drink>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DrinkDetails>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DrinkMetadata>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<AwarenessCheckIn>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<PhaseCSchemaState>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CigaretteProfile>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CigaretteEventDetails>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CigarettePreferences>()) == 0)
    }
}

@MainActor
private final class DataDeletionHealthKitMock: HealthKitProviding {
    var isHealthKitAvailable = true
    var caffeineWriteAuthorizationStatus: HKAuthorizationStatus = .sharingAuthorized
    private(set) var deletedIDs: Set<UUID> = []

    func requestCaffeineAuthorization() async throws {}
    func requestSleepAuthorization() async throws {}
    func sleepAuthorizationRequestStatus() async throws -> HKAuthorizationRequestStatus {
        .unnecessary
    }
    func saveCaffeine(
        milligrams: Double,
        date: Date,
        appEntryID: UUID,
        displayName: String
    ) async throws -> HealthCaffeineSample {
        HealthCaffeineSample(
            id: UUID(),
            milligrams: milligrams,
            consumedAt: date,
            appEntryID: appEntryID,
            displayName: displayName
        )
    }
    func fetchCaffeineSamples(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthCaffeineSample] {
        []
    }
    func fetchSleepSamples(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HealthSleepSample] {
        []
    }
    func deleteCaffeineSamples(ids: Set<UUID>) async throws -> Int {
        deletedIDs = ids
        return ids.count
    }
}
