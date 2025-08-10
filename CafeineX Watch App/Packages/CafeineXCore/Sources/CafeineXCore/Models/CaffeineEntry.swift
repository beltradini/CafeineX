import Foundation

public struct CaffeineEntry: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var date: Date
    public var beverageName: String
    public var caffeineMg: Double

    public init(id: UUID = UUID(), date: Date = Date(), beverageName: String = "", caffeineMg: Double = 0) {
        self.id = id
        self.date = date
        self.beverageName = beverageName
        self.caffeineMg = caffeineMg
    }
}
