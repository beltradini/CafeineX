import Foundation
import Testing
@testable import CafeineX

struct HealthInsightsEngineTests {
    @Test func timingInsightsKeepSubstancesSeparateAndRejectCausalLanguage() throws {
        let sleepStart = Date(timeIntervalSince1970: 1_754_000_000)
        let snapshot = SleepSnapshot(
            sleepStart: sleepStart,
            sleepEnd: sleepStart.addingTimeInterval(7 * 60 * 60),
            totalAsleep: 6.5 * 60 * 60,
            timeInBed: 7 * 60 * 60,
            awakeDuration: 30 * 60,
            detailedStageCoverage: 6 * 60 * 60,
            sampleCount: 8
        )
        let caffeine = CaffeineDose(
            amountMG: 120,
            consumedAt: sleepStart.addingTimeInterval(-2 * 60 * 60)
        )
        let nicotine = NicotineEvent(
            id: UUID(),
            product: .pouch,
            quantity: 4,
            unit: .milligrams,
            usedAt: sleepStart.addingTimeInterval(-60 * 60)
        )

        let summary = HealthInsightsEngine().makeSummary(
            snapshot: snapshot,
            caffeineDoses: [caffeine],
            nicotineEvents: [nicotine],
            cutoffHoursBeforeSleep: 6,
            referenceDate: snapshot.sleepEnd.addingTimeInterval(60 * 60)
        )

        let caffeineInsight = try #require(
            summary.insights.first { $0.id == "caffeine-window" }
        )
        let nicotineInsight = try #require(
            summary.insights.first { $0.id == "nicotine-window" }
        )
        #expect(caffeineInsight.message.contains("not evidence"))
        #expect(nicotineInsight.message.contains("remain separate"))
        #expect(!summary.insights.map(\.message).joined().contains("caused poor sleep"))
        #expect(HealthInsightsSummary.limitationText.contains("do not establish cause"))
    }

    @Test func missingOptionalSleepDetailsProduceAnExplicitIncompleteInsight() {
        let sleepStart = Date(timeIntervalSince1970: 1_754_000_000)
        let snapshot = SleepSnapshot(
            sleepStart: sleepStart,
            sleepEnd: sleepStart.addingTimeInterval(7 * 60 * 60),
            totalAsleep: 7 * 60 * 60,
            timeInBed: nil,
            awakeDuration: nil,
            detailedStageCoverage: 0,
            sampleCount: 1
        )

        let summary = HealthInsightsEngine().makeSummary(
            snapshot: snapshot,
            caffeineDoses: [],
            nicotineEvents: [],
            cutoffHoursBeforeSleep: 6,
            referenceDate: snapshot.sleepEnd
        )

        #expect(
            summary.insights.contains {
                $0.id == "sleep-detail-coverage" && $0.tone == .incomplete
            }
        )
        #expect(
            summary.insights.first { $0.id == "caffeine-window" }?.message
                .contains("Missing or unimported entries") == true
        )
    }
}
