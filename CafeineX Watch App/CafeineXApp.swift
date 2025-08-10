//
//  CafeineXApp.swift
//  CafeineX Watch App
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import SwiftUI
import SwiftData

@main
struct CafeineX_Watch_AppApp: App {
    
    static let sharedContainer: ModelContainer = {
        try! ModelContainer(for: CaffeineEntryModel.self, BeverageTypeModel.self)
    }()
    
    // Dependencies
    private let dataSource: CaffeineDataSourceProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let syncService: CaffeineSyncService
    
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var catalogViewModel: BeverageCatalogViewModel
    
    init() {
        // Initialize dependencies
        let container = Self.sharedContainer
        self.dataSource = SwiftDataSource(container: container)
        self.healthKitService = HealthKitService.shared as HealthKitServiceProtocol
        self.syncService = CaffeineSyncService(
            healthKitService: healthKitService,
            dataRepository: dataSource as! CaffeineDataRepositoryProtocol
        )
        
        // Initialize view models
        let dashboard = DashboardViewModel(
            dataSource: dataSource,
            syncService: syncService,
            healthKitService: healthKitService,
            dataRepository: dataSource as! CaffeineDataRepositoryProtocol
        )
        let catalog = BeverageCatalogViewModel(
            service: BeverageCatalogService(container: container)
        )
        
        // Set StateObjects
        _dashboardViewModel = StateObject(wrappedValue: dashboard)
        _catalogViewModel = StateObject(wrappedValue: catalog)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                DashboardView(viewModel: dashboardViewModel)
                    .environmentObject(catalogViewModel)
            }
        }
    }
}
