import Foundation
import Testing
@testable import CafeineX

@MainActor
struct AppearanceStoreTests {
    @Test func selectedAppearancePersistsAcrossStoreInstances() {
        let suiteName = "AppearanceStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstStore = AppearanceStore(defaults: defaults)
        firstStore.setSelection(.light)

        let secondStore = AppearanceStore(defaults: defaults)
        #expect(secondStore.selection == .light)
    }

    @Test func unknownStoredAppearanceFallsBackToSystem() {
        let suiteName = "AppearanceStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set("future-mode", forKey: "appearance.selection")

        let store = AppearanceStore(defaults: defaults)

        #expect(store.selection == .system)
    }
}
