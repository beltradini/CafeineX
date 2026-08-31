import AppIntents
import Darwin
import Foundation
import WidgetKit

nonisolated struct PendingWidgetDrinkCommand: Codable, Sendable, Equatable {
    let id: UUID
    let name: String
    let caffeineMG: Double
    let createdAt: Date
}

/// A durable, cross-process inbox. The file lock covers read/modify/write and
/// migration; an atomic replacement never exposes partially encoded JSON.
nonisolated struct WidgetCommandQueue: Sendable {
    let directory: URL

    private struct State: Codable {
        var commands: [PendingWidgetDrinkCommand] = []
        var lastEnqueued: PendingWidgetDrinkCommand?
    }

    @discardableResult
    func enqueue(_ command: PendingWidgetDrinkCommand) throws -> PendingWidgetDrinkCommand {
        guard !command.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              command.caffeineMG.isFinite, command.caffeineMG > 0, command.caffeineMG <= 1_000,
              command.createdAt.timeIntervalSinceReferenceDate.isFinite else {
            throw QueueError.invalidDrink
        }
        return try update { state in
            if let existing = state.commands.first(where: { $0.id == command.id }) { return existing }
            if let last = state.lastEnqueued,
               last.name == command.name, last.caffeineMG == command.caffeineMG,
               abs(last.createdAt.timeIntervalSince(command.createdAt)) < 3 {
                return last
            }
            state.commands.append(command)
            state.lastEnqueued = command
            return command
        }
    }

    func pending() throws -> [PendingWidgetDrinkCommand] {
        try update { $0.commands.sorted { $0.createdAt < $1.createdAt } }
    }

    func acknowledge(id: UUID) throws {
        try update { $0.commands.removeAll { $0.id == id } }
    }

    func removeAll() throws {
        try update { $0 = State() }
    }

    func migrateLegacy(defaults: UserDefaults) throws {
        try update({ state in
            guard let data = defaults.data(forKey: CafeineXWidgetConstants.commandKey) else { return }
            let decoder = JSONDecoder()
            let commands: [PendingWidgetDrinkCommand]
            if let array = try? decoder.decode([PendingWidgetDrinkCommand].self, from: data) {
                commands = array
            } else {
                commands = [try decoder.decode(PendingWidgetDrinkCommand.self, from: data)]
            }
            for command in commands where !state.commands.contains(where: { $0.id == command.id }) {
                state.commands.append(command)
            }
        }, afterCommit: {
            // Still under the lock: another consumer must not replay the old copy.
            defaults.removeObject(forKey: CafeineXWidgetConstants.commandKey)
        })
    }

    private func update<T>(
        _ body: (inout State) throws -> T,
        afterCommit: () -> Void = {}
    ) throws -> T {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let lockURL = directory.appending(path: "inbox.lock")
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw POSIXError(.EIO) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw POSIXError(.EIO) }
        defer { flock(descriptor, LOCK_UN) }

        let file = directory.appending(path: "inbox.json")
        var state: State
        if FileManager.default.fileExists(atPath: file.path) {
            state = try JSONDecoder().decode(State.self, from: Data(contentsOf: file))
        } else {
            state = State()
        }
        let result = try body(&state)
        try JSONEncoder().encode(state).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        afterCommit()
        return result
    }

    enum QueueError: LocalizedError {
        case appGroupUnavailable, invalidDrink
        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable: "CafeineX could not access shared widget storage. Open the app and try again."
            case .invalidDrink: "This favorite needs a valid name and caffeine amount. Edit it in CafeineX."
            }
        }
    }
}

nonisolated enum WidgetCommandStore {
    static let didEnqueue = Notification.Name("CafeineX.widgetCommandDidEnqueue")

    static func sharedQueue() throws -> WidgetCommandQueue {
        guard let directory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: CafeineXWidgetConstants.appGroupID
        ) else { throw WidgetCommandQueue.QueueError.appGroupUnavailable }
        let queue = WidgetCommandQueue(directory: directory.appending(path: "WidgetInbox"))
        if let defaults = UserDefaults(suiteName: CafeineXWidgetConstants.appGroupID) {
            try queue.migrateLegacy(defaults: defaults)
        }
        return queue
    }

    @discardableResult
    static func enqueueDrink(name: String, caffeineMG: Double) throws -> PendingWidgetDrinkCommand {
        try sharedQueue().enqueue(.init(id: UUID(), name: name, caffeineMG: caffeineMG, createdAt: .now))
    }

    static func pendingDrinkCommands() throws -> [PendingWidgetDrinkCommand] {
        try sharedQueue().pending()
    }

    static func acknowledgeDrinkCommand(id: UUID) throws {
        try sharedQueue().acknowledge(id: id)
    }
}

struct LogFavoriteDrinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Log favorite drink"
    static let description = IntentDescription("Records this favorite in CafeineX.")
    // This is widget plumbing, not a fifth public Siri/Shortcuts action.
    static var isDiscoverable: Bool { false }
    static var supportedModes: IntentModes { .foreground(.deferred) }

    @Parameter(title: "Drink") var name: String
    @Parameter(title: "Caffeine (mg)") var caffeineMG: Double

    init() {}

    init(name: String, caffeineMG: Double) {
        self.name = name
        self.caffeineMG = caffeineMG
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try WidgetCommandStore.enqueueDrink(name: name, caffeineMG: caffeineMG)
        // Handles an already active app; scene activation drains cold-start deliveries.
        NotificationCenter.default.post(name: WidgetCommandStore.didEnqueue, object: nil)
        return .result()
    }
}
