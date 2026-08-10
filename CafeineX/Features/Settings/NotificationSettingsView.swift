import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(NotificationPreferencesStore.self)
    private var notificationStore

    @Environment(SleepScheduleStore.self)
    private var sleepScheduleStore

    @Query(sort: \Drink.name)
    private var drinks: [Drink]

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var errorMessage: String?

    private let scheduler = NotificationScheduler()

    var body: some View {
        Form {
            authorizationSection

            Section {
                Toggle(
                    "Usual drink reminder",
                    isOn: habitualDrinkEnabledBinding
                )
                .disabled(favoriteDrinks.isEmpty)

                if notificationStore.preferences.habitualDrinkEnabled {
                    Picker("Drink", selection: habitualDrinkIDBinding) {
                        Text("Select a drink")
                            .tag(UUID?.none)

                        ForEach(favoriteDrinks) { drink in
                            Text(drink.name)
                                .tag(Optional(drink.id))
                        }
                    }

                    DatePicker(
                        "Reminder time",
                        selection: habitualDrinkTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Habitual drink")
            } footer: {
                Text(
                    favoriteDrinks.isEmpty
                        ? "Mark a drink as a favorite before enabling this reminder."
                        : "CafeineX will ask whether you had it. It will never assume that you did."
                )
            }

            Section {
                Toggle(
                    "Review sleep window",
                    isOn: sleepWindowEnabledBinding
                )
            } header: {
                Text("Sleep guidance")
            } footer: {
                Text("Uses your bedtime and caffeine cutoff settings.")
            }

            Section {
                Toggle(
                    "Daily exposure check-in",
                    isOn: forgottenExposureEnabledBinding
                )

                if notificationStore.preferences.forgottenExposureEnabled {
                    DatePicker(
                        "Check-in time",
                        selection: forgottenExposureTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Daily check-in")
            } footer: {
                Text("This asks you to review today's records. It does not claim that you forgot an exposure.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cxContentBackground()
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            authorizationStatus = await scheduler.authorizationStatus()
        }
    }

    private var authorizationSection: some View {
        Section {
            switch authorizationStatus {
            case .authorized, .provisional:
                Label("Notifications are enabled", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(CXTheme.healthAccent)

            case .denied:
                Button("Open Notification Settings") {
                    openSystemSettings()
                }

            case .notDetermined:
                Text("Enable a reminder below when you are ready. CafeineX will ask for permission then.")
                    .foregroundStyle(.secondary)

            default:
                Text("Notification availability is controlled by iOS.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Permission")
        }
    }

    private var favoriteDrinks: [Drink] {
        drinks.filter(\.isFavorite)
    }

    private var habitualDrinkEnabledBinding: Binding<Bool> {
        Binding(
            get: {
                notificationStore.preferences.habitualDrinkEnabled
            },
            set: { enabled in
                guard !enabled || !favoriteDrinks.isEmpty else { return }

                notificationStore.update {
                    $0.habitualDrinkEnabled = enabled
                    if enabled, $0.habitualDrinkID == nil {
                        $0.habitualDrinkID = favoriteDrinks.first?.id
                    }
                }
                reschedule()
            }
        )
    }

    private var habitualDrinkIDBinding: Binding<UUID?> {
        Binding(
            get: {
                notificationStore.preferences.habitualDrinkID
            },
            set: { identifier in
                notificationStore.update {
                    $0.habitualDrinkID = identifier
                }
                reschedule()
            }
        )
    }

    private var habitualDrinkTimeBinding: Binding<Date> {
        Binding(
            get: {
                notificationStore.preferences.habitualDrinkTime.date
            },
            set: { date in
                notificationStore.update {
                    $0.habitualDrinkTime = NotificationTime(date: date)
                }
                reschedule()
            }
        )
    }

    private var sleepWindowEnabledBinding: Binding<Bool> {
        Binding(
            get: {
                notificationStore.preferences.sleepWindowEnabled
            },
            set: { enabled in
                notificationStore.update {
                    $0.sleepWindowEnabled = enabled
                }
                reschedule()
            }
        )
    }

    private var forgottenExposureEnabledBinding: Binding<Bool> {
        Binding(
            get: {
                notificationStore.preferences.forgottenExposureEnabled
            },
            set: { enabled in
                notificationStore.update {
                    $0.forgottenExposureEnabled = enabled
                }
                reschedule()
            }
        )
    }

    private var forgottenExposureTimeBinding: Binding<Date> {
        Binding(
            get: {
                notificationStore.preferences.forgottenExposureTime.date
            },
            set: { date in
                notificationStore.update {
                    $0.forgottenExposureTime = NotificationTime(date: date)
                }
                reschedule()
            }
        )
    }

    private func reschedule() {
        Task { @MainActor in
            do {
                let preferences = notificationStore.preferences
                let hasEnabledReminder = preferences.habitualDrinkEnabled
                    || preferences.sleepWindowEnabled
                    || preferences.forgottenExposureEnabled

                guard hasEnabledReminder else {
                    scheduler.cancelAll()
                    authorizationStatus = await scheduler.authorizationStatus()
                    errorMessage = nil
                    return
                }

                if await scheduler.authorizationStatus() == .notDetermined {
                    let granted = try await scheduler.requestAuthorization()
                    guard granted else {
                        authorizationStatus = .denied
                        return
                    }
                }

                authorizationStatus = await scheduler.authorizationStatus()

                let selectedDrink = drinks.first {
                    $0.id == notificationStore.preferences.habitualDrinkID
                }

                try await scheduler.reschedule(
                    preferences: preferences,
                    sleepSchedule: sleepScheduleStore.schedule,
                    drinkName: selectedDrink?.name
                )
                errorMessage = nil
            } catch {
                errorMessage = "CafeineX could not update notification reminders."
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }
}
