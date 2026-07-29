import Foundation
import SwiftData

enum ProfileGoal: String, CaseIterable, Identifiable, Codable, Sendable {
    case protectSleep
    case understandPatterns
    case reduceLateCaffeine
    case mindfulTracking

    var id: Self { self }

    var title: String {
        switch self {
        case .protectSleep: "Protect my sleep"
        case .understandPatterns: "Understand my patterns"
        case .reduceLateCaffeine: "Reduce late caffeine"
        case .mindfulTracking: "Track with awareness"
        }
    }

    var symbol: String {
        switch self {
        case .protectSleep: "moon.stars.fill"
        case .understandPatterns: "chart.xyaxis.line"
        case .reduceLateCaffeine: "clock.badge.checkmark"
        case .mindfulTracking: "brain.head.profile"
        }
    }
}

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    @Attribute(.externalStorage) var avatarData: Data?
    var goalRawValue: String
    var createdAt: Date
    var updatedAt: Date

    // A stable local identity and revision make the record ready to be
    // associated with an Apple credential and remote revision later.
    var syncIdentifier: UUID
    var syncRevision: Int
    var lastSyncedAt: Date?

    init(
        id: UUID = UUID(),
        displayName: String = "",
        avatarData: Data? = nil,
        goal: ProfileGoal = .protectSleep,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        syncIdentifier: UUID = UUID(),
        syncRevision: Int = 0,
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarData = avatarData
        self.goalRawValue = goal.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncIdentifier = syncIdentifier
        self.syncRevision = syncRevision
        self.lastSyncedAt = lastSyncedAt
    }

    var goal: ProfileGoal {
        get { ProfileGoal(rawValue: goalRawValue) ?? .protectSleep }
        set {
            goalRawValue = newValue.rawValue
            markChanged()
        }
    }

    func markChanged(at date: Date = .now) {
        updatedAt = date
        syncRevision += 1
    }
}
