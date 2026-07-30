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
    @State private var appearanceStore = AppearanceStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: CafeineXSchemaV4.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: CafeineXMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            DrinkLibrary.backfillDetailsIfNeeded(context: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(sleepScheduleStore)
                .environment(sensitivityStore)
                .environment(appearanceStore)
        }
        .modelContainer(sharedModelContainer)
    }
}
