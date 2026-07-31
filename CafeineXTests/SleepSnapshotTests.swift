import Foundation
import Testing
@testable import CafeineX

struct SleepSnapshotTests {
    @Test func latestCompletedSessionMergesOverlapsWithoutDoubleCounting() throws {
        let reference = date(2026, 7, 30, 12)
        let samples = [
            sample(.asleepUnspecified, 2026, 7, 28, 23, endDay: 29, endHour: 6),
            sample(.inBed, 2026, 7, 29, 22, endDay: 30, endHour: 7),
            sample(.asleepCore, 2026, 7, 29, 23, endDay: 30, endHour: 2),
            sample(.asleepCore, 2026, 7, 29, 23, endDay: 30, endHour: 2),
            sample(.asleepDeep, 2026, 7, 30, 1, endDay: 30, endHour: 3),
            sample(.asleepREM, 2026, 7, 30, 3, endDay: 30, endHour: 5),
            sample(.asleepUnspecified, 2026, 7, 30, 5, endDay: 30, endHour: 6),
            sample(.awake, 2026, 7, 30, 6, endDay: 30, endHour: 7),
        ]

        let snapshot = try #require(
            SleepSnapshotBuilder.makeLatest(
                from: samples,
                relativeTo: reference
            )
        )

        #expect(snapshot.sleepStart == date(2026, 7, 29, 22))
        #expect(snapshot.sleepEnd == date(2026, 7, 30, 7))
        #expect(snapshot.totalAsleep == 7 * 60 * 60)
        #expect(try #require(snapshot.timeInBed) == TimeInterval(9 * 60 * 60))
        #expect(try #require(snapshot.awakeDuration) == TimeInterval(60 * 60))
        #expect(snapshot.detailedStageCoverage == 6 * 60 * 60)
        #expect(snapshot.hasDetailedStages)
    }

    @Test func futureAndAwakeOnlySamplesNeverCreateASnapshot() {
        let reference = date(2026, 7, 30, 12)
        let samples = [
            sample(.awake, 2026, 7, 30, 8, endDay: 30, endHour: 9),
            sample(.asleepCore, 2026, 7, 30, 23, endDay: 31, endHour: 2),
        ]

        #expect(
            SleepSnapshotBuilder.makeLatest(
                from: samples,
                relativeTo: reference
            ) == nil
        )
    }

    private func sample(
        _ stage: HealthSleepStage,
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        endDay: Int,
        endHour: Int
    ) -> HealthSleepSample {
        HealthSleepSample(
            id: UUID(),
            stage: stage,
            startDate: date(year, month, day, hour),
            endDate: date(year, month, endDay, endHour)
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
}
