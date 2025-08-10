//
//  DashboardViewModel.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var entries: [CaffeineEntry] = []
    @Published var dailyTotal: Double = 0.0
    @Published var dailyLimit: Double = 400.0
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // Closures for UI actions
    var onAddBeverage: () -> Void = {}
    var onShowHistory: () -> Void = {}
    
    private let dataSource: CaffeineDataSourceProtocol
    private let syncService: CaffeineSyncService
    private let healthKitService: any HealthKitServiceProtocol
    private let dataRepository: any CaffeineDataRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        dataSource: CaffeineDataSourceProtocol,
        syncService: CaffeineSyncService,
        healthKitService: any HealthKitServiceProtocol,
        dataRepository: any CaffeineDataRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.syncService = syncService
        self.healthKitService = healthKitService
        self.dataRepository = dataRepository
    }
    
    func loadEntries() async {
        isLoading = true
        defer { isLoading = false }
        
        entries = await dataSource.fetchEntries()
        calculateDailyTotal()
    }
    
    func addEntry(_ entry: CaffeineEntry) async {
        await dataSource.addEntry(entry)
        await loadEntries()
    }
    
    func removeEntry(id: UUID) async {
        await dataSource.removeEntry(id: id)
        await loadEntries()
    }
    
    private func calculateDailyTotal() {
        let calendar = Calendar.current
        let today = Date()
        
        dailyTotal = entries
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.caffeineMg }
    }
    
    func synchronizeData() async {
        do {
            try await syncService.syncData()
            await loadEntries()
        } catch {
            self.error = error
        }
    }
}
