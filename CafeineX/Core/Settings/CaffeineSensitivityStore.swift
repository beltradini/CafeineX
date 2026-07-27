import Foundation
import Observation

@MainActor
@Observable
final class CaffeineSensitivityStore {
    private static let profileKey = "caffeine.sensitivityProfile"

    private let defaults: UserDefaults

    private(set) var profile: CaffeineSensitivityProfile

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.profile = defaults.string(forKey: Self.profileKey)
            .flatMap(CaffeineSensitivityProfile.init(rawValue:))
            ?? .typical
    }

    func setProfile(_ profile: CaffeineSensitivityProfile) {
        self.profile = profile
        defaults.set(profile.rawValue, forKey: Self.profileKey)
    }

    func reset() {
        setProfile(.typical)
    }
}

