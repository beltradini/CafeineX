import Foundation
import SwiftData

@Model
final class AwarenessCheckIn {
    var id: UUID
    var day: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        day: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.day = day
        self.createdAt = createdAt
    }
}
