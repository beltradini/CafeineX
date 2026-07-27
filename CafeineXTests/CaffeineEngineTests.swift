import Foundation
import Testing
@testable import CafeineX

struct CaffeineEngineTests {
    private let engine = CaffeineEngine()

    @Test func centralEstimateHalvesAfterFiveHours() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let dose = CaffeineDose(amountMG: 200, consumedAt: now.addingTimeInterval(-5 * 3_600))

        let estimate = engine.estimateActiveCaffeine(doses: [dose], currentDate: now)

        #expect(abs(estimate - 100) < 0.001)
    }

    @Test func uncertaintyRangeContainsCentralEstimate() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let dose = CaffeineDose(amountMG: 200, consumedAt: now.addingTimeInterval(-5 * 3_600))

        let estimate = engine.estimateActiveCaffeine(doses: [dose], currentDate: now)
        let range = engine.estimateActiveCaffeineRange(doses: [dose], currentDate: now)

        #expect(range.lowerBound < estimate)
        #expect(range.upperBound > estimate)
    }

    @Test func dailyTotalExcludesPreviousDayAndFutureEntries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 11, hour: 12))!
        let doses = [
            CaffeineDose(amountMG: 80, consumedAt: now.addingTimeInterval(-3_600)),
            CaffeineDose(amountMG: 120, consumedAt: now.addingTimeInterval(-24 * 3_600)),
            CaffeineDose(amountMG: 200, consumedAt: now.addingTimeInterval(3_600)),
        ]

        let status = engine.makeStatus(doses: doses, currentDate: now, calendar: calendar)

        #expect(status.consumedTodayMG == 80)
        #expect(status.activeCaffeineMG < 80)
    }

    @Test func generalReferenceProducesHighGuidance() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let dose = CaffeineDose(amountMG: 400, consumedAt: now)

        let status = engine.makeStatus(doses: [dose], currentDate: now)

        #expect(status.riskLevel == .high)
        #expect(status.dailyProgress == 1)
    }

    @Test func lateDoseProducesSleepGuidanceWhenSlowEstimateStaysElevated() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 11, hour: 16))!
        let dose = CaffeineDose(amountMG: 200, consumedAt: now)

        let status = engine.makeStatus(doses: [dose], currentDate: now, calendar: calendar)

        #expect(status.riskLevel == .sleepRisk)
        #expect(status.caffeineAtBedtimeHighMG >= 100)
    }

    @Test func negativeAmountsDoNotAffectCalculations() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let dose = CaffeineDose(amountMG: -50, consumedAt: now)

        let status = engine.makeStatus(doses: [dose], currentDate: now)

        #expect(status.consumedTodayMG == 0)
        #expect(status.activeCaffeineMG == 0)
    }

    @Test func customBedtimeUsesHourAndMinute() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 27, hour: 12)
        )!
        let schedule = SleepSchedule(
            bedtimeHour: 23,
            bedtimeMinute: 30,
            cutoffHoursBeforeBedtime: 7
        )
        let customEngine = CaffeineEngine(
            configuration: .init(sleepSchedule: schedule)
        )

        let status = customEngine.makeStatus(
            doses: [],
            currentDate: now,
            calendar: calendar
        )
        let bedtimeComponents = calendar.dateComponents(
            [.hour, .minute],
            from: status.targetBedtime
        )
        let cutoffComponents = calendar.dateComponents(
            [.hour, .minute],
            from: status.suggestedCutoffTime
        )

        #expect(bedtimeComponents.hour == 23)
        #expect(bedtimeComponents.minute == 30)
        #expect(cutoffComponents.hour == 16)
        #expect(cutoffComponents.minute == 30)
    }

    @Test func higherSensitivityShowsSleepGuidanceEarlierWithoutChangingExposureEstimate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 27, hour: 16)
        )!
        let dose = CaffeineDose(amountMG: 180, consumedAt: now)
        let typicalEngine = CaffeineEngine(
            configuration: .init(sensitivity: .typical)
        )
        let higherSensitivityEngine = CaffeineEngine(
            configuration: .init(sensitivity: .higher)
        )

        let typicalStatus = typicalEngine.makeStatus(
            doses: [dose],
            currentDate: now,
            calendar: calendar
        )
        let higherStatus = higherSensitivityEngine.makeStatus(
            doses: [dose],
            currentDate: now,
            calendar: calendar
        )

        #expect(typicalStatus.riskLevel == .low)
        #expect(higherStatus.riskLevel == .sleepRisk)
        #expect(typicalStatus.activeCaffeineMG == higherStatus.activeCaffeineMG)
        #expect(typicalStatus.caffeineAtBedtimeHighMG == higherStatus.caffeineAtBedtimeHighMG)
        #expect(higherStatus.dailyLimitMG == 400)
    }
}
