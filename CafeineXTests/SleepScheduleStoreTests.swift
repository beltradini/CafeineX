import Foundation
import Testing
@testable import CafeineX

@MainActor
struct SleepScheduleStoreTests {
    @Test func schedulePersistsAcrossStoreInstances() throws {
        let suiteName = "SleepScheduleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = SleepScheduleStore(defaults: defaults)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let bedtime = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 7,
                    day: 27,
                    hour: 23,
                    minute: 45
                )
            )
        )

        store.setBedtime(bedtime, calendar: calendar)
        store.setCutoffHoursBeforeBedtime(6)

        let restored = SleepScheduleStore(defaults: defaults)
        #expect(restored.schedule.bedtimeHour == 23)
        #expect(restored.schedule.bedtimeMinute == 45)
        #expect(restored.schedule.cutoffHoursBeforeBedtime == 6)
    }

    @Test func invalidStoredValuesAreClamped() throws {
        let suiteName = "SleepScheduleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set(30, forKey: "sleep.bedtimeHour")
        defaults.set(-15, forKey: "sleep.bedtimeMinute")
        defaults.set(40, forKey: "sleep.cutoffHoursBeforeBedtime")

        let store = SleepScheduleStore(defaults: defaults)

        #expect(store.schedule.bedtimeHour == 23)
        #expect(store.schedule.bedtimeMinute == 0)
        #expect(store.schedule.cutoffHoursBeforeBedtime == 16)
    }
}

