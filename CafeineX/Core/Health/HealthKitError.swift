//
//  HealthKitError.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/29/26.
//

import Foundation

enum HealthKitError: LocalizedError {
    case healthDataUnavailable
    case caffeineNotAvailable
    case sleepAnalysisNotAvailable
    case invalidCaffeineAmount
    
    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Health data is not available"
        case .caffeineNotAvailable:
            return "Caffeine is not available"
        case .sleepAnalysisNotAvailable:
            return "Sleep analysis is not available"
        case .invalidCaffeineAmount:
            return "Enter a caffeine amount greater than zero"
        }
    }
}
