import Foundation

nonisolated struct NicotineEngine: Sendable {
    nonisolated struct Configuration: Sendable {
        var defaultObservationWindowHours: Double = 2
        var oralObservationWindowHours: Double = 3
        var patchObservationWindowHours: Double = 24
        var bedtimeGuidanceHours: Int = 4
        var sleepSchedule: SleepSchedule

        init(sleepSchedule: SleepSchedule = .default) {
            self.sleepSchedule = sleepSchedule
        }
    }

    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    func makeStatus(
        events: [NicotineEvent],
        currentDate: Date = .now,
        calendar: Calendar = .current
    ) -> NicotineStatus {
        let pastEvents = events.filter { $0.usedAt <= currentDate }
        let todayEvents = pastEvents.filter {
            calendar.isDate($0.usedAt, inSameDayAs: currentDate)
        }
        let targetBedtime = configuration.sleepSchedule.nextBedtime(
            relativeTo: currentDate,
            calendar: calendar
        )
        let suggestedPauseTime = calendar.date(
            byAdding: .hour,
            value: -configuration.bedtimeGuidanceHours,
            to: targetBedtime
        ) ?? targetBedtime

        var amounts = NicotineAmountSummary()
        todayEvents.forEach {
            amounts.add(quantity: $0.quantity, unit: $0.unit)
        }

        let nearBedtime = pastEvents.contains { event in
            let window = observationWindow(for: event)
            return event.usedAt >= suggestedPauseTime && event.usedAt <= targetBedtime
                || window.contains(targetBedtime)
        }

        let guidance: NicotineSleepGuidance
        if nearBedtime {
            guidance = .nearBedtime
        } else if todayEvents.isEmpty {
            guidance = .noEvents
        } else {
            guidance = .outsideWindow
        }

        return NicotineStatus(
            eventsToday: todayEvents.count,
            amountsToday: amounts,
            activeEventCount: pastEvents.count { observationWindow(for: $0).contains(currentDate) },
            latestEventAt: pastEvents.map(\.usedAt).max(),
            targetBedtime: targetBedtime,
            suggestedPauseTime: suggestedPauseTime,
            sleepGuidance: guidance
        )
    }

    func observationWindow(for event: NicotineEvent) -> ClosedRange<Date> {
        let hours: Double
        switch event.product {
        case .pouch, .gum, .lozenge:
            hours = configuration.oralObservationWindowHours
        case .patch:
            hours = configuration.patchObservationWindowHours
        case .cigarette, .cigar, .vape, .other:
            hours = configuration.defaultObservationWindowHours
        }

        let safeHours = max(hours, 0)
        let end = event.usedAt.addingTimeInterval(safeHours * 3_600)
        return event.usedAt...end
    }
}
