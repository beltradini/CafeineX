import Foundation
import SwiftData

@Model
final class DrinkMetadata {
    @Attribute(.unique) var drinkID: UUID
    var isArchived: Bool
    var useCount: Int
    var lastUsedAt: Date?
    var updatedAt: Date

    init(
        drinkID: UUID,
        isArchived: Bool = false,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.drinkID = drinkID
        self.isArchived = isArchived
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.updatedAt = updatedAt
    }
}
