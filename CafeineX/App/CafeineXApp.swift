//
//  CafeineXApp.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftData
import SwiftUI

@main
struct CafeineXApp: App {
    @State private var persistenceController = CafeineXPersistenceController()
    @State private var persistenceIssueCenter = PersistenceIssueCenter()
    @State private var sleepScheduleStore = SleepScheduleStore()
    @State private var sensitivityStore = CaffeineSensitivityStore()
    @State private var appearanceStore = AppearanceStore()

    var body: some Scene {
        WindowGroup {
            switch persistenceController.state {
            case .loading:
                ProgressView("Opening CafeineX…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .ready(let container):
                AppShellView(persistenceIssueCenter: persistenceIssueCenter)
                    .environment(sleepScheduleStore)
                    .environment(sensitivityStore)
                    .environment(appearanceStore)
                    .modelContainer(container)

            case .unavailable(let failure):
                StorageUnavailableView(
                    failure: failure,
                    retry: persistenceController.retry,
                    preserveAndStartFresh: persistenceController.preserveAndStartFresh
                )
            }
        }
    }
}
