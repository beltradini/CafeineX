//
//  CaffeineEntry.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import SwiftData

@Model
final class CaffeineEntry: Identifiable, @unchecked Sendable {
    var id: UUID
    var date: Date
    var beverageName: String
    var caffeineMg: Double

    init(id: UUID = UUID(), date: Date = Date(), beverageName: String = "", caffeineMg: Double = 0) {
        self.id = id
        self.date = date
        self.beverageName = beverageName
        self.caffeineMg = caffeineMg
    }
}
