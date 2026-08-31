//
//  CafeineXShortcuts.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/18/26.
//

import AppIntents

struct CafeineXShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogCaffeineIntent(),
            phrases: [
                "Log caffeine in \(.applicationName)",
                "Record caffeine with \(.applicationName)",
            ],
            shortTitle: "Log Caffeine",
            systemImageName: "cup.and.saucer.fill"
        )

        AppShortcut(
            intent: OpenQuickAddIntent(),
            phrases: [
                "Open Quick Add in \(.applicationName)",
                "Add an exposure in \(.applicationName)",
            ],
            shortTitle: "Quick Add",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: ShowTodaySummaryIntent(),
            phrases: [
                "Show my \(.applicationName) summary",
                "What is my caffeine summary in \(.applicationName)",
            ],
            shortTitle: "Today’s Summary",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: OpenHistoryIntent(),
            phrases: [
                "Open my \(.applicationName) history",
                "Show exposure history in \(.applicationName)",
            ],
            shortTitle: "Open History",
            systemImageName: "clock.arrow.circlepath"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .orange
    }
}
