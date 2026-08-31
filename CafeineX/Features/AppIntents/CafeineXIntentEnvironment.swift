//
//  CafeineXIntentEnvironment.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/17/26.
//

import Foundation
import SwiftData

@MainActor
enum CafeineXIntentEnvironment {
    static func makeLoggingService() throws -> CaffeineLoggingService {
        let container = try CafeineXStoreFactory.sharedApplicationContainer()

        return CaffeineLoggingService(
            context: container.mainContext,
            recentActions: .shared,
            healthKitService: HealthKitService()
        )
    }

    static func makeSummaryService() throws -> CaffeineSummaryService {
        let container = try CafeineXStoreFactory.sharedApplicationContainer()

        return CaffeineSummaryService(
            context: container.mainContext, sleepSchedule: SleepScheduleStore().schedule, sensitivity: CaffeineSensitivityStore().profile
        )
    }
}
