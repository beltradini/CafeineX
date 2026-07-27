import Foundation

/// A persistence-independent input for caffeine calculations.
nonisolated struct CaffeineDose: Equatable, Sendable {
    let amountMG: Double
    let consumedAt: Date
}
