import Foundation
import Observation
import OSLog

/// UndoManager callbacks cannot throw back into Siri. Retain failed Undo requests
/// so the app can show the error and retry, including after relaunch.
@MainActor
@Observable
final class IntentUndoFailureStore {
    struct Failure: Codable, Identifiable {
        let id: UUID
        let message: String
    }

    static let shared = IntentUndoFailureStore()
    private let defaults: UserDefaults
    private let key = "cafeinex.intentUndoFailures"
    private(set) var failures: [Failure]
    private(set) var isRetrying = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        failures = defaults.data(forKey: key).flatMap {
            try? JSONDecoder().decode([Failure].self, from: $0)
        } ?? []
    }

    @discardableResult
    func attempt(entryID: UUID, operation: () async throws -> Void) async -> Bool {
        failures.removeAll { $0.id == entryID }
        failures.append(Failure(id: entryID, message: "Undo has not finished. You can retry it here."))
        persist()
        do {
            try await operation()
            dismiss(entryID: entryID)
            return true
        } catch {
            recordFailure(entryID: entryID, error: error)
            Logger(subsystem: "beltradini.CafeineX", category: "AppIntents")
                .error("Undo failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func recordFailure(entryID: UUID, error: Error) {
        failures.removeAll { $0.id == entryID }
        failures.append(Failure(id: entryID, message: error.localizedDescription))
        persist()
    }

    func retry(entryID: UUID) async {
        guard !isRetrying else { return }
        isRetrying = true
        defer { isRetrying = false }
        await attempt(entryID: entryID) {
            try await CafeineXIntentEnvironment.makeLoggingService().undo(entryID: entryID)
        }
    }

    func dismiss(entryID: UUID) {
        failures.removeAll { $0.id == entryID }
        persist()
    }

    func removeAll() {
        failures = []
        defaults.removeObject(forKey: key)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(failures) { defaults.set(data, forKey: key) }
    }
}
