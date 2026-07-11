import Foundation
import HealthKit

struct HealthCaffeineSample: Equatable, Sendable {
    let id: UUID
    let milligrams: Double
    let consumedAt: Date
    let appEntryID: UUID?
    let displayName: String?
}

@MainActor
protocol HealthKitProviding: AnyObject {
    var isHealthKitAvailable: Bool { get }
    var caffeineWriteAuthorizationStatus: HKAuthorizationStatus { get }

    func requestAuthorization() async throws
    func saveCaffeine(
        milligrams: Double,
        date: Date,
        appEntryID: UUID,
        displayName: String
    ) async throws -> HealthCaffeineSample
    func fetchCaffeineSamples(from startDate: Date, to endDate: Date) async throws -> [HealthCaffeineSample]
}

@MainActor
final class HealthKitService: HealthKitProviding {
    private enum MetadataKey {
        static let appEntryID = "com.cafeinex.caffeine-entry-id"
        static let displayName = "com.cafeinex.caffeine-display-name"
    }

    private let healthStore = HKHealthStore()
    private let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine)

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var caffeineWriteAuthorizationStatus: HKAuthorizationStatus {
        guard let caffeineType else { return .notDetermined }
        return healthStore.authorizationStatus(for: caffeineType)
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.healthDataUnavailable
        }
        guard let caffeineType else {
            throw HealthKitError.caffeineNotAvailable
        }

        try await healthStore.requestAuthorization(
            toShare: [caffeineType],
            read: [caffeineType]
        )
    }

    func saveCaffeine(
        milligrams: Double,
        date: Date = .now,
        appEntryID: UUID,
        displayName: String
    ) async throws -> HealthCaffeineSample {
        guard milligrams.isFinite, milligrams > 0 else {
            throw HealthKitError.invalidCaffeineAmount
        }
        guard let caffeineType else {
            throw HealthKitError.caffeineNotAvailable
        }

        let sample = HKQuantitySample(
            type: caffeineType,
            quantity: HKQuantity(unit: .gramUnit(with: .milli), doubleValue: milligrams),
            start: date,
            end: date,
            metadata: [
                MetadataKey.appEntryID: appEntryID.uuidString,
                MetadataKey.displayName: displayName,
            ]
        )

        try await healthStore.save(sample)

        return HealthCaffeineSample(
            id: sample.uuid,
            milligrams: milligrams,
            consumedAt: date,
            appEntryID: appEntryID,
            displayName: displayName
        )
    }

    func fetchCaffeineSamples(
        from startDate: Date,
        to endDate: Date = .now
    ) async throws -> [HealthCaffeineSample] {
        guard let caffeineType else {
            throw HealthKitError.caffeineNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate, .strictEndDate]
        )
        let descriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let samples = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: caffeineType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [descriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            healthStore.execute(query)
        }

        let unit = HKUnit.gramUnit(with: .milli)
        return samples.compactMap { sample in
            let milligrams = sample.quantity.doubleValue(for: unit)
            guard milligrams.isFinite, milligrams > 0 else { return nil }

            let entryID = (sample.metadata?[MetadataKey.appEntryID] as? String)
                .flatMap(UUID.init(uuidString:))
            let displayName = sample.metadata?[MetadataKey.displayName] as? String

            return HealthCaffeineSample(
                id: sample.uuid,
                milligrams: milligrams,
                consumedAt: sample.startDate,
                appEntryID: entryID,
                displayName: displayName
            )
        }
    }
}
