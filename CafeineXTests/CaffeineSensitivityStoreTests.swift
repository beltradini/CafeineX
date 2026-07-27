import Foundation
import Testing
@testable import CafeineX

@MainActor
struct CaffeineSensitivityStoreTests {
    @Test func selectedProfilePersistsAcrossStoreInstances() throws {
        let suiteName = "CaffeineSensitivityStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = CaffeineSensitivityStore(defaults: defaults)
        store.setProfile(.higher)

        let restored = CaffeineSensitivityStore(defaults: defaults)
        #expect(restored.profile == .higher)
    }

    @Test func unknownStoredProfileFallsBackToTypical() throws {
        let suiteName = "CaffeineSensitivityStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set("unsupported", forKey: "caffeine.sensitivityProfile")

        let store = CaffeineSensitivityStore(defaults: defaults)

        #expect(store.profile == .typical)
    }
}

