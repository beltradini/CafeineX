import Foundation

/// A full import pass and Undo must be ordered too: otherwise a query that began
/// before Undo could return a stale sample and reimport the deleted entry.
@MainActor
enum CaffeineHealthOperationCoordinator {
    private static var tail: (id: UUID, task: Task<Void, Error>)?

    static func run(_ operation: @escaping @MainActor () async throws -> Void) async throws {
        let previous = tail?.task
        let id = UUID()
        let task = Task { @MainActor in
            if let previous { _ = await previous.result }
            try await operation()
        }
        tail = (id, task)
        defer { if tail?.id == id { tail = nil } }
        try await task.value
    }
}
