import Foundation
import HealthKit
import SwiftData

struct CaffeineLogRequest {
    /// Stable across delivery retries, new for each intentional recording.
    let operationID: UUID
    let drinkName: String
    let caffeineMG: Double
    let consumedAt: Date
    let source: CaffeineSource

    init(operationID: UUID = UUID(), drinkName: String, caffeineMG: Double,
         consumedAt: Date = .now, source: CaffeineSource) {
        self.operationID = operationID
        self.drinkName = drinkName
        self.caffeineMG = caffeineMG
        self.consumedAt = consumedAt
        self.source = source
    }

    func validate() throws {
        guard !drinkName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CaffeineLoggingError.invalidName
        }
        guard caffeineMG.isFinite, caffeineMG > 0, caffeineMG <= 1_000 else {
            throw CaffeineLoggingError.invalidAmount
        }
        guard consumedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw CaffeineLoggingError.invalidDate
        }
    }
}

@MainActor
struct CaffeineLogReceipt {
    let entry: CaffeineEntry
    let createdNewEntry: Bool
    var entryID: UUID { entry.id }
}

enum CaffeineLoggingError: LocalizedError {
    case invalidName, invalidAmount, invalidDate, conflictingOperation
    case importedEntryCannotBeRemoved, entryNotFound, operationInProgress

    var errorDescription: String? {
        switch self {
        case .invalidName: "Enter a drink name."
        case .invalidAmount: "Caffeine must be greater than zero and at most 1,000 milligrams."
        case .invalidDate: "Enter a valid recording time."
        case .conflictingOperation: "This recording identifier already belongs to another entry."
        case .importedEntryCannotBeRemoved: "CafeineX cannot undo an entry imported from Apple Health."
        case .entryNotFound: "The caffeine entry no longer exists."
        case .operationInProgress: "This entry is being updated. Try again shortly."
        }
    }
}

/// All app/Siri/widget mutations use this service on the app's main context.
@MainActor
final class CaffeineLoggingService {
    private let context: ModelContext
    private let recentActions: RecentActionStore
    private let healthKitService: any HealthKitProviding
    private let publishChange: @MainActor (ModelContext) -> Void
    private let acknowledgeWidget: (UUID) throws -> Void
    private let commitLog: (ModelContext) throws -> Void

    // Share across instances so delayed upload, foreground sync and Undo cannot race.
    private static var healthWrites: [UUID: Task<Void, Error>] = [:]
    private static var undoing: Set<UUID> = []

    init(
        context: ModelContext,
        recentActions: RecentActionStore,
        healthKitService: any HealthKitProviding = HealthKitService(),
        publishChange: @escaping @MainActor (ModelContext) -> Void = CafeineXWidgetPublisher.publish,
        acknowledgeWidget: @escaping (UUID) throws -> Void = { try WidgetCommandStore.acknowledgeDrinkCommand(id: $0) },
        commitLog: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.context = context
        self.recentActions = recentActions
        self.healthKitService = healthKitService
        self.publishChange = publishChange
        self.acknowledgeWidget = acknowledgeWidget
        self.commitLog = commitLog
    }

    func log(_ request: CaffeineLogRequest, actionKind: RecentActionKind = .logged) throws -> CaffeineLogReceipt {
        try request.validate()
        let name = request.drinkName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = try entry(id: request.operationID) {
            guard existing.drinkName == name, existing.caffeineMG == request.caffeineMG,
                  existing.source == request.source else {
                throw CaffeineLoggingError.conflictingOperation
            }
            return CaffeineLogReceipt(entry: existing, createdNewEntry: false)
        }

        let entry = CaffeineEntry(
            id: request.operationID, drinkName: name, caffeineMG: request.caffeineMG,
            consumedAt: min(request.consumedAt, .now), source: request.source
        )
        let outbox = HealthSyncOutboxItem(entryID: entry.id)
        context.insert(entry)
        context.insert(outbox)
        do {
            try commitLog(context)
        } catch {
            // Remove this operation's unsaved inserts, not unrelated user edits.
            context.delete(outbox)
            context.delete(entry)
            throw error
        }
        recentActions.record(
            kind: actionKind, title: "\(actionKind.titlePrefix) \(name)",
            detail: "\(Int(request.caffeineMG.rounded())) mg", relatedEntryID: entry.id
        )
        publishChange(context)
        return CaffeineLogReceipt(entry: entry, createdNewEntry: true)
    }

    func synchronizeHealthKit(entryID: UUID) async throws {
        guard !Self.undoing.contains(entryID) else { return }
        if let task = Self.healthWrites[entryID] {
            try await task.value
            return
        }
        guard healthKitService.isHealthKitAvailable,
              healthKitService.caffeineWriteAuthorizationStatus == .sharingAuthorized else { return }
        let task = Task { @MainActor in
            guard let entry = try self.entry(id: entryID), entry.source != .healthKit else { return }
            if entry.healthKitUUID == nil {
                // Recover a HealthKit write interrupted before the local UUID was saved.
                let existing = try await self.ownedSamples(for: entry)
                let sample: HealthCaffeineSample
                if let saved = existing.first {
                    sample = saved
                } else {
                    sample = try await self.healthKitService.saveCaffeine(
                        milligrams: entry.caffeineMG, date: entry.consumedAt,
                        appEntryID: entry.id, displayName: entry.drinkName
                    )
                }
                entry.healthKitUUID = sample.id
            }
            try self.removeOutbox(entryID: entryID)
            try self.context.save()
        }
        Self.healthWrites[entryID] = task
        defer { Self.healthWrites[entryID] = nil }
        try await task.value
    }

    func undo(entryID: UUID) async throws {
        try await CaffeineHealthOperationCoordinator.run {
            try await self.performUndo(entryID: entryID)
        }
    }

    private func performUndo(entryID: UUID) async throws {
        guard Self.undoing.insert(entryID).inserted else {
            throw CaffeineLoggingError.operationInProgress
        }
        defer { Self.undoing.remove(entryID) }
        // An upload error may still have written a sample. Reconcile before deleting.
        if let task = Self.healthWrites[entryID] { _ = await task.result }
        guard let entry = try entry(id: entryID) else { return } // Retry-safe Undo.
        guard entry.source != .healthKit else { throw CaffeineLoggingError.importedEntryCannotBeRemoved }
        if entry.source == .widget {
            // A failed acknowledgment must not resurrect the entry after Undo.
            try acknowledgeWidget(entryID)
        }
        var healthIDs = Set(entry.healthKitUUID.map { [$0] } ?? [])
        if healthKitService.isHealthKitAvailable,
           healthKitService.caffeineWriteAuthorizationStatus == .sharingAuthorized {
            healthIDs.formUnion(try await ownedSamples(for: entry).map(\.id))
        }
        if !healthIDs.isEmpty {
            _ = try await healthKitService.deleteCaffeineSamples(ids: healthIDs)
        }

        // Commit unrelated pending edits before starting this deletion transaction.
        try context.save()
        let name = entry.drinkName
        let amount = entry.caffeineMG
        do {
            try removeOutbox(entryID: entryID)
            context.delete(entry)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        recentActions.record(kind: .undone, title: "Undid \(name)",
                             detail: "\(Int(amount.rounded())) mg", relatedEntryID: entryID)
        publishChange(context)
    }

    private func entry(id: UUID) throws -> CaffeineEntry? {
        try context.fetch(FetchDescriptor<CaffeineEntry>(predicate: #Predicate { $0.id == id })).first
    }

    private func removeOutbox(entryID: UUID) throws {
        let items = try context.fetch(FetchDescriptor<HealthSyncOutboxItem>(
            predicate: #Predicate { $0.entryID == entryID }
        ))
        for item in items { context.delete(item) }
    }

    private func ownedSamples(for entry: CaffeineEntry) async throws -> [HealthCaffeineSample] {
        try await healthKitService.fetchCaffeineSamples(
            from: entry.consumedAt.addingTimeInterval(-1),
            to: entry.consumedAt.addingTimeInterval(1)
        ).filter { $0.appEntryID == entry.id }
    }
}
