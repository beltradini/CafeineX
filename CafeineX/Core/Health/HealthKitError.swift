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
    case caffeineDeletionFailed
    case caffeineLinkUnavailable
    
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
        case .caffeineDeletionFailed:
            return "Apple Health did not confirm deletion of the CafeineX caffeine samples"
        case .caffeineLinkUnavailable:
            return "The entry is saved locally. Its Apple Health link will be checked again during synchronization."
        }
    }
}
