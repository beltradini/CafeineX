import AppIntents
import Foundation
import HealthKit
import SwiftData
import Testing
@testable import CafeineX

@MainActor
struct SystemSurfaceLoggingTests {
    @Test func widgetReplayAfterCommitAndReopenCreatesExactlyOneEntry() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let command = PendingWidgetDrinkCommand(
            id: UUID(), name: "Favorite Latte", caffeineMG: 120, createdAt: .now
        )
        try fixture.queue.enqueue(command)
        let storeURL = fixture.directory.appending(path: "test.store")
        // Simulate termination after the SQLite commit but before inbox acknowledgment.
        do {
            let container = try CafeineXStoreFactory.makePersistentContainer(storeURL: storeURL)
            let service = fixture.service(context: container.mainContext)
            #expect(throws: SimulatedFailure.self) {
                try WidgetCommandConsumer.consume(queue: fixture.queue) { command in
                    let receipt = try service.log(command.request)
                    #expect(receipt.entryID == command.id)
                    throw SimulatedFailure.interrupted
                }
            }
        }
        #expect(try fixture.queue.pending().count == 1)
        let reopened = try CafeineXStoreFactory.makePersistentContainer(storeURL: storeURL)
        let context = reopened.mainContext
        let service = fixture.service(context: context)
        try WidgetCommandConsumer.consume(queue: fixture.queue) { command in
            let receipt = try service.log(command.request)
            #expect(!receipt.createdNewEntry)
            #expect(receipt.entryID == command.id)
        }
        #expect(try context.fetchCount(FetchDescriptor<CaffeineEntry>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 1)
        #expect(try fixture.queue.pending().isEmpty)
        #expect(fixture.actions.actions.count == 1)
        let snapshot = try CafeineXWidgetPublisher.makeSnapshot(context: context)
        #expect(snapshot.caffeineTodayMG == 120)
        #expect(snapshot.recentExposures.first?.id == command.id)
    }

    @Test func homeAndWidgetUseTheSameOperationIdentity() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let viewModel = HomeViewModel(engine: CaffeineEngine(), healthKitService: fixture.health,
                                      recentActions: fixture.actions)
        let id = UUID()
        for _ in 0..<2 {
            #expect(viewModel.addDrink(name: "Americano", caffeineMG: 150,
                                      context: container.mainContext, source: .widget, operationID: id))
        }
        viewModel.cancelPendingOperationsForDataDeletion()
        #expect(viewModel.entries.count == 1)
        #expect(viewModel.feedback?.entryID == id)
        #expect(fixture.actions.actions.count == 1)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<CaffeineEntry>()) == 1)
    }

    @Test func distinctIntentionalRecordingsAreNotCollapsed() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let service = fixture.service(context: container.mainContext)
        let date = Date.now
        let first = try service.log(.init(drinkName: "Espresso", caffeineMG: 64, consumedAt: date, source: .manual))
        let second = try service.log(.init(drinkName: "Espresso", caffeineMG: 64, consumedAt: date, source: .manual),
                                     actionKind: .loggedAgain)
        #expect(first.entryID != second.entryID)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<CaffeineEntry>()) == 2)
    }

    @Test func invalidAmountsNeverWriteOrConvertToInt() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let service = fixture.service(context: container.mainContext)
        for amount in [Double.nan, .infinity, -.infinity, -1, 0, 1_001] {
            #expect(throws: CaffeineLoggingError.self) {
                try service.log(.init(drinkName: "Espresso", caffeineMG: amount, source: .siri))
            }
        }
        #expect(throws: CaffeineLoggingError.self) {
            try service.log(.init(drinkName: " \n ", caffeineMG: 64, source: .siri))
        }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 0)
    }

    @Test func publicIntentRejectsInvalidAmountBeforeSystemConfirmation() async throws {
        let intent = LogCaffeineIntent(drinkName: "Espresso", caffeineMG: .infinity)
        await #expect(throws: CaffeineLoggingError.self) { try await intent.perform() }
    }

    @Test func widgetParametersRetainTheSelectedDrinkAndAreNotDiscoverable() {
        let intent = LogFavoriteDrinkIntent(name: "Cold Brew", caffeineMG: 200)
        #expect(intent.name == "Cold Brew")
        #expect(intent.caffeineMG == 200)
        #expect(!LogFavoriteDrinkIntent.isDiscoverable)
    }

    @Test func inboxDebouncesDoubleTapEvenAfterAcknowledgment() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let first = PendingWidgetDrinkCommand(id: UUID(), name: "Espresso", caffeineMG: 64, createdAt: .now)
        try fixture.queue.enqueue(first)
        try fixture.queue.acknowledge(id: first.id)
        let repeated = try fixture.queue.enqueue(.init(id: UUID(), name: first.name, caffeineMG: first.caffeineMG,
                                                       createdAt: first.createdAt.addingTimeInterval(1)))
        #expect(repeated.id == first.id)
        #expect(try fixture.queue.pending().isEmpty)
        let later = try fixture.queue.enqueue(.init(id: UUID(), name: first.name, caffeineMG: first.caffeineMG,
                                                    createdAt: first.createdAt.addingTimeInterval(4)))
        #expect(later.id != first.id)
        #expect(try fixture.queue.pending().count == 1)
    }

    @Test func inboxDoesNotSilentlyDropOldCommandsAndMigratesLegacyData() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let commands = (0..<25).map { index in
            PendingWidgetDrinkCommand(id: UUID(), name: "Drink \(index)", caffeineMG: 64,
                                      createdAt: Date.now.addingTimeInterval(-172_800 + Double(index * 4)))
        }
        fixture.defaults.set(try JSONEncoder().encode(commands), forKey: CafeineXWidgetConstants.commandKey)
        try fixture.queue.migrateLegacy(defaults: fixture.defaults)
        try fixture.queue.migrateLegacy(defaults: fixture.defaults)
        #expect(try fixture.queue.pending() == commands)
        #expect(fixture.defaults.data(forKey: CafeineXWidgetConstants.commandKey) == nil)
        try fixture.queue.removeAll()
        #expect(try fixture.queue.pending().isEmpty)
    }

    @Test func failedPersistenceDoesNotAcknowledgeTheWidgetCommand() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        try fixture.queue.enqueue(.init(id: UUID(), name: "Tea", caffeineMG: 40, createdAt: .now))
        #expect(throws: SimulatedFailure.self) {
            try WidgetCommandConsumer.consume(queue: fixture.queue) { _ in throw SimulatedFailure.interrupted }
        }
        #expect(try fixture.queue.pending().count == 1)
    }

    @Test func failedLocalCommitLeavesNoGhostEntryOrOutbox() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let context = container.mainContext
        let failing = CaffeineLoggingService(
            context: context, recentActions: fixture.actions, healthKitService: fixture.health,
            publishChange: { _ in }, commitLog: { _ in throw SimulatedFailure.interrupted }
        )
        let request = CaffeineLogRequest(drinkName: "Tea", caffeineMG: 40, source: .siri)
        #expect(throws: SimulatedFailure.self) { try failing.log(request) }
        try context.save() // A later save must not accidentally commit the failed operation.
        #expect(try context.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 0)
        #expect(fixture.actions.actions.isEmpty)
        #expect(try fixture.service(context: context).log(request).createdNewEntry)
    }

    @Test func concurrentEnqueuesDoNotLoseCommands() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let queue = fixture.queue
        let commands = (0..<30).map {
            PendingWidgetDrinkCommand(id: UUID(), name: "Favorite \($0)", caffeineMG: 64, createdAt: .now)
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for command in commands {
                group.addTask { _ = try queue.enqueue(command) }
            }
            try await group.waitForAll()
        }
        #expect(Set(try queue.pending().map(\.id)) == Set(commands.map(\.id)))
    }

    @Test func corruptedInboxReportsFailureWithoutReplacingData() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        try fixture.queue.removeAll()
        let file = fixture.queue.directory.appending(path: "inbox.json")
        let corruptData = Data("invalid json".utf8)
        try corruptData.write(to: file)
        #expect(throws: (any Error).self) { try fixture.queue.pending() }
        #expect(try Data(contentsOf: file) == corruptData)
    }

    @Test func healthRetryAfterInterruptedLinkDoesNotUploadTwice() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let context = container.mainContext
        let service = fixture.service(context: context)
        let receipt = try service.log(.init(drinkName: "Espresso", caffeineMG: 64, source: .siri))
        // HealthKit succeeded, then the process was interrupted before linking.
        fixture.health.samples = [.init(id: UUID(), milligrams: 64, consumedAt: receipt.entry.consumedAt,
                                        appEntryID: receipt.entryID, displayName: "Espresso")]
        try await service.synchronizeHealthKit(entryID: receipt.entryID)
        try await fixture.service(context: context).synchronizeHealthKit(entryID: receipt.entryID)
        #expect(fixture.health.saveCount == 0)
        #expect(fixture.health.samples.count == 1)
        #expect(receipt.entry.healthKitUUID == fixture.health.samples.first?.id)
        #expect(try context.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 0)
    }

    @Test func deniedHealthWriteKeepsDurableOutboxForLater() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let service = fixture.service(context: container.mainContext)
        let receipt = try service.log(.init(drinkName: "Espresso", caffeineMG: 64, source: .siri))
        fixture.health.caffeineWriteAuthorizationStatus = .sharingDenied
        try await service.synchronizeHealthKit(entryID: receipt.entryID)
        #expect(fixture.health.saveCount == 0)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 1)
        fixture.health.caffeineWriteAuthorizationStatus = .sharingAuthorized
        try await service.synchronizeHealthKit(entryID: receipt.entryID)
        try await service.synchronizeHealthKit(entryID: receipt.entryID)
        #expect(fixture.health.saveCount == 1)
    }

    @Test func concurrentUploadAndUndoWaitForTheSameWrite() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let context = container.mainContext
        let service = fixture.service(context: context)
        let receipt = try service.log(.init(drinkName: "Espresso", caffeineMG: 64, source: .siri))
        fixture.health.pauseWrites = true
        let upload = Task { try await service.synchronizeHealthKit(entryID: receipt.entryID) }
        await fixture.health.waitForWrite()
        let secondUpload = Task {
            try await fixture.service(context: context).synchronizeHealthKit(entryID: receipt.entryID)
        }
        let undo = Task { try await fixture.service(context: context).undo(entryID: receipt.entryID) }
        await Task.yield()
        fixture.health.resumeWrite()
        try await upload.value
        try await secondUpload.value
        try await undo.value
        #expect(fixture.health.saveCount == 1)
        #expect(fixture.health.samples.isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<HealthSyncOutboxItem>()) == 0)
    }

    @Test func undoCannotBeReimportedByAnAlreadyRunningHealthQuery() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let context = container.mainContext
        let service = fixture.service(context: context)
        let receipt = try service.log(.init(drinkName: "Tea", caffeineMG: 40, source: .siri))
        try await service.synchronizeHealthKit(entryID: receipt.entryID)
        let viewModel = HomeViewModel(engine: CaffeineEngine(), healthKitService: fixture.health)
        viewModel.load(entries: [receipt.entry])
        fixture.health.pauseNextRead = true
        let sync = Task { await viewModel.synchronizeHealthKit(context: context) }
        await fixture.health.waitForRead()
        let undo = Task { try await service.undo(entryID: receipt.entryID) }
        await Task.yield()
        // Undo is queued behind the complete import transaction.
        #expect(fixture.health.deleteCount == 0)
        fixture.health.resumeRead()
        await sync.value
        try await undo.value
        #expect(fixture.health.samples.isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
    }

    @Test func undoFailureRetainsEntryAndCanBeRetriedAfterReopening() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let storeURL = fixture.directory.appending(path: "undo.store")
        let id: UUID
        do {
            let container = try CafeineXStoreFactory.makePersistentContainer(storeURL: storeURL)
            let service = fixture.service(context: container.mainContext)
            let receipt = try service.log(.init(drinkName: "Tea", caffeineMG: 40, source: .siri))
            id = receipt.entryID
            try await service.synchronizeHealthKit(entryID: id)
            fixture.health.failDeletion = true
            let failures = IntentUndoFailureStore(defaults: fixture.defaults)
            #expect(!(await failures.attempt(entryID: id) { try await service.undo(entryID: id) }))
            #expect(try container.mainContext.fetchCount(FetchDescriptor<CaffeineEntry>()) == 1)
            #expect(fixture.health.samples.count == 1)
        }
        let reopened = try CafeineXStoreFactory.makePersistentContainer(storeURL: storeURL)
        let service = fixture.service(context: reopened.mainContext)
        let failures = IntentUndoFailureStore(defaults: fixture.defaults)
        #expect(failures.failures.first?.id == id)
        fixture.health.failDeletion = false
        #expect(await failures.attempt(entryID: id) { try await service.undo(entryID: id) })
        try await service.undo(entryID: id) // Retrying a successful Undo is harmless.
        #expect(failures.failures.isEmpty)
        #expect(fixture.health.samples.isEmpty)
        #expect(try reopened.mainContext.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
    }

    @Test func undoNeverDeletesImportedHealthData() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let entry = CaffeineEntry(drinkName: "Imported", caffeineMG: 80, source: .healthKit, healthKitUUID: UUID())
        container.mainContext.insert(entry)
        try container.mainContext.save()
        await #expect(throws: CaffeineLoggingError.self) {
            try await fixture.service(context: container.mainContext).undo(entryID: entry.id)
        }
        #expect(fixture.health.deleteCount == 0)
    }

    @Test func undoAcknowledgesPendingReplayBeforeRemovingWidgetEntry() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let container = try CafeineXStoreFactory.makeInMemoryContainer()
        let command = PendingWidgetDrinkCommand(id: UUID(), name: "Espresso", caffeineMG: 64, createdAt: .now)
        try fixture.queue.enqueue(command)
        let service = fixture.service(context: container.mainContext)
        _ = try service.log(command.request)
        try await service.undo(entryID: command.id)
        #expect(try fixture.queue.pending().isEmpty)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<CaffeineEntry>()) == 0)
    }

    @MainActor
    private struct Fixture {
        let directory: URL
        let suite = "CafeineX.SystemSurfaceTests.\(UUID().uuidString)"
        let defaults: UserDefaults
        let actions: RecentActionStore
        let health = SurfaceHealthMock()
        var queue: WidgetCommandQueue { .init(directory: directory.appending(path: "inbox")) }

        init() throws {
            directory = FileManager.default.temporaryDirectory.appending(path: "CafeineXTests-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defaults = try #require(UserDefaults(suiteName: suite))
            actions = RecentActionStore(defaults: defaults)
        }
        func service(context: ModelContext) -> CaffeineLoggingService {
            CaffeineLoggingService(context: context, recentActions: actions, healthKitService: health,
                                   publishChange: { _ in }, acknowledgeWidget: { try queue.acknowledge(id: $0) })
        }
        func cleanUp() {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
    }
}

private extension PendingWidgetDrinkCommand {
    @MainActor var request: CaffeineLogRequest {
        .init(operationID: id, drinkName: name, caffeineMG: caffeineMG, consumedAt: createdAt, source: .widget)
    }
}

private enum SimulatedFailure: Error { case interrupted }

@MainActor
private final class SurfaceHealthMock: HealthKitProviding {
    var isHealthKitAvailable = true
    var caffeineWriteAuthorizationStatus: HKAuthorizationStatus = .sharingAuthorized
    var samples: [HealthCaffeineSample] = []
    var saveCount = 0
    var deleteCount = 0
    var failDeletion = false
    var pauseWrites = false
    var pauseNextRead = false
    private var writeContinuation: CheckedContinuation<Void, Never>?
    private var observer: CheckedContinuation<Void, Never>?
    private var readContinuation: CheckedContinuation<Void, Never>?
    private var readObserver: CheckedContinuation<Void, Never>?

    func requestCaffeineAuthorization() async throws {}
    func requestSleepAuthorization() async throws {}
    func sleepAuthorizationRequestStatus() async throws -> HKAuthorizationRequestStatus { .shouldRequest }
    func fetchSleepSamples(from: Date, to: Date) async throws -> [HealthSleepSample] { [] }
    func fetchCaffeineSamples(from: Date, to: Date) async throws -> [HealthCaffeineSample] {
        let result = samples.filter { $0.consumedAt >= from && $0.consumedAt <= to }
        if pauseNextRead {
            pauseNextRead = false
            await withCheckedContinuation { continuation in
                readContinuation = continuation
                readObserver?.resume()
                readObserver = nil
            }
        }
        return result
    }
    func saveCaffeine(milligrams: Double, date: Date, appEntryID: UUID, displayName: String) async throws -> HealthCaffeineSample {
        saveCount += 1
        if pauseWrites {
            await withCheckedContinuation { continuation in
                writeContinuation = continuation
                observer?.resume()
                observer = nil
            }
        }
        let sample = HealthCaffeineSample(id: UUID(), milligrams: milligrams, consumedAt: date,
                                         appEntryID: appEntryID, displayName: displayName)
        samples.append(sample)
        return sample
    }
    func deleteCaffeineSamples(ids: Set<UUID>) async throws -> Int {
        if failDeletion { throw SimulatedFailure.interrupted }
        deleteCount += 1
        let count = samples.filter { ids.contains($0.id) }.count
        samples.removeAll { ids.contains($0.id) }
        return count
    }
    func waitForWrite() async {
        guard writeContinuation == nil else { return }
        await withCheckedContinuation { observer = $0 }
    }
    func resumeWrite() {
        writeContinuation?.resume()
        writeContinuation = nil
    }
    func waitForRead() async {
        guard readContinuation == nil else { return }
        await withCheckedContinuation { readObserver = $0 }
    }
    func resumeRead() {
        readContinuation?.resume()
        readContinuation = nil
    }
}
