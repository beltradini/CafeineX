import Foundation
import Testing
@testable import CafeineX

struct CafeineXWidgetSnapshotTests {
    @Test func equalBoundsUseOneValueInsteadOfARepeatedRange() {
        let snapshot = makeSnapshot(low: 64.2, high: 64.4)

        #expect(snapshot.activeRangeText == "64 mg")
    }

    @Test func projectedRangeInterpolatesAndMovesToNearSleepAtCutoff() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let snapshot = makeSnapshot(
            generatedAt: now,
            low: 60,
            high: 80,
            cutoffTime: now.addingTimeInterval(30 * 60),
            bedtime: now.addingTimeInterval(8 * 60 * 60),
            recentExposures: [
                WidgetExposure(
                    id: UUID(),
                    kind: .caffeine,
                    title: "Espresso",
                    amountText: "64 mg",
                    date: now,
                    symbolName: "cup.and.saucer.fill"
                ),
            ],
            points: [
                WidgetActiveRangePoint(date: now, lowMG: 60, highMG: 80),
                WidgetActiveRangePoint(
                    date: now.addingTimeInterval(60 * 60),
                    lowMG: 30,
                    highMG: 40
                ),
            ]
        )

        let projected = snapshot.projected(
            relativeTo: now.addingTimeInterval(30 * 60)
        )

        #expect(projected.activeCaffeineLowMG == 45)
        #expect(projected.activeCaffeineHighMG == 60)
        #expect(projected.state == .nearSleep)
    }

    @Test func oldSnapshotWithoutNewFieldsStillDecodes() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let oldSnapshot = LegacySnapshot(
            generatedAt: now,
            activeCaffeineLowMG: 40,
            activeCaffeineHighMG: 52,
            caffeineTodayMG: 64,
            bedtime: now.addingTimeInterval(8 * 60 * 60),
            cutoffTime: now.addingTimeInterval(60 * 60),
            state: .withinWindow,
            recentExposures: [
                LegacyExposure(
                    id: UUID(),
                    title: "Cigarette",
                    amountText: "1 cigarette",
                    date: now,
                    symbolName: "smoke.fill"
                ),
            ],
            favoriteDrinks: []
        )

        let data = try JSONEncoder().encode(oldSnapshot)
        let decoded = try JSONDecoder().decode(
            CafeineXWidgetSnapshot.self,
            from: data
        )

        #expect(decoded.activeRangePoints.isEmpty)
        #expect(decoded.recentExposures.first?.kind == .nicotine)
    }

    private func makeSnapshot(
        generatedAt: Date = .now,
        low: Double? = nil,
        high: Double? = nil,
        cutoffTime: Date? = nil,
        bedtime: Date? = nil,
        recentExposures: [WidgetExposure] = [],
        points: [WidgetActiveRangePoint] = []
    ) -> CafeineXWidgetSnapshot {
        CafeineXWidgetSnapshot(
            generatedAt: generatedAt,
            activeCaffeineLowMG: low,
            activeCaffeineHighMG: high,
            caffeineTodayMG: 0,
            bedtime: bedtime ?? generatedAt.addingTimeInterval(8 * 60 * 60),
            cutoffTime: cutoffTime ?? generatedAt.addingTimeInterval(60 * 60),
            state: .withinWindow,
            recentExposures: recentExposures,
            favoriteDrinks: [],
            activeRangePoints: points
        )
    }
}

private struct LegacySnapshot: Encodable {
    let generatedAt: Date
    let activeCaffeineLowMG: Double?
    let activeCaffeineHighMG: Double?
    let caffeineTodayMG: Double
    let bedtime: Date
    let cutoffTime: Date
    let state: WidgetWindowState
    let recentExposures: [LegacyExposure]
    let favoriteDrinks: [WidgetFavoriteDrink]
}

private struct LegacyExposure: Encodable {
    let id: UUID
    let title: String
    let amountText: String
    let date: Date
    let symbolName: String
}
