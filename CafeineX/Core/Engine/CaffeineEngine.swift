//
//  CaffeineEngine.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import Foundation

struct CaffeineEngine: Sendable {
    struct Configuration: Sendable {
        var dailyReferenceMG: Double = 400
        var centralHalfLifeHours: Double = 5
        var fastHalfLifeHours: Double = 3
        var slowHalfLifeHours: Double = 7
        var targetBedtimeHour: Int = 22
        var cutoffHoursBeforeBedtime: Int = 8
    }

    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    func makeStatus(
        doses: [CaffeineDose],
        currentDate: Date = .now,
        calendar: Calendar = .current
    ) -> CaffeineStatus {
        let todayDoses = doses.filter {
            $0.consumedAt <= currentDate
                && calendar.isDate($0.consumedAt, inSameDayAs: currentDate)
        }

        let consumedToday = todayDoses.reduce(0) { $0 + max($1.amountMG, 0) }

        let activeCaffeine = estimateActiveCaffeine(doses: doses, currentDate: currentDate)
        let activeRange = estimateActiveCaffeineRange(doses: doses, currentDate: currentDate)
        let targetBedtime = targetBedtime(currentDate: currentDate, calendar: calendar)
        let bedtimeRange = estimateActiveCaffeineRange(
            doses: doses,
            currentDate: max(targetBedtime, currentDate)
        )

        let riskLevel = calculateRiskLevel(
            consumedTodayMG: consumedToday,
            activeCaffeineMG: activeCaffeine,
            caffeineAtBedtimeHighMG: bedtimeRange.upperBound,
            currentDate: currentDate,
            suggestedCutoffTime: suggestedCutoffTime(targetBedtime: targetBedtime, calendar: calendar)
        )

        return CaffeineStatus(
            consumedTodayMG: consumedToday,
            activeCaffeineMG: activeCaffeine,
            activeCaffeineLowMG: activeRange.lowerBound,
            activeCaffeineHighMG: activeRange.upperBound,
            caffeineAtBedtimeLowMG: bedtimeRange.lowerBound,
            caffeineAtBedtimeHighMG: bedtimeRange.upperBound,
            dailyLimitMG: configuration.dailyReferenceMG,
            targetBedtime: targetBedtime,
            suggestedCutoffTime: suggestedCutoffTime(targetBedtime: targetBedtime, calendar: calendar),
            riskLevel: riskLevel
        )
    }

    func estimateActiveCaffeine(
        doses: [CaffeineDose],
        currentDate: Date = .now
    ) -> Double {
        estimateRemaining(doses: doses, at: currentDate, halfLifeHours: configuration.centralHalfLifeHours)
    }

    func estimateActiveCaffeineRange(
        doses: [CaffeineDose],
        currentDate: Date = .now
    ) -> ClosedRange<Double> {
        let fast = estimateRemaining(
            doses: doses,
            at: currentDate,
            halfLifeHours: configuration.fastHalfLifeHours
        )
        let slow = estimateRemaining(
            doses: doses,
            at: currentDate,
            halfLifeHours: configuration.slowHalfLifeHours
        )
        return min(fast, slow)...max(fast, slow)
    }

    private func estimateRemaining(
        doses: [CaffeineDose],
        at date: Date,
        halfLifeHours: Double
    ) -> Double {
        guard halfLifeHours > 0 else { return 0 }

        return doses.reduce(0) { total, dose in
            let elapsedHours = date.timeIntervalSince(dose.consumedAt) / 3600

            guard elapsedHours >= 0 else {
                return total
            }

            let remaining = max(dose.amountMG, 0) * pow(0.5, elapsedHours / halfLifeHours)
            return total + max(remaining, 0)
        }
    }

    private func calculateRiskLevel(
        consumedTodayMG: Double,
        activeCaffeineMG: Double,
        caffeineAtBedtimeHighMG: Double,
        currentDate: Date,
        suggestedCutoffTime: Date
    ) -> CaffeineRiskLevel {
        if consumedTodayMG >= configuration.dailyReferenceMG {
            return .high
        }

        if currentDate >= suggestedCutoffTime && caffeineAtBedtimeHighMG >= 100 {
            return .sleepRisk
        }

        if consumedTodayMG >= configuration.dailyReferenceMG * 0.625 || activeCaffeineMG >= 200 {
            return .moderate
        }

        return .low
    }

    private func targetBedtime(
        currentDate: Date,
        calendar: Calendar
    ) -> Date {
        let bedtimeToday = calendar.date(
            bySettingHour: configuration.targetBedtimeHour,
            minute: 0,
            second: 0,
            of: currentDate
        ) ?? currentDate

        if bedtimeToday >= currentDate {
            return bedtimeToday
        }

        return calendar.date(byAdding: .day, value: 1, to: bedtimeToday) ?? bedtimeToday
    }

    private func suggestedCutoffTime(targetBedtime: Date, calendar: Calendar) -> Date {
        calendar.date(
            byAdding: .hour,
            value: -configuration.cutoffHoursBeforeBedtime,
            to: targetBedtime
        ) ?? targetBedtime
    }
}
