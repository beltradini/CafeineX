//
//  CafeineXApp.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI
import SwiftData

@main
struct CafeineXApp: App {
    @State private var sleepScheduleStore = SleepScheduleStore()
    @State private var sensitivityStore = CaffeineSensitivityStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: CafeineXSchemaV2.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: CafeineXMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environment(sleepScheduleStore)
                .environment(sensitivityStore)
        }
        .modelContainer(sharedModelContainer)
    }
}
