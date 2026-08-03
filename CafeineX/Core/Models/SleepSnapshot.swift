import Foundation

nonisolated enum HealthSleepStage: String, CaseIterable, Sendable {
    case inBed
    case awake
    case asleepUnspecified
    case asleepCore
    case asleepDeep
    case asleepREM

    var isAsleep: Bool {
        switch self {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            true
        case .inBed, .awake:
            false
        }
    }

    var isDetailed: Bool {
        switch self {
        case .asleepCore, .asleepDeep, .asleepREM:
            true
        default:
            false
        }
    }
}

nonisolated struct HealthSleepSample: Equatable, Sendable {
    let id: UUID
    let stage: HealthSleepStage
    let startDate: Date
    let endDate: Date
}

nonisolated struct SleepSnapshot: Equatable, Sendable {
    let sleepStart: Date
    let sleepEnd: Date
    let totalAsleep: TimeInterval
    let timeInBed: TimeInterval?
    let awakeDuration: TimeInterval?
    let detailedStageCoverage: TimeInterval
    let sampleCount: Int
    let stageIntervals: [HealthSleepSample]

    init(
        sleepStart: Date,
        sleepEnd: Date,
        totalAsleep: TimeInterval,
        timeInBed: TimeInterval?,
        awakeDuration: TimeInterval?,
        detailedStageCoverage: TimeInterval,
        sampleCount: Int,
        stageIntervals: [HealthSleepSample] = []
    ) {
        self.sleepStart = sleepStart
        self.sleepEnd = sleepEnd
        self.totalAsleep = totalAsleep
        self.timeInBed = timeInBed
        self.awakeDuration = awakeDuration
        self.detailedStageCoverage = detailedStageCoverage
        self.sampleCount = sampleCount
        self.stageIntervals = stageIntervals
    }

    var hasDetailedStages: Bool {
        detailedStageCoverage > 0
    }

    func isStale(
        relativeTo referenceDate: Date,
        threshold: TimeInterval = 48 * 60 * 60
    ) -> Bool {
        referenceDate.timeIntervalSince(sleepEnd) > threshold
    }
}

nonisolated enum SleepSnapshotBuilder {
    private static let maximumSessionGap: TimeInterval = 3 * 60 * 60

    static func makeLatest(
        from samples: [HealthSleepSample],
        relativeTo referenceDate: Date = .now
    ) -> SleepSnapshot? {
        let validSamples = samples
            .filter {
                $0.startDate < $0.endDate
                    && $0.startDate < referenceDate
                    && $0.endDate <= referenceDate
            }
            .sorted { $0.startDate < $1.startDate }

        guard !validSamples.isEmpty else { return nil }

        var sessions: [[HealthSleepSample]] = []
        var current: [HealthSleepSample] = []
        var currentEnd = Date.distantPast

        for sample in validSamples {
            if current.isEmpty
                || sample.startDate.timeIntervalSince(currentEnd) <= maximumSessionGap {
                current.append(sample)
                currentEnd = max(currentEnd, sample.endDate)
            } else {
                sessions.append(current)
                current = [sample]
                currentEnd = sample.endDate
            }
        }
        if !current.isEmpty {
            sessions.append(current)
        }

        guard let latest = sessions
            .filter({ $0.contains(where: \.stage.isAsleep) })
            .max(by: { sessionEnd($0) < sessionEnd($1) }) else {
            return nil
        }

        let asleepIntervals = latest
            .filter(\.stage.isAsleep)
            .map { DateInterval(start: $0.startDate, end: $0.endDate) }
        let totalAsleep = unionDuration(asleepIntervals)
        guard totalAsleep > 0 else { return nil }

        let inBedDuration = unionDuration(
            latest
                .filter { $0.stage == .inBed }
                .map { DateInterval(start: $0.startDate, end: $0.endDate) }
        )
        let awakeDuration = unionDuration(
            latest
                .filter { $0.stage == .awake }
                .map { DateInterval(start: $0.startDate, end: $0.endDate) }
        )
        let detailedCoverage = unionDuration(
            latest
                .filter(\.stage.isDetailed)
                .map { DateInterval(start: $0.startDate, end: $0.endDate) }
        )

        return SleepSnapshot(
            sleepStart: latest.map(\.startDate).min() ?? .distantPast,
            sleepEnd: latest.map(\.endDate).max() ?? .distantPast,
            totalAsleep: totalAsleep,
            timeInBed: inBedDuration > 0 ? inBedDuration : nil,
            awakeDuration: awakeDuration > 0 ? awakeDuration : nil,
            detailedStageCoverage: detailedCoverage,
            sampleCount: latest.count,
            stageIntervals: latest
        )
    }

    private static func sessionEnd(_ samples: [HealthSleepSample]) -> Date {
        samples.map(\.endDate).max() ?? .distantPast
    }

    private static func unionDuration(_ intervals: [DateInterval]) -> TimeInterval {
        let sorted = intervals.sorted { $0.start < $1.start }
        guard var current = sorted.first else { return 0 }
        var total: TimeInterval = 0

        for interval in sorted.dropFirst() {
            if interval.start <= current.end {
                current = DateInterval(
                    start: current.start,
                    end: max(current.end, interval.end)
                )
            } else {
                total += current.duration
                current = interval
            }
        }
        return total + current.duration
    }
}
