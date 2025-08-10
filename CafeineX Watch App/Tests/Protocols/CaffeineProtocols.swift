//
//  CaffeineProtocols.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation

// HealthKitServiceProtocol
protocol HealthKitServiceProtocol {
    func fetchCaffeineEntries(startDate: Date, endDate: Date) async throws -> [CaffeineEntry]
    func saveCaffeineEntry(_ entry: CaffeineEntry) async throws -> Bool
}

// CaffeineDataRepositoryProtocol
protocol CaffeineDataRepositoryProtocol {
    @MainActor func fetchEntries() -> [CaffeineEntry]
    @MainActor func addEntry(_ entry: CaffeineEntry)
    @MainActor func removeEntry(id: UUID)
}

// CaffeineSyncServiceProtocol
protocol CaffeineSyncServiceProtocol {
    func syncData() async throws
}
