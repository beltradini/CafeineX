import Foundation

public struct BeverageType: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var caffeineMg: Double
    public var isFavorite: Bool

    public init(id: UUID = UUID(), name: String, caffeineMg: Double, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.caffeineMg = caffeineMg
        self.isFavorite = isFavorite
    }
}
