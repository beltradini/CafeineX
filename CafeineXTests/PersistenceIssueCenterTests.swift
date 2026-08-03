import Foundation
import Testing
@testable import CafeineX

@MainActor
struct PersistenceIssueCenterTests {
    @Test func failedAttemptRemainsVisibleAndCanBeRetried() {
        let center = PersistenceIssueCenter()
        var attemptCount = 0

        let succeeded = center.attempt("Saving a pilot entry") {
            attemptCount += 1
            if attemptCount == 1 {
                throw FixtureError.saveFailed
            }
        }

        #expect(!succeeded)
        #expect(center.issue?.operation == "Saving a pilot entry")
        #expect(center.issue?.errorDescription == "Simulated save failure")

        center.retry()

        #expect(attemptCount == 2)
        #expect(center.issue == nil)
    }

    private enum FixtureError: LocalizedError {
        case saveFailed

        var errorDescription: String? {
            "Simulated save failure"
        }
    }
}
