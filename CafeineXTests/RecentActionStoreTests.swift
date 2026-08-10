import Foundation
import Testing
@testable import CafeineX

@MainActor
struct RecentActionStoreTests {
    @Test
    func keepsTheMostRecentTwentyActions() {
        let suiteName = "RecentActionStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = RecentActionStore(defaults: defaults)

        for index in 0..<25 {
            store.record(
                kind: .logged,
                title: "Drink \(index)"
            )
        }

        #expect(store.actions.count == 20)
        #expect(store.actions.first?.title == "Drink 24")
        #expect(store.actions.last?.title == "Drink 5")
    }

    @Test
    func persistsActionsAcrossStoreInstances() {
        let suiteName = "RecentActionPersistenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstStore = RecentActionStore(defaults: defaults)
        firstStore.record(
            kind: .loggedAgain,
            title: "Logged Again Espresso",
            detail: "64 mg"
        )

        let secondStore = RecentActionStore(defaults: defaults)

        #expect(secondStore.actions.count == 1)
        #expect(secondStore.actions.first?.kind == .loggedAgain)
        #expect(secondStore.actions.first?.detail == "64 mg")
    }
}

