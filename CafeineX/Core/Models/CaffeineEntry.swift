//
//  CaffeineEntry.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import Foundation
import SwiftData

@Model
final class CaffeineEntry {
    var id: UUID
    var drinkName: String
    var caffeineMG: Double
    var consumedAt: Date
    var sourceRawValue: String
    var healthKitUUIDString: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        drinkName: String,
        caffeineMG: Double,
        consumedAt: Date = .now,
        source: CaffeineSource = .manual,
        healthKitUUID: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.drinkName = drinkName
        self.caffeineMG = caffeineMG
        self.consumedAt = consumedAt
        self.sourceRawValue = source.rawValue
        self.healthKitUUIDString = healthKitUUID?.uuidString
        self.createdAt = createdAt
    }
    
    var source: CaffeineSource {
        CaffeineSource(rawValue: sourceRawValue) ?? .manual
    }

    var healthKitUUID: UUID? {
        get {
            guard let healthKitUUIDString else { return nil }
            return UUID(uuidString: healthKitUUIDString)
        }
        set {
            healthKitUUIDString = newValue?.uuidString
        }
    }

    var dose: CaffeineDose {
        CaffeineDose(amountMG: caffeineMG, consumedAt: consumedAt)
    }
}

enum CaffeineSource: String, Codable, Sendable {
    case manual
    case appleWatch
    case siri
    case widget
    case healthKit
}
