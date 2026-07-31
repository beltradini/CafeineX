import SwiftData
import SwiftUI

struct PrivacyAndDataView: View {
    @Query private var caffeineEntries: [CaffeineEntry]
    @Query private var nicotineEntries: [NicotineEntry]

    var body: some View {
        Form {
            Section("On This Device") {
                LabeledContent("Caffeine events", value: caffeineEntries.count.formatted())
                LabeledContent("Nicotine events", value: nicotineEntries.count.formatted())
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
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}
