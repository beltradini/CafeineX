import Foundation
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct UserProfileStoreTests {
    @Test func resolveCreatesOnePersistentProfileAndPreservesIdentity() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProfile.self,
            configurations: configuration
        )
        let firstContext = ModelContext(container)

        let profile = try UserProfileStore.resolve(in: firstContext)
        try UserProfileStore.save(
            profile,
            displayName: "  Alex  ",
            avatarData: Data([1, 2, 3]),
            goal: .understandPatterns,
            in: firstContext
        )

        let secondContext = ModelContext(container)
        let resolvedAgain = try UserProfileStore.resolve(in: secondContext)

        #expect(resolvedAgain.id == profile.id)
        #expect(resolvedAgain.syncIdentifier == profile.syncIdentifier)
        #expect(resolvedAgain.displayName == "Alex")
        #expect(resolvedAgain.avatarData == Data([1, 2, 3]))
        #expect(resolvedAgain.goal == .understandPatterns)
        #expect(resolvedAgain.syncRevision == 1)
        #expect(
            try secondContext.fetchCount(FetchDescriptor<UserProfile>()) == 1
        )
    }
}
