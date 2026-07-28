import Foundation

nonisolated enum DailyExposureGuidance: String, Codable, Sendable {
    case clear
    case caffeineOnly
    case nicotineOnly
    case temporalOverlap
    case sleepPriority

    var title: String {
        switch self {
        case .clear: "No exposure logged"
        case .caffeineOnly: "Caffeine context"
        case .nicotineOnly: "Nicotine context"
        case .temporalOverlap: "Overlapping windows"
        case .sleepPriority: "Sleep priority"
        }
    }

    var message: String {
        switch self {
        case .clear:
            "Log an event to build your daily exposure context."
        case .caffeineOnly:
            "Only caffeine is represented in the current observation window."
        case .nicotineOnly:
            "Only nicotine is represented in the current observation window."
        case .temporalOverlap:
            "Caffeine and nicotine observation windows overlap. Their quantities remain separate; use this timing context to notice your response."
        case .sleepPriority:
            "A logged stimulant event is close to your planned bedtime. Consider pausing and prioritizing your sleep routine."
        }
    }
}

nonisolated struct DailyExposureContext: Sendable {
    let caffeineStatus: CaffeineStatus
    let nicotineStatus: NicotineStatus
    let temporalOverlapCount: Int
    let guidance: DailyExposureGuidance

    var hasTemporalOverlap: Bool {
        temporalOverlapCount > 0
    }

    static func make(
        caffeineDoses: [CaffeineDose],
        nicotineEvents: [NicotineEvent],
        currentDate: Date = .now,
        calendar: Calendar = .current,
        sleepSchedule: SleepSchedule = .default,
        caffeineWindowHours: Double = 6,
        caffeineEngine suppliedCaffeineEngine: CaffeineEngine? = nil
    ) -> DailyExposureContext {
        let caffeineEngine = suppliedCaffeineEngine ?? CaffeineEngine(
            configuration: .init(sleepSchedule: sleepSchedule)
        )
        let nicotineEngine = NicotineEngine(
            configuration: .init(sleepSchedule: sleepSchedule)
        )
        let caffeineStatus = caffeineEngine.makeStatus(
            doses: caffeineDoses,
            currentDate: currentDate,
            calendar: calendar
        )
        let nicotineStatus = nicotineEngine.makeStatus(
            events: nicotineEvents,
            currentDate: currentDate,
            calendar: calendar
        )

        let startOfDay = calendar.startOfDay(for: currentDate)
        let eligibleDoses = caffeineDoses.filter { dose in
            let end = dose.consumedAt.addingTimeInterval(
                max(caffeineWindowHours, 0) * 3_600
            )
            return dose.consumedAt <= currentDate && end >= startOfDay
        }
        let eligibleNicotine = nicotineEvents.filter { event in
            event.usedAt <= currentDate
                && nicotineEngine.observationWindow(for: event).upperBound >= startOfDay
        }
        let overlapCount = eligibleDoses.reduce(0) { count, dose in
            let caffeineEnd = dose.consumedAt.addingTimeInterval(
                max(caffeineWindowHours, 0) * 3_600
            )
            let caffeineWindow = dose.consumedAt...caffeineEnd
            return count + eligibleNicotine.count { event in
                windowsOverlap(
                    caffeineWindow,
                    nicotineEngine.observationWindow(for: event),
                    through: currentDate
                )
            }
        }

        let guidance: DailyExposureGuidance
        if caffeineStatus.riskLevel == .sleepRisk
            || nicotineStatus.sleepGuidance == .nearBedtime {
            guidance = .sleepPriority
        } else if overlapCount > 0 {
            guidance = .temporalOverlap
        } else if !eligibleDoses.isEmpty {
            guidance = .caffeineOnly
        } else if !eligibleNicotine.isEmpty {
            guidance = .nicotineOnly
        } else {
            guidance = .clear
        }

        return DailyExposureContext(
            caffeineStatus: caffeineStatus,
            nicotineStatus: nicotineStatus,
            temporalOverlapCount: overlapCount,
            guidance: guidance
        )
    }

    private static func windowsOverlap(
        _ lhs: ClosedRange<Date>,
        _ rhs: ClosedRange<Date>,
        through currentDate: Date
    ) -> Bool {
        max(lhs.lowerBound, rhs.lowerBound)
            <= min(min(lhs.upperBound, rhs.upperBound), currentDate)
    }
}
