import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class CafeineXPersistenceController {
    struct Failure {
        let summary: String
        let technicalDetails: String
    }

    enum State {
        case loading
        case ready(ModelContainer)
        case unavailable(Failure)
    }

    private(set) var state: State = .loading
    private let useInMemoryStore: Bool

    init(useInMemoryStore: Bool = false) {
        self.useInMemoryStore = useInMemoryStore
        open()
    }

    func retry() {
        open()
    }

    func preserveAndStartFresh() {
        let previousDetails: String
        if case .unavailable(let failure) = state {
            previousDetails = failure.technicalDetails
        } else {
            previousDetails = "CafeineX storage was unavailable."
        }

        state = .loading
        do {
            let container = try CafeineXStoreFactory.makeFreshContainerPreservingUnreadableStore(
                originalErrorDescription: previousDetails
            )
            try prepare(container)
            state = .ready(container)
        } catch {
            state = .unavailable(Failure(
                summary: "CafeineX could not create a recovered local store.",
                technicalDetails: String(describing: error)
            ))
        }
    }

    private func open() {
        state = .loading
        do {
            let container = if useInMemoryStore {
                try CafeineXStoreFactory.makeInMemoryContainer()
            } else {
                try CafeineXStoreFactory.makePersistentContainer()
            }
            try prepare(container)
            state = .ready(container)
        } catch {
            state = .unavailable(Failure(
                summary: "CafeineX could not open its local storage. Your existing files have not been silently deleted.",
                technicalDetails: String(describing: error)
            ))
        }
    }

    private func prepare(_ container: ModelContainer) throws {
        let context = container.mainContext
        try DrinkLibrary.backfillDetailsIfNeeded(context: context)
        let profiles = try context.fetch(FetchDescriptor<CigaretteProfile>())
        let preferences = try context.fetch(FetchDescriptor<CigarettePreferences>())
        try CigaretteLibrary.bootstrapIfNeeded(
            profiles: profiles,
            preferences: preferences,
            context: context
        )
    }
}
