import Foundation

public struct BeverageCatalog {
    public init() {}

    // Convenience without exposing Bundle.module in a default argument
    public func loadDefaults() throws -> [BeverageType] {
        try loadDefaults(from: .module)
    }

    public func loadDefaults(from bundle: Bundle) throws -> [BeverageType] {
        guard let url = bundle.url(forResource: "caffeine_types", withExtension: "json") else {
            throw CatalogError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([BeverageTypeDTO].self, from: data)
        return dtos.map { BeverageType(name: $0.name, caffeineMg: $0.caffeineMg) }
    }
}

// MARK: - DTOs
private struct BeverageTypeDTO: Decodable {
    let name: String
    let caffeineMg: Double
}

// MARK: - Errors
public enum CatalogError: Error {
    case resourceNotFound
}
