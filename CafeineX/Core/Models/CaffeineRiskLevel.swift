//
//  CaffeineRiskLevel.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import Foundation

enum CaffeineRiskLevel: String, Codable, Sendable {
    case low
    case moderate
    case high
    case sleepRisk

    var title: String {
        switch self {
        case .low:
            return "Low"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        case .sleepRisk:
            return "Sleep Risk"
        }
    }
}
