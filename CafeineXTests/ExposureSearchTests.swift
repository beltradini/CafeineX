import Foundation
import Testing
@testable import CafeineX

@MainActor
struct ExposureSearchTests {
    @Test func combinedTimelineSortsDifferentSubstancesByDate() {
        let older = Date(timeIntervalSinceReferenceDate: 1_000)
        let newer = older.addingTimeInterval(60)
        let caffeine = CaffeineEntry(
            drinkName: "Espresso",
            caffeineMG: 64,
            consumedAt: older
        )
        let nicotine = NicotineEntry(
            product: .pouch,
            quantity: 3,
            unit: .milligrams,
            usedAt: newer
        )

        let items = ExposureItem.combined(
            caffeineEntries: [caffeine],
            nicotineEntries: [nicotine]
        )

        #expect(items.count == 2)
        #expect(items.first?.kind == .nicotine)
        #expect(items.last?.kind == .caffeine)
    }

    @Test func searchIsCaseAndDiacriticInsensitiveAndMatchesAllTerms() {
        let caffeine = CaffeineEntry(
            drinkName: "Café Latte",
            caffeineMG: 120,
            source: .manual
        )
        let nicotine = NicotineEntry(
            product: .pouch,
            quantity: 6,
            unit: .milligrams,
            source: .manual,
            note: "Evening"
        )
        let items = ExposureItem.combined(
            caffeineEntries: [caffeine],
            nicotineEntries: [nicotine]
        )

        let results = ExposureSearchEngine().results(
            in: items,
            query: "CAFE 120"
        )

        #expect(results.count == 1)
        #expect(results.first?.title == "Café Latte")
    }

    @Test func substanceScopeFiltersGlobalResults() {
        let caffeine = CaffeineEntry(
            drinkName: "Morning drink",
            caffeineMG: 80
        )
        let nicotine = NicotineEntry(
            product: .vape,
            quantity: 2,
            unit: .puffs,
            note: "Morning"
        )
        let items = ExposureItem.combined(
            caffeineEntries: [caffeine],
            nicotineEntries: [nicotine]
        )

        let results = ExposureSearchEngine().results(
            in: items,
            query: "morning",
            kind: .nicotine
        )

        #expect(results.count == 1)
        #expect(results.first?.kind == .nicotine)
    }

    @Test func healthLinkedCaffeineIsReadOnlyButLocalNicotineIsEditable() {
        let caffeine = CaffeineEntry(
            drinkName: "Synced coffee",
            caffeineMG: 90,
            healthKitUUID: UUID()
        )
        let nicotine = NicotineEntry(
            product: .gum,
            quantity: 2,
            unit: .milligrams
        )

        #expect(!ExposureItem.caffeine(caffeine).canModify)
        #expect(ExposureItem.nicotine(nicotine).canModify)
    }
}
