import SwiftData
import SwiftUI

struct HealthConnectionSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Status", value: caffeineStatusTitle)

                Button {
                    Task {
                        if viewModel.healthAccessState == .notRequested {
                            await viewModel.requestHealthAccess(context: modelContext)
                        } else {
                            await viewModel.synchronizeHealthKit(context: modelContext)
                        }
                    }
                } label: {
                    if viewModel.isSyncingHealth {
                        HStack {
                            ProgressView()
                            Text("Syncing…")
                        }
                    } else {
                        Label(buttonTitle, systemImage: "heart.fill")
                    }
                }
                .disabled(
                    viewModel.healthAccessState == .unavailable
                        || viewModel.isSyncingHealth
                )
            } header: {
                Text("Caffeine Sync")
            } footer: {
                Text("This permission covers only dietary caffeine. Reading and writing remain separate system choices.")
            }

            Section {
                LabeledContent("Status", value: sleepStatusTitle)

                Button {
                    Task {
                        if viewModel.sleepDataState == .notRequested {
                            await viewModel.requestSleepAccess()
                        } else {
                            await viewModel.refreshSleepSnapshot()
                        }
                    }
                } label: {
                    if viewModel.isLoadingSleep {
                        HStack {
                            ProgressView()
                            Text("Reading…")
                        }
                    } else {
                        Label(
                            viewModel.sleepDataState == .notRequested
                                ? "Choose Sleep Access"
                                : "Refresh Sleep Snapshot",
                            systemImage: "moon.stars.fill"
                        )
                    }
                }
                .disabled(
                    viewModel.sleepDataState == .unavailable
                        || viewModel.isLoadingSleep
                )
            } header: {
                Text("Sleep Context")
            } footer: {
                Text("Read-only access uses recent sleep analysis to show timing context. CafeineX does not request heart rate, HRV, respiratory rate, temperature, or other Health data.")
            }

            if let message = viewModel.healthMessage {
                Section("Caffeine Update") {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy") {
                Text("Apple Health permissions are controlled by the system. HealthKit does not tell apps whether read access was denied, so “no readable data” can also mean no recent samples or limited history.")
                    .foregroundStyle(.secondary)
                Text("Sleep samples are processed on device into an in-memory snapshot and are not copied into SwiftData. Nicotine records remain local.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.refreshHealthAccessState()
            await viewModel.refreshSleepContext()
        }
    }

    private var caffeineStatusTitle: String {
        switch viewModel.healthAccessState {
        case .unavailable: "Unavailable"
        case .notRequested: "Not connected"
        case .writeEnabled: "Caffeine write enabled"
        case .writeDisabled: "Caffeine write disabled"
        }
    }

    private var buttonTitle: String {
        viewModel.healthAccessState == .notRequested ? "Connect Apple Health" : "Sync Now"
    }

    private var sleepStatusTitle: String {
        switch viewModel.sleepDataState {
        case .unavailable: "Unavailable"
        case .notRequested: "Not requested"
        case .loading: "Reading"
        case .noData: "No readable recent data"
        case .available: "Recent snapshot available"
        case .failed: "Could not read"
        }
    }
}
