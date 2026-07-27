import SwiftUI

struct GuidanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let sleepScheduleStore: SleepScheduleStore
    let sensitivityStore: CaffeineSensitivityStore

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Bedtime",
                        selection: bedtimeBinding,
                        displayedComponents: .hourAndMinute
                    )

                    Stepper(
                        "Stop caffeine \(sleepScheduleStore.schedule.cutoffHoursBeforeBedtime) hours before",
                        value: cutoffBinding,
                        in: 1...16
                    )
                } header: {
                    Text("Sleep schedule")
                } footer: {
                    Text("CafeineX uses this schedule to estimate caffeine remaining at bedtime and your suggested cutoff. It does not change alarms or your Apple Health sleep schedule.")
                }

                Section {
                    Picker("Response", selection: sensitivityBinding) {
                        ForEach(CaffeineSensitivityProfile.allCases) { profile in
                            Text(profile.title)
                                .tag(profile)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(sensitivityStore.profile.guidanceDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Caffeine sensitivity")
                } footer: {
                    Text("Sensitivity changes when guidance appears. It does not claim to measure metabolism and never raises the 400 mg general adult reference.")
                }

                Section {
                    Button("Restore defaults", role: .destructive) {
                        sleepScheduleStore.reset()
                        sensitivityStore.reset()
                    }
                }
            }
            .navigationTitle("Personal Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var bedtimeBinding: Binding<Date> {
        Binding(
            get: { sleepScheduleStore.bedtimeDate() },
            set: { sleepScheduleStore.setBedtime($0) }
        )
    }

    private var cutoffBinding: Binding<Int> {
        Binding(
            get: { sleepScheduleStore.schedule.cutoffHoursBeforeBedtime },
            set: { sleepScheduleStore.setCutoffHoursBeforeBedtime($0) }
        )
    }

    private var sensitivityBinding: Binding<CaffeineSensitivityProfile> {
        Binding(
            get: { sensitivityStore.profile },
            set: { sensitivityStore.setProfile($0) }
        )
    }
}

#Preview {
    GuidanceSettingsView(
        sleepScheduleStore: SleepScheduleStore(),
        sensitivityStore: CaffeineSensitivityStore()
    )
}
