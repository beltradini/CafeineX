//
//  CaffeineMocks.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import SwiftData

// MockBeverageService
class MockBeverageService: BeverageCatalogService {
    override init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: BeverageTypeModel.self, configurations: config)
        super.init(container: container)
    }
}

// MockHealthKitService
class MockHealthKitService: HealthKitServiceProtocol {
    var fetchedEntries: [CaffeineEntry] = []
    var savedEntries: [CaffeineEntry] = []
    
    func fetchCaffeineEntries(startDate: Date, endDate: Date) async throws -> [CaffeineEntry] {
        return fetchedEntries
    }
    
    func saveCaffeineEntry(_ entry: CaffeineEntry) async throws -> Bool {
        savedEntries.append(entry)
        return true
    }
}

// MockCaffeineDataRepository
class MockCaffeineDataRepository: CaffeineDataRepositoryProtocol {
    var entries: [CaffeineEntry] = []
    
    @MainActor
    func fetchEntries() -> [CaffeineEntry] {
        entries
    }
    
    @MainActor
    func addEntry(_ entry: CaffeineEntry) {
        entries.append(entry)
    }

    @MainActor
    func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
    }
}

// MockCaffeineSyncService
final class MockCaffeineSyncService: CaffeineSyncServiceProtocol {
    var syncWasCalled = false
    
    func syncData() async throws {
        syncWasCalled = true
    }
}
