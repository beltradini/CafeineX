import Foundation
import HealthKit
import Observation
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    private struct DrinkUsageSnapshot {
        let details: DrinkDetails
        let useCount: Int
        let lastUsedAt: Date?
    }

    struct Feedback: Equatable, Identifiable {
        let id = UUID()
        let entryID: UUID
        let message: String
        let kind: Kind

        enum Kind: Equatable {
            case caffeine
            case nicotine
        }
    }

    enum HealthAccessState: Equatable {
        case unavailable
        case notRequested
        case writeEnabled
        case writeDisabled
    }

    enum SleepDataState: Equatable {
        case unavailable
        case notRequested
        case loading
        case noData
        case available
        case failed
    }

    private var engine: CaffeineEngine
    private var recentActions: RecentActionStore?
    private var sleepSchedule: SleepSchedule = .default
    private let healthKitService: any HealthKitProviding
    private let persistenceIssueCenter: PersistenceIssueCenter?
    private var pendingHealthWrites: [UUID: Task<Void, Never>] = [:]
    private var pendingDrinkUsage: [UUID: DrinkUsageSnapshot] = [:]

    var entries: [CaffeineEntry] = []
    var nicotineEntries: [NicotineEntry] = []
    var status: CaffeineStatus?
    var nicotineStatus: NicotineStatus?
    var dailyExposureContext: DailyExposureContext?
    var healthAccessState: HealthAccessState = .notRequested
    var healthMessage: String?
    var isSyncingHealth = false
    var lastHealthSyncDate: Date?
    var sleepDataState: SleepDataState = .notRequested
    var sleepSnapshot: SleepSnapshot?
    var healthInsightsSummary: HealthInsightsSummary?
    var sleepDataMessage: String?
    var isLoadingSleep = false
    var feedback: Feedback?

    init(
        persistenceIssueCenter: PersistenceIssueCenter? = nil,
        recentActions: RecentActionStore? = nil
    ) {
        self.engine = CaffeineEngine()
        self.recentActions = recentActions
        self.healthKitService = HealthKitService()
        self.persistenceIssueCenter = persistenceIssueCenter
        refreshHealthAccessState()
    }

    init(
        engine: CaffeineEngine,
        healthKitService: any HealthKitProviding,
        persistenceIssueCenter: PersistenceIssueCenter? = nil,
        recentActions: RecentActionStore? = nil
    ) {
        self.engine = engine
        self.healthKitService = healthKitService
        self.persistenceIssueCenter = persistenceIssueCenter
        self.recentActions = recentActions
        refreshHealthAccessState()
    }

    func load(
        entries: [CaffeineEntry],
        nicotineEntries: [NicotineEntry] = []
    ) {
        self.entries = entries
        self.nicotineEntries = nicotineEntries
        recalculateStatus()
    }

    func attachRecentActionStore(_ store: RecentActionStore) {
        recentActions = store
    }

    func updatePreferences(
        sleepSchedule: SleepSchedule,
        sensitivity: CaffeineSensitivityProfile
    ) {
        self.sleepSchedule = sleepSchedule
        engine = CaffeineEngine(
            configuration: CaffeineEngine.Configuration(
                sleepSchedule: sleepSchedule,
                sensitivity: sensitivity
            )
        )
        recalculateStatus()
    }

    func refreshHealthAccessState() {
        guard healthKitService.isHealthKitAvailable else {
            healthAccessState = .unavailable
            return
        }

        switch healthKitService.caffeineWriteAuthorizationStatus {
        case .notDetermined:
            healthAccessState = .notRequested
        case .sharingAuthorized:
            healthAccessState = .writeEnabled
        case .sharingDenied:
            healthAccessState = .writeDisabled
        @unknown default:
            healthAccessState = .notRequested
        }
    }

    func requestHealthAccess(context: ModelContext) async {
        do {
            try await healthKitService.requestCaffeineAuthorization()
            refreshHealthAccessState()
            await synchronizeHealthKit(context: context)
        } catch {
            refreshHealthAccessState()
            healthMessage = error.localizedDescription
        }
    }

    func refreshSleepContext() async {
        guard healthKitService.isHealthKitAvailable else {
            sleepDataState = .unavailable
            sleepSnapshot = nil
            healthInsightsSummary = nil
            return
        }

        do {
            let requestStatus = try await healthKitService
                .sleepAuthorizationRequestStatus()
            switch requestStatus {
            case .shouldRequest:
                sleepDataState = .notRequested
                sleepSnapshot = nil
                healthInsightsSummary = nil
            case .unnecessary, .unknown:
                await refreshSleepSnapshot()
            @unknown default:
                sleepDataState = .notRequested
            }
        } catch {
            sleepDataState = .failed
            sleepDataMessage = "CafeineX could not check sleep access."
        }
    }

    func requestSleepAccess() async {
        guard !isLoadingSleep else { return }
        isLoadingSleep = true
        sleepDataState = .loading
        defer { isLoadingSleep = false }

        do {
            try await healthKitService.requestSleepAuthorization()
            await loadSleepSnapshot()
        } catch {
            sleepDataState = .failed
            sleepDataMessage = "CafeineX could not request sleep access."
        }
    }

    func refreshSleepSnapshot() async {
        guard !isLoadingSleep else { return }
        isLoadingSleep = true
        sleepDataState = .loading
        defer { isLoadingSleep = false }
        await loadSleepSnapshot()
    }

    func synchronizeHealthKit(context: ModelContext) async {
        guard healthAccessState != .unavailable, !isSyncingHealth else { return }

        isSyncingHealth = true
        defer { isSyncingHealth = false }

        do {
            try await CaffeineHealthOperationCoordinator.run {
                await self.performHealthSynchronization(context: context)
            }
        } catch {
            healthMessage = error.localizedDescription
        }
    }

    private func performHealthSynchronization(context: ModelContext) async {
        do {
            entries = try context.fetch(FetchDescriptor<CaffeineEntry>())
            let startDate = CaffeineHistoryPolicy.synchronizationStartDate()
            let samples = try await healthKitService.fetchCaffeineSamples(from: startDate, to: .now)
            let importedCount = reconcile(samples: samples, context: context)
            try context.save()

            var uploadedCount = 0
            if healthAccessState == .writeEnabled {
                let outboxItems = (try? context.fetch(
                    FetchDescriptor<HealthSyncOutboxItem>()
                )) ?? []
                let pendingIDs = Set(outboxItems.map(\.entryID))
                let pendingEntries = entries.filter {
                    pendingIDs.contains($0.id) && $0.healthKitUUID == nil
                }
                for entry in pendingEntries {
                    await saveToHealthKit(entry, context: context)
                    if entry.healthKitUUID != nil {
                        uploadedCount += 1
                    }
                }
            }

            lastHealthSyncDate = .now
            if importedCount == 0, uploadedCount == 0 {
                healthMessage = "Apple Health is up to date."
            } else {
                healthMessage = "Apple Health updated: \(importedCount) imported, \(uploadedCount) uploaded."
            }
        } catch {
            healthMessage = error.localizedDescription
            reportPersistenceFailure(
                operation: "Saving Apple Health synchronization",
                error: error,
                context: context
            )
        }
    }

    @discardableResult
    func addDrink(
        name: String,
        caffeineMG: Double,
        consumedAt: Date = .now,
        drink: Drink? = nil,
        context: ModelContext,
        actionKind: RecentActionKind = .logged,
        source: CaffeineSource = .manual,
        operationID: UUID = UUID()
    ) -> Bool {
        let receipt: CaffeineLogReceipt
        do {
            receipt = try loggingService(context: context).log(
                CaffeineLogRequest(operationID: operationID, drinkName: name,
                                   caffeineMG: caffeineMG, consumedAt: consumedAt, source: source),
                actionKind: actionKind
            )
        } catch {
            healthMessage = "CafeineX could not save this entry: \(error.localizedDescription)"
            persistenceIssueCenter?.report("Saving the caffeine entry", error: error) { [weak self] in
                guard let self else { return }
                guard self.addDrink(
                    name: name, caffeineMG: caffeineMG, consumedAt: consumedAt, drink: drink,
                    context: context, actionKind: actionKind, source: source, operationID: operationID
                ) else {
                    throw NSError(domain: "CafeineX.Logging", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: self.healthMessage ?? "The entry could not be saved."
                    ])
                }
            }
            return false
        }
        let entry = receipt.entry
        if !entries.contains(where: { $0.id == entry.id }) { entries.append(entry) }
        entries.sort { $0.consumedAt > $1.consumedAt }
        recalculateStatus()
        guard receipt.createdNewEntry else { return true }
        let normalizedName = entry.drinkName
        if let drink {
            let details = DrinkLibrary.details(
                for: drink,
                in: [],
                context: context
            )
            pendingDrinkUsage[entry.id] = DrinkUsageSnapshot(
                details: details,
                useCount: details.useCount,
                lastUsedAt: details.lastUsedAt
            )
            do {
                try DrinkLibrary.recordUse(
                    of: drink,
                    at: entry.consumedAt,
                    detailsValues: [details],
                    context: context
                )
            } catch {
                reportPersistenceFailure(
                    operation: "Updating drink usage",
                    error: error,
                    context: context
                )
            }
        }
        recalculateStatus()
        presentFeedback(
            Feedback(
                entryID: entry.id,
                message: "\(actionKind.titlePrefix) \(normalizedName)",
                kind: .caffeine
            )
        )

        pendingHealthWrites[entry.id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled, let self else { return }
            await self.saveToHealthKit(entry, context: context)
            self.pendingHealthWrites[entry.id] = nil
        }
        return true
    }

    @discardableResult
    func undoLastCaffeineAdd(context: ModelContext) async -> Bool {
        guard let feedback,
              feedback.kind == .caffeine,
              let entry = entries.first(where: { $0.id == feedback.entryID }),
              entry.source != .healthKit else {
            return false
        }

        let entryID = entry.id
        pendingHealthWrites[entryID]?.cancel()
        pendingHealthWrites[entryID] = nil
        do {
            try await loggingService(context: context).undo(entryID: entryID)
        } catch {
            healthMessage = "CafeineX could not undo this entry: \(error.localizedDescription)"
            IntentUndoFailureStore.shared.recordFailure(entryID: entryID, error: error)
            return false
        }
        IntentUndoFailureStore.shared.dismiss(entryID: entryID)
        if let usage = pendingDrinkUsage.removeValue(forKey: entryID) {
            usage.details.useCount = usage.useCount
            usage.details.lastUsedAt = usage.lastUsedAt
            usage.details.updatedAt = .now
            do { try context.save() } catch {
                reportPersistenceFailure(operation: "Restoring drink usage", error: error, context: context)
            }
        }
        entries.removeAll { $0.id == entryID }
        self.feedback = nil
        recalculateStatus()
        return true
    }

    func dismissFeedback() {
        if let feedback {
            pendingDrinkUsage.removeValue(forKey: feedback.entryID)
        }
        feedback = nil
    }

    func cancelPendingOperationsForDataDeletion() {
        for task in pendingHealthWrites.values {
            task.cancel()
        }
        pendingHealthWrites.removeAll()
        pendingDrinkUsage.removeAll()
    }

    func resetAfterDataDeletion() {
        cancelPendingOperationsForDataDeletion()
        entries = []
        nicotineEntries = []
        status = nil
        nicotineStatus = nil
        dailyExposureContext = nil
        healthMessage = nil
        isSyncingHealth = false
        lastHealthSyncDate = nil
        sleepSnapshot = nil
        healthInsightsSummary = nil
        sleepDataMessage = nil
        isLoadingSleep = false
        feedback = nil
    }

    @discardableResult
    func addNicotine(
        product: NicotineProduct,
        quantity: Double,
        unit: NicotineUnit,
        usedAt: Date = .now,
        note: String? = nil,
        context: ModelContext,
        actionKind: RecentActionKind = .logged
    ) -> Bool {
        guard product.allowedUnits.contains(unit),
              quantity.isFinite,
              quantity > 0,
              quantity <= 1_000 else {
            healthMessage = "Enter a valid nicotine amount and unit."
            return false
        }

        let entry = NicotineEntry(
            product: product,
            quantity: quantity,
            unit: unit,
            usedAt: min(usedAt, .now),
            source: .manual,
            note: note
        )
        context.insert(entry)

        do {
            try context.save()
        } catch {
            healthMessage = "CafeineX could not save this nicotine entry: \(error.localizedDescription)"
            reportPersistenceFailure(
                operation: "Saving the nicotine entry",
                error: error,
                context: context
            )
            return false
        }

        nicotineEntries.append(entry)
        nicotineEntries.sort { $0.usedAt > $1.usedAt }
        recalculateStatus()
        recentActions?.record(
            kind: actionKind,
            title: "\(actionKind.titlePrefix) \(product.title)",
            detail: unit.formatted(quantity: quantity),
            relatedEntryID: entry.id,
            occurredAt: entry.usedAt
        )
        presentFeedback(
            Feedback(
                entryID: entry.id,
                message: "\(actionKind.titlePrefix) \(product.title)",
                kind: .nicotine
            )
        )
        return true
    }

    @discardableResult
    func addCigarette(
        quantity: Double = 1,
        usedAt: Date = .now,
        profileID: UUID? = nil,
        cigaretteContext: CigaretteContext? = nil,
        note: String? = nil,
        profiles: [CigaretteProfile] = [],
        context: ModelContext,
        actionKind: RecentActionKind = .logged
    ) -> Bool {
        guard quantity.isFinite, (0.1...100).contains(quantity) else {
            healthMessage = "Enter a cigarette count between 0.1 and 100."
            return false
        }

        let safeDate = min(usedAt, .now)
        let entry = NicotineEntry(
            product: .cigarette,
            quantity: quantity,
            unit: .pieces,
            usedAt: safeDate,
            source: .manual,
            note: note
        )
        let details = CigaretteEventDetails(
            nicotineEntryID: entry.id,
            cigaretteProfileID: profileID,
            context: cigaretteContext
        )
        context.insert(entry)
        context.insert(details)
        CigaretteLibrary.recordUse(profileID: profileID, at: safeDate, profiles: profiles)

        do {
            try context.save()
        } catch {
            healthMessage = "CafeineX could not save this cigarette: \(error.localizedDescription)"
            reportPersistenceFailure(
                operation: "Saving the cigarette entry",
                error: error,
                context: context
            )
            return false
        }

        nicotineEntries.append(entry)
        nicotineEntries.sort { $0.usedAt > $1.usedAt }
        recalculateStatus()
        recentActions?.record(
            kind: actionKind,
            title: "\(actionKind.titlePrefix) cigarette",
            detail: "\(quantity.formatted(.number.precision(.fractionLength(0...1)))) pieces",
            relatedEntryID: entry.id,
            occurredAt: entry.usedAt
        )
        presentFeedback(
            Feedback(
                entryID: entry.id,
                message: "\(actionKind.titlePrefix) cigarette",
                kind: .nicotine
            )
        )
        return true
    }

    @discardableResult
    func undoLastAdd(context: ModelContext) async -> Bool {
        if await undoLastCaffeineAdd(context: context) { return true }
        guard let feedback,
              feedback.kind == .nicotine,
              let entry = nicotineEntries.first(where: { $0.id == feedback.entryID }) else {
            return false
        }
        let identifier = entry.id
        let undoneTitle = entry.product.title
        let undoneDetail = entry.unit.formatted(quantity: entry.quantity)
        let descriptor = FetchDescriptor<CigaretteEventDetails>(
            predicate: #Predicate { $0.nicotineEntryID == identifier }
        )
        if let details = try? context.fetch(descriptor).first {
            if let profileID = details.cigaretteProfileID,
               let profiles = try? context.fetch(FetchDescriptor<CigaretteProfile>()),
               let profile = profiles.first(where: { $0.id == profileID }) {
                profile.useCount = max(profile.useCount - 1, 0)
                if profile.lastUsedAt == entry.usedAt {
                    let allDetails = (try? context.fetch(FetchDescriptor<CigaretteEventDetails>())) ?? []
                    let relatedEntryIDs = Set(
                        allDetails
                            .filter { $0.nicotineEntryID != identifier && $0.cigaretteProfileID == profileID }
                            .map(\.nicotineEntryID)
                    )
                    profile.lastUsedAt = nicotineEntries
                        .filter { relatedEntryIDs.contains($0.id) }
                        .map(\.usedAt)
                        .max()
                }
                profile.updatedAt = .now
            }
            context.delete(details)
        }
        context.delete(entry)
        do {
            try context.save()
        } catch {
            healthMessage = "CafeineX could not undo this entry: \(error.localizedDescription)"
            reportPersistenceFailure(
                operation: "Undoing the nicotine entry",
                error: error,
                context: context
            )
            return false
        }
        nicotineEntries.removeAll { $0.id == identifier }
        recentActions?.record(
            kind: .undone,
            title: "Undid \(undoneTitle)",
            detail: undoneDetail,
            relatedEntryID: identifier
        )
        self.feedback = nil
        recalculateStatus()
        return true
    }

    private func presentFeedback(_ newFeedback: Feedback) {
        if let feedback, feedback.entryID != newFeedback.entryID {
            pendingDrinkUsage.removeValue(forKey: feedback.entryID)
        }
        feedback = newFeedback
    }

    private func saveToHealthKit(_ entry: CaffeineEntry, context: ModelContext) async {
        guard healthAccessState == .writeEnabled else {
            healthMessage = "Saved on this device. Apple Health write access is off."
            return
        }

        do {
            try await loggingService(context: context).synchronizeHealthKit(entryID: entry.id)
            healthMessage = nil
        } catch {
            healthMessage = "Saved on this device, but Apple Health could not be updated: \(error.localizedDescription)"
            reportPersistenceFailure(
                operation: "Saving the Apple Health link",
                error: error,
                context: context
            )
        }
    }

    private func reportPersistenceFailure(
        operation: String,
        error: Error,
        context: ModelContext
    ) {
        persistenceIssueCenter?.report(operation, error: error) {
            try context.save()
        }
    }

    private func reconcile(samples: [HealthCaffeineSample], context: ModelContext) -> Int {
        var entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        var knownHealthUUIDs = Set(entries.compactMap(\.healthKitUUID))
        var importedCount = 0

        for sample in samples {
            if knownHealthUUIDs.contains(sample.id) {
                continue
            }

            if let appEntryID = sample.appEntryID, let linkedEntry = entriesByID[appEntryID] {
                linkedEntry.healthKitUUID = sample.id
                knownHealthUUIDs.insert(sample.id)
                continue
            }

            let entry = CaffeineEntry(
                drinkName: sample.displayName ?? "Apple Health",
                caffeineMG: sample.milligrams,
                consumedAt: sample.consumedAt,
                source: .healthKit,
                healthKitUUID: sample.id
            )
            context.insert(entry)
            entries.append(entry)
            entriesByID[entry.id] = entry
            knownHealthUUIDs.insert(sample.id)
            importedCount += 1
        }

        entries.sort { $0.consumedAt > $1.consumedAt }
        recalculateStatus()
        return importedCount
    }

    private func recalculateStatus() {
        status = engine.makeStatus(doses: entries.map(\.dose))
        let context = DailyExposureContext.make(
            caffeineDoses: entries.map(\.dose),
            nicotineEvents: nicotineEntries.map(\.event),
            sleepSchedule: sleepSchedule,
            caffeineEngine: engine
        )
        nicotineStatus = context.nicotineStatus
        dailyExposureContext = context
        recalculateHealthInsights()
    }

    private func loadSleepSnapshot() async {
        do {
            let endDate = Date.now
            let startDate = Calendar.current.date(
                byAdding: .day,
                value: -14,
                to: endDate
            ) ?? endDate.addingTimeInterval(-14 * 24 * 60 * 60)
            let samples = try await healthKitService.fetchSleepSamples(
                from: startDate,
                to: endDate
            )
            sleepSnapshot = SleepSnapshotBuilder.makeLatest(
                from: samples,
                relativeTo: endDate
            )
            sleepDataMessage = nil
            sleepDataState = sleepSnapshot == nil ? .noData : .available
            recalculateHealthInsights()
        } catch {
            sleepSnapshot = nil
            healthInsightsSummary = nil
            sleepDataState = .failed
            sleepDataMessage = "Recent sleep data could not be read. Check access in the Health app and try again."
        }
    }

    private func recalculateHealthInsights() {
        guard let sleepSnapshot else {
            healthInsightsSummary = nil
            return
        }
        healthInsightsSummary = HealthInsightsEngine().makeSummary(
            snapshot: sleepSnapshot,
            caffeineDoses: entries.map(\.dose),
            nicotineEvents: nicotineEntries.map(\.event),
            cutoffHoursBeforeSleep: sleepSchedule.cutoffHoursBeforeBedtime
        )
    }

    private func loggingService(context: ModelContext) -> CaffeineLoggingService {
        CaffeineLoggingService(context: context, recentActions: recentActions ?? .shared,
                               healthKitService: healthKitService)
    }
}
