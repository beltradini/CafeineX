import Foundation
import SwiftData

@MainActor
enum CigaretteLibrary {
    static func bootstrapIfNeeded(
        profiles: [CigaretteProfile],
        preferences: [CigarettePreferences],
        context: ModelContext
    ) throws {
        var changed = false
        if profiles.isEmpty {
            context.insert(
                CigaretteProfile(
                    name: "My Cigarette",
                    isFavorite: true,
                    favoriteOrder: 0
                )
            )
            changed = true
        }
        if preferences.isEmpty {
            context.insert(CigarettePreferences())
            changed = true
        }
        if changed { try context.save() }
    }

    static func recordUse(
        profileID: UUID?,
        at date: Date,
        profiles: [CigaretteProfile]
    ) {
        guard let profileID, let profile = profiles.first(where: { $0.id == profileID }) else { return }
        profile.useCount += 1
        profile.lastUsedAt = date
        profile.updatedAt = .now
    }

    static func archive(_ profile: CigaretteProfile) {
        profile.isArchived = true
        profile.archivedAt = .now
        profile.isFavorite = false
        profile.favoriteOrder = nil
        profile.updatedAt = .now
    }
}
