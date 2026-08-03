import Foundation
import Observation

@MainActor
@Observable
final class PersistenceIssueCenter {
    struct Issue: Identifiable {
        let id = UUID()
        let operation: String
        let errorDescription: String
        fileprivate let retryAction: @MainActor () throws -> Void
    }

    private(set) var issue: Issue?

    @discardableResult
    func attempt(
        _ operation: String,
        action: @escaping @MainActor () throws -> Void
    ) -> Bool {
        do {
            try action()
            issue = nil
            return true
        } catch {
            report(operation, error: error, retryAction: action)
            return false
        }
    }

    func report(
        _ operation: String,
        error: Error,
        retryAction: @escaping @MainActor () throws -> Void
    ) {
        issue = Issue(
            operation: operation,
            errorDescription: error.localizedDescription,
            retryAction: retryAction
        )
    }

    func retry() {
        guard let current = issue else { return }
        do {
            try current.retryAction()
            issue = nil
        } catch {
            issue = Issue(
                operation: current.operation,
                errorDescription: error.localizedDescription,
                retryAction: current.retryAction
            )
        }
    }

    func dismiss() {
        issue = nil
    }
}
