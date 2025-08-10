//
//  CaffeineSyncService.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import SwiftData

final class CaffeineSyncService: CaffeineSyncServiceProtocol {
    private let healthKitService: HealthKitServiceProtocol
    private let dataRepository: CaffeineDataRepositoryProtocol

    init(
        healthKitService: HealthKitServiceProtocol,
        dataRepository: CaffeineDataRepositoryProtocol
    ) {
        self.healthKitService = healthKitService
        self.dataRepository = dataRepository
    }

    func syncData() async throws {
        let swiftDataEntries = await dataRepository.fetchEntries()
        let startDate = Date(timeIntervalSinceNow: -60*60*24*30)
        let endDate = Date()

        let healthKitEntries = try await healthKitService.fetchCaffeineEntries(startDate: startDate, endDate: endDate)
        
        let localIDs = Set(swiftDataEntries.map { $0.id })
        let hkIDs = Set(healthKitEntries.map { $0.id })
        
        let newFromHK = healthKitEntries.filter { !localIDs.contains($0.id) }
        for entry in newFromHK {
            await dataRepository.addEntry(entry)
        }
        
        _ = swiftDataEntries.filter { !hkIDs.contains($0.id) }
        for entry in newFromHK {
            await dataRepository.addEntry(entry)
        }
    }
    
    @MainActor
    static let shared: CaffeineSyncService = {
        let schema = Schema([CaffeineEntry.self as any PersistentModel.Type])
        let container = try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: false)]
        )
        let repository = CaffeineDataRepository(container: container)
        return CaffeineSyncService(
            healthKitService: HealthKitService.shared as HealthKitServiceProtocol,
            dataRepository: repository as CaffeineDataRepositoryProtocol
        )
    }()
}
