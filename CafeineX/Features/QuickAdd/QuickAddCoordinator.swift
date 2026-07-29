import Observation

enum QuickAddKind: String, CaseIterable, Identifiable {
    case caffeine
    case nicotine

    var id: Self { self }

    var title: String {
        switch self {
        case .caffeine: "Caffeine"
        case .nicotine: "Nicotine"
        }
    }
}

@MainActor
@Observable
final class QuickAddCoordinator {
    var isPresented = false
    var initialKind: QuickAddKind = .caffeine

    func present(_ kind: QuickAddKind = .caffeine) {
        initialKind = kind
        isPresented = true
    }
}
