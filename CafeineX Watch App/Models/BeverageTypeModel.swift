//
//  BeverageTypeModel.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import SwiftData

@Model
final class BeverageTypeModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var caffeineMg: Double
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        name: String,
        caffeineMg: Double,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.caffeineMg = caffeineMg
        self.isFavorite = isFavorite
    }
}
