//
//  Drink.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import Foundation
import SwiftData

@Model
final class Drink {
    var id: UUID
    var name: String
    var caffeineMG: Double
    var categoryRawValue: String
    var isFavorite: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        caffeineMG: Double,
        category: DrinkCategory,
        isFavorite: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.caffeineMG = caffeineMG
        self.categoryRawValue = category.rawValue
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
    
    var category: DrinkCategory {
        DrinkCategory(rawValue: categoryRawValue) ?? .coffee
    }
}

enum DrinkCategory: String, Codable, Sendable, CaseIterable {
    case coffee
    case espresso
    case tea
    case energyDrink
    case custom
}
