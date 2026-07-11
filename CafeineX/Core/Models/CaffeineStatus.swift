//
//  CaffeineStatus.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import Foundation

struct CaffeineStatus: Codable, Sendable {
    let consumedTodayMG: Double
    let activeCaffeineMG: Double
    let activeCaffeineLowMG: Double
    let activeCaffeineHighMG: Double
    let caffeineAtBedtimeLowMG: Double
    let caffeineAtBedtimeHighMG: Double
    let dailyLimitMG: Double
    let targetBedtime: Date
    let suggestedCutoffTime: Date
    let riskLevel: CaffeineRiskLevel

    var dailyProgress: Double {
        guard dailyLimitMG > 0 else { return 0 }
        return min(consumedTodayMG / dailyLimitMG, 1.0)
    }
}
