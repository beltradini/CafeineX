//
//  CaffeineSummaryService.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/17/26.
//

import Foundation
import SwiftData

struct CafeineXTodaySummary {
    let consumedTodayMG: Double
    let activeLowMG: Double
    let activeHighMG: Double
    let bedtime: Date
    let text: String
}

@MainActor
final class CaffeineSummaryService {
    private let context: ModelContext
    private let sleepSchedule: SleepSchedule
    private let sensitivity: CaffeineSensitivityProfile

    init(
        context: ModelContext,
        sleepSchedule: SleepSchedule,
        sensitivity: CaffeineSensitivityProfile
    ) {
        self.context = context
        self.sleepSchedule = sleepSchedule
        self.sensitivity = sensitivity
    }

    func makeTodaySummary(
        relativeTo date: Date = .now
    ) throws -> CafeineXTodaySummary {
        let startDate = CaffeineHistoryPolicy.synchronizationStartDate(
            relativeTo: date
        )

        let descriptor = FetchDescriptor<CaffeineEntry>(
            predicate: #Predicate {
                $0.consumedAt >= startDate
                    && $0.consumedAt <= date
            },
            sortBy: [SortDescriptor(\.consumedAt, order: .reverse)]
        )

        let entries = try context.fetch(descriptor)

        let engine = CaffeineEngine(
            configuration: .init(
                sleepSchedule: sleepSchedule,
                sensitivity: sensitivity
            )
        )

        // Única lógica de cálculo: CaffeineEngine.
        let status = engine.makeStatus(
            doses: entries.map(\.dose),
            currentDate: date
        )

        let low = Int(status.activeCaffeineLowMG.rounded())
        let high = Int(status.activeCaffeineHighMG.rounded())
        let today = Int(status.consumedTodayMG.rounded())
        let bedtime = status.targetBedtime.formatted(
            date: .omitted,
            time: .shortened
        )

        let text: String

        if entries.isEmpty {
            text = "CafeineX has no recent caffeine records. Your configured sleep time is \(bedtime)."
        } else {
            text = "You logged \(today) milligrams today. Your estimated active caffeine range is \(low) to \(high) milligrams. Your configured sleep time is \(bedtime)."
        }

        return CafeineXTodaySummary(
            consumedTodayMG: status.consumedTodayMG,
            activeLowMG: status.activeCaffeineLowMG,
            activeHighMG: status.activeCaffeineHighMG,
            bedtime: status.targetBedtime,
            text: text
        )
    }
}
