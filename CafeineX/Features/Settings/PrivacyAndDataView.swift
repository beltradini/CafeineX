import SwiftData
import SwiftUI

struct PrivacyAndDataView: View {
    private let privacyPolicyURL = URL(
        string: "https://cafeinex.com/privacy"
    )!

    @Environment(\.modelContext) private var modelContext
    @Environment(SleepScheduleStore.self) private var sleepScheduleStore
    @Environment(CaffeineSensitivityStore.self) private var sensitivityStore
    @Environment(AppearanceStore.self) private var appearanceStore

    @Query private var caffeineEntries: [CaffeineEntry]
    @Query private var nicotineEntries: [NicotineEntry]
    @Query private var drinks: [Drink]
    @Query private var cigaretteProfiles: [CigaretteProfile]

    @Bindable var viewModel: HomeViewModel
    @State private var deleteOwnedHealthKitSamples = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var isShowingResult = false
    @State private var resultMessage = ""

    var body: some View {
        Form {
            Section("On This Device") {
                LabeledContent("Caffeine events", value: caffeineEntries.count.formatted())
                LabeledContent("Nicotine events", value: nicotineEntries.count.formatted())
                LabeledContent("Drink profiles", value: drinks.count.formatted())
                LabeledContent("Cigarette profiles", value: cigaretteProfiles.count.formatted())
                LabeledContent(
                    "Total events",
                    value: (caffeineEntries.count + nicotineEntries.count).formatted()
                )
            }

            Section("Storage") {
                Label(
                    "CafeineX stores its timeline in SwiftData on this device.",
                    systemImage: "internaldrive.fill"
                )
                Label(
                    "Nicotine records are not written to Apple Health.",
                    systemImage: "waveform.path.ecg"
                )
                Label(
                    "Cigarette profiles, context, goals, and pattern summaries remain local to CafeineX.",
                    systemImage: "smoke.fill"
                )
                Label(
                    "Imported caffeine entries retain their Apple Health identifier to prevent duplicates.",
                    systemImage: "heart.text.square"
                )
                Label(
                    "Sleep samples are summarized in memory and are not copied into SwiftData.",
                    systemImage: "moon.stars.fill"
                )
            }

            Section("Apple Health Scope") {
                LabeledContent("Dietary caffeine", value: "Optional read/write")
                LabeledContent("Sleep analysis", value: "Optional read-only")
                LabeledContent("Heart and other metrics", value: "Not requested")
                LabeledContent("Nicotine", value: "Local only")
            }

            Section("Health Insights") {
                Text("CafeineX places logged stimulant timing beside recorded sleep. It does not claim that one caused the other, rate sleep as good or bad, diagnose a condition, or measure absorbed nicotine.")
                    .foregroundStyle(.secondary)
                Text("When data is missing, limited, or not shared, CafeineX shows an incomplete state instead of estimating values.")
                    .foregroundStyle(.secondary)
            }

            Section("Cigarette Intelligence") {
                Text("CafeineX counts the events you log and compares their timing with your caffeine timeline and planned sleep window. These are descriptive patterns, not causal conclusions or medical advice.")
                    .foregroundStyle(.secondary)
                Text("Any nicotine value entered from packaging is manufacturer label information. CafeineX does not convert it into absorbed nicotine or a safe-use amount.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(
                    "Also delete caffeine samples written by CafeineX from Apple Health",
                    isOn: $deleteOwnedHealthKitSamples
                )
                .disabled(isDeleting)

                Text("Imported Apple Health caffeine and sleep records are never deleted. The optional Health deletion only targets linked caffeine samples written by CafeineX.")
                    .foregroundStyle(.secondary)

                Button("Delete All My CafeineX Data", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
                .disabled(isDeleting)

                if isDeleting {
                    HStack {
                        ProgressView()
                        Text("Deleting data…")
                    }
                }
            } header: {
                Text("Delete CafeineX Data")
            } footer: {
                Text("This removes local caffeine and nicotine events, drink and cigarette profiles, your name and photo, goals and preferences, recovery backups, and local synchronization state. This cannot be undone.")
            }

            Section("Policy & Support") {
                Link(destination: privacyPolicyURL) {
                    Label("View Privacy Policy", systemImage: "hand.raised.fill")
                }

                Label(
                    "Pilot support is available from CafeineX in TestFlight using Send Beta Feedback.",
                    systemImage: "bubble.left.and.bubble.right.fill"
                )

                Text("For privacy requests, begin the feedback message with “PRIVACY”.")
                    .foregroundStyle(.secondary)
            }
        }
        .cxContentBackground()
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete all CafeineX data?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                Task { await deleteAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteConfirmationMessage)
        }
        .alert("Data Deletion", isPresented: $isShowingResult) {
            Button("OK") {}
        } message: {
            Text(resultMessage)
        }
    }

    private var deleteConfirmationMessage: String {
        if deleteOwnedHealthKitSamples {
            return "Local CafeineX data and recovery backups will be removed. CafeineX will also ask Apple Health to delete only its linked caffeine samples. Imported Health data remains untouched."
        }
        return "All local CafeineX data and recovery backups will be removed. Nothing will be deleted from Apple Health."
    }

    @MainActor
    private func deleteAllData() async {
        isDeleting = true
        viewModel.cancelPendingOperationsForDataDeletion()

        do {
            let service = CafeineXDataDeletionService(
                healthKitService: HealthKitService()
            )
            let result = try await service.deleteAllData(
                from: modelContext,
                sleepScheduleStore: sleepScheduleStore,
                sensitivityStore: sensitivityStore,
                appearanceStore: appearanceStore,
                deleteOwnedHealthKitSamples: deleteOwnedHealthKitSamples
            )
            viewModel.resetAfterDataDeletion()
            resultMessage = successMessage(for: result)
            deleteOwnedHealthKitSamples = false
        } catch {
            resultMessage = "CafeineX could not complete the deletion. Some optional Apple Health samples may already have been removed; local CafeineX changes were rolled back when possible. \(error.localizedDescription)"
        }

        isDeleting = false
        isShowingResult = true
    }

    private func successMessage(for result: CafeineXDataDeletionResult) -> String {
        var parts = ["Deleted \(result.localRecordCount) local records and cleared preferences and synchronization state."]
        if result.removedRecoveryBackups {
            parts.append("Old recovery backups were removed.")
        }
        if deleteOwnedHealthKitSamples {
            parts.append("Apple Health deleted \(result.healthKitSampleCount) linked CafeineX caffeine samples.")
        } else {
            parts.append("Apple Health was not changed.")
        }
        return parts.joined(separator: " ")
    }
}
