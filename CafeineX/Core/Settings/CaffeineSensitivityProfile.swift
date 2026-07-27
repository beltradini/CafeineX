import Foundation

nonisolated enum CaffeineSensitivityProfile: String, CaseIterable, Identifiable, Sendable {
    case lower
    case typical
    case higher

    var id: Self { self }

    var title: String {
        switch self {
        case .lower:
            return "Lower"
        case .typical:
            return "Typical"
        case .higher:
            return "Higher"
        }
    }

    var guidanceDescription: String {
        switch self {
        case .lower:
            return "Guidance appears later while the 400 mg general reference stays unchanged."
        case .typical:
            return "Uses CafeineX’s standard response thresholds."
        case .higher:
            return "Guidance appears earlier for active load and caffeine near bedtime."
        }
    }

    var dailyGuidanceFraction: Double {
        switch self {
        case .lower:
            return 0.75
        case .typical:
            return 0.625
        case .higher:
            return 0.5
        }
    }

    var activeLoadGuidanceThresholdMG: Double {
        switch self {
        case .lower:
            return 250
        case .typical:
            return 200
        case .higher:
            return 150
        }
    }

    var bedtimeGuidanceThresholdMG: Double {
        switch self {
        case .lower:
            return 125
        case .typical:
            return 100
        case .higher:
            return 75
        }
    }
}

