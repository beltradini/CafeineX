import Foundation
import HealthKit
import Observation
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    private struct DrinkUsageSnapshot {
        let metadata: DrinkMetadata
        let useCount: Int
        let lastUsedAt: Date?
    }

    struct Feedback: Equatable, Identifiable {
        let id = UUID()
        let entryID: UUID
        let message: String
    }

    enum HealthAccessState: Equatable {
        case unavailable
        case notRequested
        case writeEnabled
        case writeDisabled
    }

    private var engine: CaffeineEngine
    private var sleepSchedule: SleepSchedule = .default
    private let healthKitService: any HealthKitProviding
    private var pendingHealthWrites: [UUID: Task<Void, Never>] = [:]
    private var pendingDrinkUsage: [UUID: DrinkUsageSnapshot] = [:]
    private var pendingOutboxItems: [UUID: HealthSyncOutboxItem] = [:]

    var entries: [CaffeineEntry] = []
    var nicotineEntries: [NicotineEntry] = []
    var status: CaffeineStatus?
    var nicotineStatus: NicotineStatus?
    var dailyExposureContext: DailyExposureContext?
    var healthAccessState: HealthAccessState = .notRequested
    var healthMessage: String?
    var isSyncingHealth = false
    var lastHealthSyncDate: Date?
    var feedback: Feedback?

    init() {
        self.engine = CaffeineEngine()
        self.healthKitService = HealthKitService()
        refreshHealthAccessState()
    }

    init(engine: CaffeineEngine, healthKitService: any HealthKitProviding) {
        self.engine = engine
        self.healthKitService = healthKitService
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
            try await healthKitService.requestAuthorization()
            refreshHealthAccessState()
            await synchronizeHealthKit(context: context)
        } catch {
            refreshHealthAccessState()
            healthMessage = error.localizedDescription
        }
    }

    func synchronizeHealthKit(context: ModelContext) async {
        guard healthAccessState != .unavailable, !isSyncingHealth else { return }

        isSyncingHealth = true
        defer { isSyncingHealth = false }

        do {
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
        }
    }

    @discardableResult
    func addDrink(
        name: String,
        caffeineMG: Double,
        consumedAt: Date = .now,
        drink: Drink? = nil,
        context: ModelContext
    ) -> Bool {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty, caffeineMG.isFinite, caffeineMG > 0, caffeineMG <= 1_000 else {
            healthMessage = "Enter a name and a caffeine amount between 1 and 1,000 mg."
            return false
        }

        let entry = CaffeineEntry(
            drinkName: normalizedName,
            caffeineMG: caffeineMG,
            consumedAt: min(consumedAt, .now),
            source: .manual
        )
        let outboxItem = HealthSyncOutboxItem(entryID: entry.id)

        context.insert(entry)
        context.insert(outboxItem)
        do {
            try context.save()
        } catch {
            context.delete(outboxItem)
            context.delete(entry)
            healthMessage = "CafeineX could not save this entry: \(error.localizedDescription)"
            return false
        }

        entries.append(entry)
        pendingOutboxItems[entry.id] = outboxItem
        entries.sort { $0.consumedAt > $1.consumedAt }
        if let drink {
            let metadata = DrinkLibrary.metadata(
                for: drink,
                in: [],
                context: context
            )
            pendingDrinkUsage[entry.id] = DrinkUsageSnapshot(
                metadata: metadata,
                useCount: metadata.useCount,
                lastUsedAt: metadata.lastUsedAt
            )
            DrinkLibrary.recordUse(
                of: drink,
                at: entry.consumedAt,
                metadataValues: [metadata],
                context: context
            )
        }
        recalculateStatus()
        feedback = Feedback(entryID: entry.id, message: "\(normalizedName) added")

        pendingHealthWrites[entry.id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled, let self else { return }
            await self.saveToHealthKit(entry, context: context)
            self.pendingHealthWrites[entry.id] = nil
            self.pendingDrinkUsage[entry.id] = nil
        }
        return true
    }

    @discardableResult
    func undoLastCaffeineAdd(context: ModelContext) -> Bool {
        guard let feedback,
              let entry = entries.first(where: { $0.id == feedback.entryID }),
              entry.healthKitUUID == nil else {
            return false
        }

        pendingHealthWrites[entry.id]?.cancel()
        pendingHealthWrites[entry.id] = nil
        if let outboxItem = pendingOutboxItems.removeValue(forKey: entry.id)
            ?? outboxItem(for: entry.id, context: context) {
            context.delete(outboxItem)
        }
        if let usage = pendingDrinkUsage.removeValue(forKey: entry.id) {
            usage.metadata.useCount = usage.useCount
            usage.metadata.lastUsedAt = usage.lastUsedAt
            usage.metadata.updatedAt = .now
        }
        context.delete(entry)

        do {
            try context.save()
        } catch {
            healthMessage = "CafeineX could not undo this entry: \(error.localizedDescription)"
            return false
        }

        entries.removeAll { $0.id == entry.id }
        self.feedback = nil
        recalculateStatus()
        return true
    }

    func dismissFeedback() {
        feedback = nil
    }

    @discardableResult
    func addNicotine(
        product: NicotineProduct,
        quantity: Double,
        unit: NicotineUnit,
        usedAt: Date = .now,
        note: String? = nil,
        context: ModelContext
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
            context.delete(entry)
            healthMessage = "CafeineX could not save this nicotine entry: \(error.localizedDescription)"
            return false
        }

        nicotineEntries.append(entry)
        nicotineEntries.sort { $0.usedAt > $1.usedAt }
        recalculateStatus()
        return true
    }

    private func saveToHealthKit(_ entry: CaffeineEntry, context: ModelContext) async {
        guard healthAccessState == .writeEnabled else {
            healthMessage = "Saved on this device. Apple Health write access is off."
            return
        }

        do {
            let sample = try await healthKitService.saveCaffeine(
                milligrams: entry.caffeineMG,
                date: entry.consumedAt,
                appEntryID: entry.id,
                displayName: entry.drinkName
            )
            entry.healthKitUUID = sample.id
            if let outboxItem = pendingOutboxItems.removeValue(forKey: entry.id)
                ?? outboxItem(for: entry.id, context: context) {
                context.delete(outboxItem)
            }
            try context.save()
            healthMessage = nil
        } catch {
            healthMessage = "Saved on this device, but Apple Health could not be updated: \(error.localizedDescription)"
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
    }

    private func outboxItem(
        for entryID: UUID,
        context: ModelContext
    ) -> HealthSyncOutboxItem? {
        let descriptor = FetchDescriptor<HealthSyncOutboxItem>(
            predicate: #Predicate { $0.entryID == entryID }
        )
        return try? context.fetch(descriptor).first
    }
}
