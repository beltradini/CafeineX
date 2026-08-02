import Foundation

nonisolated struct CigaretteEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let usedAt: Date
    let quantity: Double
    let context: CigaretteContext?
}

nonisolated struct CigaretteIntelligenceSummary: Equatable, Sendable {
    let cigarettesToday: Double
    let eventsToday: Int
    let latestEventAt: Date?
    let averageGap: TimeInterval?
    let longestGap: TimeInterval?
    let caffeinePairingsToday: Int
    let sleepWindowEventsToday: Int
    let mostFrequentContext: CigaretteContext?
    let currentWeekCigarettes: Double
    let previousWeekCigarettes: Double

    var weeklyDifference: Double {
        currentWeekCigarettes - previousWeekCigarettes
    }
}

nonisolated struct CigaretteEngine: Sendable {
    struct Configuration: Sendable {
        var pairingWindow: TimeInterval = 30 * 60
        var sleepProtectionWindow: TimeInterval = 4 * 60 * 60
        var sleepSchedule: SleepSchedule = .default
    }

    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    func makeSummary(
        cigaretteEvents: [CigaretteEvent],
        caffeineDoses: [CaffeineDose],
        currentDate: Date = .now,
        calendar: Calendar = .current
    ) -> CigaretteIntelligenceSummary {
        let events = cigaretteEvents
            .filter { $0.usedAt <= currentDate }
            .sorted { $0.usedAt < $1.usedAt }
        let today = events.filter { calendar.isDate($0.usedAt, inSameDayAs: currentDate) }
        let todayCaffeine = caffeineDoses.filter {
            $0.consumedAt <= currentDate && calendar.isDate($0.consumedAt, inSameDayAs: currentDate)
        }
        let gaps = zip(events, events.dropFirst()).map { $1.usedAt.timeIntervalSince($0.usedAt) }
        let bedtime = configuration.sleepSchedule.nextBedtime(relativeTo: currentDate, calendar: calendar)
        let sleepStart = bedtime.addingTimeInterval(-configuration.sleepProtectionWindow)
        let pairings = today.reduce(into: 0) { count, event in
            if todayCaffeine.contains(where: {
                abs($0.consumedAt.timeIntervalSince(event.usedAt)) <= configuration.pairingWindow
            }) {
                count += 1
            }
        }
        let contexts = Dictionary(grouping: today.compactMap(\.context), by: { $0 })
        let frequentContext = contexts.max { lhs, rhs in lhs.value.count < rhs.value.count }?.key
        let week = calendar.dateInterval(of: .weekOfYear, for: currentDate)
        let previousWeek = week.flatMap {
            calendar.dateInterval(of: .weekOfYear, for: $0.start.addingTimeInterval(-1))
        }

        return CigaretteIntelligenceSummary(
            cigarettesToday: today.reduce(0) { $0 + $1.quantity },
            eventsToday: today.count,
            latestEventAt: events.last?.usedAt,
            averageGap: gaps.isEmpty ? nil : gaps.reduce(0, +) / Double(gaps.count),
            longestGap: gaps.max(),
            caffeinePairingsToday: pairings,
            sleepWindowEventsToday: today.filter { $0.usedAt >= sleepStart && $0.usedAt <= bedtime }.count,
            mostFrequentContext: frequentContext,
            currentWeekCigarettes: total(in: week, events: events),
            previousWeekCigarettes: total(in: previousWeek, events: events)
        )
    }

    private func total(in interval: DateInterval?, events: [CigaretteEvent]) -> Double {
        guard let interval else { return 0 }
        return events.filter { interval.contains($0.usedAt) }.reduce(0) { $0 + $1.quantity }
    }
}
