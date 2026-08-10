//
//  CafeineXApp.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftData
import SwiftUI

@main
struct CafeineXApp: App {
    @AppStorage(CafeineXOnboarding.completionKey) private var hasCompletedOnboarding = false
    @AppStorage(CafeineXWhatsNew.completionKey) private var hasSeenWhatsNew = false
    @State private var persistenceController = CafeineXPersistenceController(
        useInMemoryStore: ProcessInfo.processInfo.arguments.contains("-ui-testing")
    )
    @State private var persistenceIssueCenter = PersistenceIssueCenter()
    @State private var sleepScheduleStore = SleepScheduleStore()
    @State private var sensitivityStore = CaffeineSensitivityStore()
    @State private var appearanceStore = AppearanceStore()
    @State private var notificationPreferencesStore = NotificationPreferencesStore()
    @State private var recentActionStore = RecentActionStore()

    var body: some Scene {
        WindowGroup {
            switch persistenceController.state {
            case .loading:
                ProgressView("Opening CafeineX…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .ready(let container):
                Group {
                    if shouldShowOnboarding {
                        OnboardingView {
                            hasCompletedOnboarding = true
                        }
                    } else if shouldShowWhatsNew {
                        WhatsNewView {
                            hasSeenWhatsNew = true
                        }
                    } else {
                        AppShellView(persistenceIssueCenter: persistenceIssueCenter)
                    }
                }
                .environment(sleepScheduleStore)
                .environment(sensitivityStore)
                .environment(appearanceStore)
                .environment(notificationPreferencesStore)
                .environment(recentActionStore)
                .modelContainer(container)

            case .unavailable(let failure):
                StorageUnavailableView(
                    failure: failure,
                    retry: persistenceController.retry,
                    preserveAndStartFresh: persistenceController.preserveAndStartFresh
                )
            }
        }
    }

    private var shouldShowOnboarding: Bool {
        guard !ProcessInfo.processInfo.arguments.contains("-ui-testing") else {
            return ProcessInfo.processInfo.arguments.contains("-show-onboarding")
        }
        return !hasCompletedOnboarding
    }

    private var shouldShowWhatsNew: Bool {
        guard hasCompletedOnboarding else { return false }
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            return ProcessInfo.processInfo.arguments.contains("-show-whats-new")
        }
        return !hasSeenWhatsNew
    }
}
