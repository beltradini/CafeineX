import Foundation
import Observation
import SwiftUI

nonisolated enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    @MainActor
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
@Observable
final class AppearanceStore {
    private static let appearanceKey = "appearance.selection"

    private let defaults: UserDefaults
    private(set) var selection: AppAppearance

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selection = defaults.string(forKey: Self.appearanceKey)
            .flatMap(AppAppearance.init(rawValue:))
            ?? .system
    }

    func setSelection(_ selection: AppAppearance) {
        self.selection = selection
        defaults.set(selection.rawValue, forKey: Self.appearanceKey)
    }

    func reset() {
        setSelection(.system)
    }

    func clearPersistedData() {
        defaults.removeObject(forKey: Self.appearanceKey)
        selection = .system
    }
}
