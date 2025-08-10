import Foundation
import SwiftData

// Protocol for data sources
protocol CaffeineDataSourceProtocol {
    func fetchEntries() async -> [CaffeineEntry]
    func addEntry(_ entry: CaffeineEntry) async
    func removeEntry(id: UUID) async
}

// SwiftData implementation
final class SwiftDataSource: CaffeineDataSourceProtocol {
    private let container: ModelContainer
    
    init(container: ModelContainer) {
        self.container = container
    }
    
    @MainActor
    func fetchEntries() async -> [CaffeineEntry] {
        let request = FetchDescriptor<CaffeineEntryModel>()
        let models = try? container.mainContext.fetch(request)
        return models?.map {
            CaffeineEntry(id: $0.id, date: $0.date, beverageName: $0.beverageName, caffeineMg: $0.caffeineMg)
        } ?? []
    }
    
    @MainActor
    func addEntry(_ entry: CaffeineEntry) async {
        let model = CaffeineEntryModel(
            id: entry.id,
            date: entry.date,
            beveragename: entry.beverageName,
            caffeineMg: entry.caffeineMg
        )
        container.mainContext.insert(model)
    }
    
    @MainActor
    func removeEntry(id: UUID) async {
        let request = FetchDescriptor<CaffeineEntryModel>(predicate: #Predicate { $0.id == id })
        if let models = try? container.mainContext.fetch(request), let model = models.first {
            container.mainContext.delete(model)
        }
    }
}
