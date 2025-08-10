//
//  CaffeineEntryModel.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/29/25.
//

import Foundation
import SwiftData

@Model
final class CaffeineEntryModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var beverageName: String
    var caffeineMg: Double

    init(id: UUID = UUID(), date: Date = Date(), beveragename: String = "", caffeineMg: Double = 0) {
        self.id = id
        self.date = date
        self.beverageName = beveragename
        self.caffeineMg = caffeineMg
    }
}
