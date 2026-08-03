import Foundation
import SwiftData

struct CafeineXDataDeletionResult: Equatable {
    let localRecordCount: Int
    let healthKitSampleCount: Int
    let removedRecoveryBackups: Bool
}

@MainActor
struct CafeineXDataDeletionService {
    private let healthKitService: any HealthKitProviding
    private let fileManager: FileManager
    private let recoveryRootURL: URL

    init(
        healthKitService: any HealthKitProviding,
        fileManager: FileManager = .default,
        recoveryRootURL: URL = CafeineXStoreFactory.recoveryRootURL()
    ) {
        self.healthKitService = healthKitService
        self.fileManager = fileManager
        self.recoveryRootURL = recoveryRootURL
    }

    func deleteAllData(
        from context: ModelContext,
        sleepScheduleStore: SleepScheduleStore,
        sensitivityStore: CaffeineSensitivityStore,
        appearanceStore: AppearanceStore,
        deleteOwnedHealthKitSamples: Bool
    ) async throws -> CafeineXDataDeletionResult {
        let caffeineEntries = try context.fetch(FetchDescriptor<CaffeineEntry>())
        let ownedHealthKitIDs = Set(
            caffeineEntries.compactMap { entry in
                entry.source == .healthKit ? nil : entry.healthKitUUID
            }
        )

        let healthKitSampleCount: Int
        if deleteOwnedHealthKitSamples {
            healthKitSampleCount = try await healthKitService.deleteCaffeineSamples(
                ids: ownedHealthKitIDs
            )
        } else {
            healthKitSampleCount = 0
        }

        var localRecordCount = 0
        var removedRecoveryBackups = false
        do {
            localRecordCount += try deleteAll(CigaretteEventDetails.self, from: context)
            localRecordCount += try deleteAll(DrinkDetails.self, from: context)
            localRecordCount += try deleteAll(DrinkMetadata.self, from: context)
            localRecordCount += try deleteAll(HealthSyncOutboxItem.self, from: context)
            localRecordCount += try deleteAll(AwarenessCheckIn.self, from: context)
            localRecordCount += try deleteAll(CaffeineEntry.self, from: context)
            localRecordCount += try deleteAll(NicotineEntry.self, from: context)
            localRecordCount += try deleteAll(CigaretteProfile.self, from: context)
            localRecordCount += try deleteAll(CigarettePreferences.self, from: context)
            localRecordCount += try deleteAll(Drink.self, from: context)
            localRecordCount += try deleteAll(UserProfile.self, from: context)
            localRecordCount += try deleteAll(PhaseCSchemaState.self, from: context)

            removedRecoveryBackups = fileManager.fileExists(
                atPath: recoveryRootURL.path
            )
            if removedRecoveryBackups {
                try fileManager.removeItem(at: recoveryRootURL)
            }

            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        sleepScheduleStore.clearPersistedData()
        sensitivityStore.clearPersistedData()
        appearanceStore.clearPersistedData()

        return CafeineXDataDeletionResult(
            localRecordCount: localRecordCount,
            healthKitSampleCount: healthKitSampleCount,
            removedRecoveryBackups: removedRecoveryBackups
        )
    }

    private func deleteAll<Model: PersistentModel>(
        _ model: Model.Type,
        from context: ModelContext
    ) throws -> Int {
        let values = try context.fetch(FetchDescriptor<Model>())
        for value in values {
            context.delete(value)
        }
        return values.count
    }
}
