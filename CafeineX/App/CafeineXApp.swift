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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CaffeineEntry.self,
            Drink.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TodayView()
        }
        .modelContainer(sharedModelContainer)
    }
}
