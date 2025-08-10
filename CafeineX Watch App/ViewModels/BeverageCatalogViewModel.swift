//
//  BeverageCatalogViewModel.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/13/25.
//

import Foundation
import Combine

@MainActor
final class BeverageCatalogViewModel: ObservableObject {
    @Published private(set) var allBeverages: [BeverageTypeModel] = []
    @Published private(set) var favoriteBeverages: [BeverageTypeModel] = []

    private let service: BeverageCatalogService
    private var cancellables = Set<AnyCancellable>()

    init(service: BeverageCatalogService) {
        self.service = service
        loadCatalog()
    }

    func loadCatalog() {
        allBeverages = service.fetchAll()
        favoriteBeverages = service.fetchFavorites()
    }
    
    func getBeverage(by id: UUID) -> BeverageTypeModel? {
        return allBeverages.first { $0.id == id } ?? favoriteBeverages.first { $0.id == id }
    }

    func addBeverage(name: String, caffeineMg: Double) {
        service.addBeverage(name: name, caffeineMg: caffeineMg)
        loadCatalog()
    }

    func editBeverage(_ model: BeverageTypeModel, name: String, caffeineMg: Double) {
        service.updateBeverage(model, name: name, caffeineMg: caffeineMg)
        loadCatalog()
    }

    func toggleFavorite(_ model: BeverageTypeModel) {
        service.toggleFavorite(model)
        loadCatalog()
    }

    func deleteBeverage(_ model: BeverageTypeModel) {
        service.deleteBeverage(model)
        loadCatalog()
    }
}
