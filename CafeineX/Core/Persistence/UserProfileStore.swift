import Foundation
import SwiftData

@MainActor
enum UserProfileStore {
    static func resolve(in context: ModelContext) throws -> UserProfile {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        descriptor.fetchLimit = 1

        if let profile = try context.fetch(descriptor).first {
            return profile
        }

        let profile = UserProfile()
        context.insert(profile)
        try context.save()
        return profile
    }

    static func save(
        _ profile: UserProfile,
        displayName: String,
        avatarData: Data?,
        goal: ProfileGoal,
        in context: ModelContext,
        changedAt: Date = .now
    ) throws {
        profile.displayName = displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        profile.avatarData = avatarData
        profile.goalRawValue = goal.rawValue
        profile.markChanged(at: changedAt)
        try context.save()
    }
}
