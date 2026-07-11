import Foundation

/// A persistence-independent input for caffeine calculations.
struct CaffeineDose: Equatable, Sendable {
    let amountMG: Double
    let consumedAt: Date
}
