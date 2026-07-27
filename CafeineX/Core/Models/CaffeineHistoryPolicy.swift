import Foundation

nonisolated enum CaffeineHistoryPolicy {
    static let synchronizationLookbackDays = 30
    static let dashboardEntryLimit = 20

    static func synchronizationStartDate(
        relativeTo date: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(
            byAdding: .day,
            value: -synchronizationLookbackDays,
            to: date
        ) ?? .distantPast
    }
}
