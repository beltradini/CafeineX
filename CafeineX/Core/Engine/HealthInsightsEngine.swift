import Foundation

nonisolated enum HealthInsightTone: Sendable {
    case neutral
    case supportive
    case attention
    case incomplete
}

nonisolated struct HealthInsight: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let message: String
    let symbol: String
    let tone: HealthInsightTone
}

nonisolated struct HealthInsightsSummary: Equatable, Sendable {
    let snapshot: SleepSnapshot
    let insights: [HealthInsight]

    static let limitationText =
        "These observations show timing alongside recorded sleep. They do not establish cause, diagnose a condition, or measure sleep quality."
}

nonisolated struct HealthInsightsEngine {
    func makeSummary(
        snapshot: SleepSnapshot,
        caffeineDoses: [CaffeineDose],
        nicotineEvents: [NicotineEvent],
        cutoffHoursBeforeSleep: Int,
        referenceDate: Date = .now
    ) -> HealthInsightsSummary {
        let cutoffHours = max(1, cutoffHoursBeforeSleep)
        let contextStart = snapshot.sleepStart.addingTimeInterval(
            -Double(cutoffHours) * 60 * 60
        )
        let caffeineBeforeSleep = caffeineDoses.filter {
            $0.amountMG > 0
                && $0.consumedAt >= contextStart
                && $0.consumedAt < snapshot.sleepStart
        }
        let nicotineBeforeSleep = nicotineEvents.filter {
            $0.quantity > 0
                && $0.usedAt >= contextStart
                && $0.usedAt < snapshot.sleepStart
        }

        var insights = [
            HealthInsight(
                id: "latest-sleep",
                title: snapshot.isStale(relativeTo: referenceDate)
                    ? "Last available sleep"
                    : "Recent sleep snapshot",
                message: sleepSummary(snapshot),
                symbol: "moon.stars.fill",
                tone: snapshot.isStale(relativeTo: referenceDate)
                    ? .incomplete
                    : .neutral
            ),
        ]

        if caffeineBeforeSleep.isEmpty {
            insights.append(
                HealthInsight(
                    id: "caffeine-window",
                    title: "No caffeine logged in the context window",
                    message: "CafeineX has no caffeine event recorded in the \(cutoffHours) hours before this sleep period. Missing or unimported entries can change this view.",
                    symbol: "cup.and.heat.waves",
                    tone: .supportive
                )
            )
        } else {
            insights.append(
                HealthInsight(
                    id: "caffeine-window",
                    title: "Caffeine timing to review",
                    message: "\(caffeineBeforeSleep.count) caffeine \(eventWord(caffeineBeforeSleep.count)) \(wasWere(caffeineBeforeSleep.count)) logged in the \(cutoffHours) hours before this sleep period. This is an overlap in timing, not evidence that caffeine changed your sleep.",
                    symbol: "clock.badge.exclamationmark",
                    tone: .attention
                )
            )
        }

        if !nicotineBeforeSleep.isEmpty {
            insights.append(
                HealthInsight(
                    id: "nicotine-window",
                    title: "Nicotine timing to review",
                    message: "\(nicotineBeforeSleep.count) nicotine \(eventWord(nicotineBeforeSleep.count)) \(wasWere(nicotineBeforeSleep.count)) logged in the same pre-sleep window. Amounts remain separate because products and units are not directly comparable.",
                    symbol: "leaf.fill",
                    tone: .attention
                )
            )
        }

        if !snapshot.hasDetailedStages || snapshot.timeInBed == nil {
            insights.append(
                HealthInsight(
                    id: "sleep-detail-coverage",
                    title: "Some sleep details are unavailable",
                    message: "Apple Health supplied enough data for asleep time, but not every optional stage or in-bed detail. CafeineX will not infer missing values.",
                    symbol: "ellipsis.circle",
                    tone: .incomplete
                )
            )
        }

        return HealthInsightsSummary(snapshot: snapshot, insights: insights)
    }

    private func sleepSummary(_ snapshot: SleepSnapshot) -> String {
        let duration = Duration.seconds(snapshot.totalAsleep)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        let period = "\(snapshot.sleepStart.formatted(date: .abbreviated, time: .shortened))–\(snapshot.sleepEnd.formatted(date: .omitted, time: .shortened))"
        return "Apple Health recorded \(duration) asleep during \(period). CafeineX presents the recorded interval without rating it as good or poor."
    }

    private func eventWord(_ count: Int) -> String {
        count == 1 ? "event" : "events"
    }

    private func wasWere(_ count: Int) -> String {
        count == 1 ? "was" : "were"
    }
}
