import Foundation
import HealthKit
import Observation
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    enum HealthAccessState: Equatable {
        case unavailable
        case notRequested
        case writeEnabled
        case writeDisabled
    }

    private var engine: CaffeineEngine
    private var sleepSchedule: SleepSchedule = .default
    private let healthKitService: any HealthKitProviding

    var entries: [CaffeineEntry] = []
    var nicotineEntries: [NicotineEntry] = []
    var status: CaffeineStatus?
    var nicotineStatus: NicotineStatus?
    var dailyExposureContext: DailyExposureContext?
    var healthAccessState: HealthAccessState = .notRequested
    var healthMessage: String?
    var isSyncingHealth = false
    var lastHealthSyncDate: Date?

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
            lastHealthSyncDate = .now
            healthMessage = importedCount == 0
                ? "Apple Health is up to date."
                : "Imported \(importedCount) caffeine \(importedCount == 1 ? "entry" : "entries") from Apple Health."
        } catch {
            healthMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addDrink(
        name: String,
        caffeineMG: Double,
        consumedAt: Date = .now,
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

        context.insert(entry)
        do {
            try context.save()
        } catch {
            context.delete(entry)
            healthMessage = "CafeineX could not save this entry: \(error.localizedDescription)"
            return false
        }

        entries.append(entry)
        recalculateStatus()

        Task {
            await saveToHealthKit(entry, context: context)
        }
        return true
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
}
