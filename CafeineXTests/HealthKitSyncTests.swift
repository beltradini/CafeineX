import Foundation
import HealthKit
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct HealthKitSyncTests {
    @Test func repeatedSyncLinksOwnedSampleAndDoesNotDuplicateImports() async throws {
        let schema = Schema([
            CaffeineEntry.self,
            Drink.self,
            DrinkMetadata.self,
            HealthSyncOutboxItem.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let localEntry = CaffeineEntry(drinkName: "Espresso", caffeineMG: 64)
        context.insert(localEntry)
        try context.save()

        let linkedSampleID = UUID()
        let importedSampleID = UUID()
        let healthStore = MockHealthKitService(samples: [
            HealthCaffeineSample(
                id: linkedSampleID,
                milligrams: 64,
                consumedAt: localEntry.consumedAt,
                appEntryID: localEntry.id,
                displayName: "Espresso"
            ),
            HealthCaffeineSample(
                id: importedSampleID,
                milligrams: 95,
                consumedAt: localEntry.consumedAt.addingTimeInterval(-3_600),
                appEntryID: nil,
                displayName: "Tea"
            ),
        ])
        let viewModel = HomeViewModel(engine: CaffeineEngine(), healthKitService: healthStore)
        viewModel.load(entries: [localEntry])

        await viewModel.synchronizeHealthKit(context: context)
        await viewModel.synchronizeHealthKit(context: context)

        let persistedEntries = try context.fetch(FetchDescriptor<CaffeineEntry>())
        #expect(persistedEntries.count == 2)
        #expect(localEntry.healthKitUUID == linkedSampleID)
        #expect(persistedEntries.contains { $0.healthKitUUID == importedSampleID })
    }

    @Test func pendingLocalEntryUploadsOnNextSynchronization() async throws {
        let schema = Schema([
            CaffeineEntry.self,
            Drink.self,
            DrinkMetadata.self,
            HealthSyncOutboxItem.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let entry = CaffeineEntry(
            drinkName: "Offline Espresso",
            caffeineMG: 64
        )
        context.insert(entry)
        context.insert(HealthSyncOutboxItem(entryID: entry.id))
        try context.save()

        let healthStore = MockHealthKitService(samples: [])
        let viewModel = HomeViewModel(
            engine: CaffeineEngine(),
            healthKitService: healthStore
        )
        viewModel.load(entries: [entry])

        await viewModel.synchronizeHealthKit(context: context)

        #expect(entry.healthKitUUID != nil)
        #expect(
            try context.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 0
        )
        #expect(healthStore.samples.count == 1)
    }

    @Test func undoRestoresFavoriteUsageBeforeHealthUpload() throws {
        let schema = Schema([
            CaffeineEntry.self,
            Drink.self,
            DrinkMetadata.self,
            HealthSyncOutboxItem.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let drink = Drink(
            name: "Favorite",
            caffeineMG: 80,
            category: .coffee,
            isFavorite: true
        )
        context.insert(drink)
        try context.save()

        let healthStore = MockHealthKitService(samples: [])
        let viewModel = HomeViewModel(
            engine: CaffeineEngine(),
            healthKitService: healthStore
        )

        #expect(
            viewModel.addDrink(
                name: drink.name,
                caffeineMG: drink.caffeineMG,
                drink: drink,
                context: context
            )
        )
        let metadata = try #require(
            context.fetch(FetchDescriptor<DrinkMetadata>()).first
        )
        #expect(metadata.useCount == 1)
        #expect(viewModel.undoLastCaffeineAdd(context: context))
        #expect(metadata.useCount == 0)
        #expect(try context.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
        #expect(
            try context.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 0
        )
    }
}

@MainActor
private final class MockHealthKitService: HealthKitProviding {
    var isHealthKitAvailable = true
    var caffeineWriteAuthorizationStatus: HKAuthorizationStatus = .sharingAuthorized
    var samples: [HealthCaffeineSample]

    init(samples: [HealthCaffeineSample]) {
        self.samples = samples
    }

    func requestAuthorization() async throws {}

    func saveCaffeine(
        milligrams: Double,
        date: Date,
        appEntryID: UUID,
        displayName: String
    ) async throws -> HealthCaffeineSample {
        let sample = HealthCaffeineSample(
            id: UUID(),
            milligrams: milligrams,
            consumedAt: date,
            appEntryID: appEntryID,
            displayName: displayName
        )
        samples.append(sample)
        return sample
    }

    func fetchCaffeineSamples(from startDate: Date, to endDate: Date) async throws -> [HealthCaffeineSample] {
        samples.filter { $0.consumedAt >= startDate && $0.consumedAt <= endDate }
    }
}
