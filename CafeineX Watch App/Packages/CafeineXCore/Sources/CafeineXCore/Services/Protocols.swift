import Foundation

// HealthKitServiceProtocol
public protocol HealthKitServiceProtocol {
    func fetchCaffeineEntries(startDate: Date, endDate: Date) async throws -> [CaffeineEntry]
    func saveCaffeineEntry(_ entry: CaffeineEntry) async throws -> Bool
}

// CaffeineDataRepositoryProtocol
public protocol CaffeineDataRepositoryProtocol {
    @MainActor func fetchEntries() -> [CaffeineEntry]
    @MainActor func addEntry(_ entry: CaffeineEntry)
    @MainActor func removeEntry(id: UUID)
}

// CaffeineSyncServiceProtocol
public protocol CaffeineSyncServiceProtocol {
    func syncData() async throws
}
