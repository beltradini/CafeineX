//
//  CaffeineDataRepository.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import Foundation
import SwiftData

// MARK: Repository

@MainActor
final class CaffeineDataRepository: CaffeineDataRepositoryProtocol {
    private let container: ModelContainer
    
    init(container: ModelContainer) {
        self.container = container
    }

    func fetchEntries() -> [CaffeineEntry] {
        let request = FetchDescriptor<CaffeineEntryModel>()
        let models = try? container.mainContext.fetch(request)
        return models?.map {
            CaffeineEntry(id: $0.id, date: $0.date, beverageName: $0.beverageName, caffeineMg: $0.caffeineMg)
        } ?? []
    }
    
    func addEntry(_ entry: CaffeineEntry) {
        let model = CaffeineEntryModel(
            id: entry.id,
            date: entry.date,
            beveragename: entry.beverageName,
            caffeineMg: entry.caffeineMg
        )
        container.mainContext.insert(model)
        try? container.mainContext.save()
    }
    
    func removeEntry(id: UUID) {
        let request = FetchDescriptor<CaffeineEntryModel>(predicate: #Predicate { $0.id == id })
        if let models = try? container.mainContext.fetch(request), let model = models.first {
            container.mainContext.delete(model)
            try? container.mainContext.save()
        }
    }
}
