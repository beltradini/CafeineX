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
            }

            Section("Health Guidance") {
                Text("Active estimates and timing windows are informational guidance, not a diagnosis or a measurement of absorbed nicotine.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}
