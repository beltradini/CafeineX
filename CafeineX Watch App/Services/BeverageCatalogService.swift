//
//  BeverageCatalogService.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import SwiftData

@MainActor
final class BeverageCatalogService {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
        loadDefaultsIfNeeded()
    }

    private func loadDefaultsIfNeeded() {
        let request = FetchDescriptor<BeverageTypeModel>()
        if let count = try? container.mainContext.fetch(request).count, count > 0 {
            return
        }
        guard
            let url = Bundle.main.url(forResource: "caffeine_types", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let list = try? JSONDecoder().decode([BeverageTypeDTO].self, from: data)
        else { return }

        list.forEach { dto in
            let model = BeverageTypeModel(
                name: dto.name,
                caffeineMg: dto.caffeineMg
            )
            container.mainContext.insert(model)
        }
    }

    // DTO
    private struct BeverageTypeDTO: Decodable {
        let name: String
        let caffeineMg: Double
    }

    // MARK: - CRUD Operations

    func fetchAll() -> [BeverageTypeModel] {
        let request = FetchDescriptor<BeverageTypeModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? container.mainContext.fetch(request)) ?? []
    }

    func fetchFavorites() -> [BeverageTypeModel] {
            let request = FetchDescriptor<BeverageTypeModel>(
                predicate: #Predicate { $0.isFavorite == true },
                sortBy: [SortDescriptor(\.name)]
            )
            return (try? container.mainContext.fetch(request)) ?? []
    }

    func addBeverage(name: String, caffeineMg: Double) {
        let model = BeverageTypeModel(name: name, caffeineMg: caffeineMg)
        container.mainContext.insert(model)
    }

    func updateBeverage(_ model: BeverageTypeModel, name: String, caffeineMg: Double) {
        model.name = name
        model.caffeineMg = caffeineMg
    }

    func toggleFavorite(_ model: BeverageTypeModel) {
        model.isFavorite.toggle()
    }

    func deleteBeverage(_ model: BeverageTypeModel) {
        container.mainContext.delete(model)
    }
}
