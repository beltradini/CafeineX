import Charts
import SwiftUI

struct HealthInsightsCard: View {
    let state: HomeViewModel.SleepDataState
    let summary: HealthInsightsSummary?
    let message: String?
    let isLoading: Bool
    let connect: () -> Void
    let refresh: () -> Void

    var body: some View {
        CXSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                header
                content
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("health-insights-card")
    }

    private var header: some View {
        HStack(alignment: .top) {
            Label("Sleep Context", systemImage: "moon.stars.fill")
                .font(.headline)
                .foregroundStyle(CXTheme.healthAccent)

            Spacer()

            if state == .available || state == .noData || state == .failed {
                Button("Refresh", action: refresh)
                    .font(.caption.weight(.semibold))
                    .disabled(isLoading)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .unavailable:
            stateMessage(
                title: "Apple Health unavailable",
                text: "Sleep context requires HealthKit on a supported device.",
                symbol: "heart.slash"
            )
        case .notRequested:
            stateMessage(
                title: "Add optional sleep context",
                text: "Allow read-only access to recent sleep analysis. CafeineX keeps the snapshot in memory and does not copy sleep samples into its database.",
                symbol: "lock.shield"
            )
            Button("Choose Sleep Access", action: connect)
                .buttonStyle(.borderedProminent)
                .tint(CXTheme.healthAccent)
                .accessibilityIdentifier("choose-sleep-access-button")
        case .loading:
            HStack(spacing: 12) {
                ProgressView()
                Text("Reading the latest available sleep period…")
                    .foregroundStyle(.secondary)
            }
        case .noData:
            stateMessage(
                title: "No readable recent sleep data",
                text: "This can mean there are no completed sleep samples in the last 14 days, access is limited, or read access was not granted. HealthKit does not reveal which applies.",
                symbol: "questionmark.circle"
            )
        case .failed:
            stateMessage(
                title: "Sleep context unavailable",
                text: message ?? "CafeineX could not read recent sleep data.",
                symbol: "exclamationmark.triangle"
            )
        case .available:
            if let summary {
                availableContent(summary)
            }
        }
    }

    private func availableContent(_ summary: HealthInsightsSummary) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            sleepHero(summary.snapshot)

            SleepStageTimelineView(snapshot: summary.snapshot)

            sleepMetrics(summary.snapshot)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(summary.insights.filter { $0.id != "latest-sleep" }) { insight in
                    insightRow(insight)
                    if insight.id != summary.insights.filter({ $0.id != "latest-sleep" }).last?.id {
                        Divider()
                    }
                }
            }

            Text(HealthInsightsSummary.limitationText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sleepHero(_ snapshot: SleepSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(durationText(snapshot.totalAsleep))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)

                Text("asleep")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(snapshot.sleepStart.formatted(date: .abbreviated, time: .shortened)
                + " – "
                + snapshot.sleepEnd.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Label("Apple Health", systemImage: "heart.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(CXTheme.healthAccent)
        }
    }

    private func sleepMetrics(_ snapshot: SleepSnapshot) -> some View {
        HStack(spacing: 8) {
            metric(
                title: "Asleep",
                value: durationText(snapshot.totalAsleep),
                symbol: "moon.fill",
                tint: CXTheme.healthAccent
            )
            metric(
                title: "In bed",
                value: snapshot.timeInBed.map(durationText) ?? "—",
                symbol: "bed.double.fill",
                tint: .secondary
            )
            metric(
                title: "Awake",
                value: snapshot.awakeDuration.map(durationText) ?? "—",
                symbol: "sun.max.fill",
                tint: CXTheme.warningAccent
            )
        }
    }

    private func metric(
        title: String,
        value: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func stateMessage(
        title: String,
        text: String,
        symbol: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func insightRow(_ insight: HealthInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.symbol)
                .foregroundStyle(tint(for: insight.tone))
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func tint(for tone: HealthInsightTone) -> Color {
        switch tone {
        case .neutral: .secondary
        case .supportive: CXTheme.healthAccent
        case .attention: CXTheme.warningAccent
        case .incomplete: .secondary
        }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

struct SleepStageTimelineView: View {
    let snapshot: SleepSnapshot

    @State private var selectedDate: Date?

    private var selectedInterval: HealthSleepSample? {
        guard let selectedDate else { return nil }
        return snapshot.stageIntervals.first {
            $0.startDate <= selectedDate && selectedDate <= $0.endDate
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sleep stages")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let selectedInterval {
                    Text(selectedInterval.stage.chartLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedInterval.stage.chartColor)
                }
            }

            if snapshot.stageIntervals.isEmpty {
                Text("Apple Health provided sleep timing without stage intervals.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(snapshot.stageIntervals, id: \.id) { interval in
                    BarMark(
                        xStart: .value("Start", interval.startDate),
                        xEnd: .value("End", interval.endDate),
                        y: .value("Stage", interval.stage.chartLabel)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .foregroundStyle(interval.stage.chartColor)
                }
                .chartXScale(domain: snapshot.sleepStart...snapshot.sleepEnd)
                .chartYScale(domain: HealthSleepStage.chartLabels)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                }
                .frame(height: 118)
                .chartXSelection(value: $selectedDate)
                .accessibilityLabel("Sleep stages timeline")
                .accessibilityValue(accessibilityValue)
            }

            HStack(spacing: 10) {
                ForEach(HealthSleepStage.chartLegendStages, id: \.self) { stage in
                    Label(stage.chartLabel, systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(stage.chartColor)
                        .labelStyle(.titleAndIcon)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    private var accessibilityValue: String {
        guard let selectedInterval else {
            return "Recorded sleep stages from \(snapshot.sleepStart.formatted(date: .omitted, time: .shortened)) to \(snapshot.sleepEnd.formatted(date: .omitted, time: .shortened))"
        }
        return "Selected \(selectedInterval.stage.chartLabel), from \(selectedInterval.startDate.formatted(date: .omitted, time: .shortened)) to \(selectedInterval.endDate.formatted(date: .omitted, time: .shortened))"
    }
}

private extension HealthSleepStage {
    static let chartLabels = ["Awake", "REM", "Core", "Deep", "Asleep", "In Bed"]
    static let chartLegendStages: [Self] = [.asleepREM, .asleepCore, .asleepDeep, .awake]

    var chartLabel: String {
        switch self {
        case .inBed: "In Bed"
        case .awake: "Awake"
        case .asleepUnspecified: "Asleep"
        case .asleepCore: "Core"
        case .asleepDeep: "Deep"
        case .asleepREM: "REM"
        }
    }

    var chartColor: Color {
        switch self {
        case .inBed: .secondary.opacity(0.35)
        case .awake: CXTheme.warningAccent
        case .asleepUnspecified: CXTheme.healthAccent.opacity(0.7)
        case .asleepCore: Color(red: 0.36, green: 0.62, blue: 0.95)
        case .asleepDeep: Color(red: 0.22, green: 0.34, blue: 0.78)
        case .asleepREM: Color(red: 0.62, green: 0.42, blue: 0.92)
        }
    }
}
