import Foundation
import SwiftData

@Model
final class HealthSyncOutboxItem {
    @Attribute(.unique) var entryID: UUID
    var createdAt: Date

    init(
        entryID: UUID,
        createdAt: Date = .now
    ) {
        self.entryID = entryID
        self.createdAt = createdAt
    }
}
