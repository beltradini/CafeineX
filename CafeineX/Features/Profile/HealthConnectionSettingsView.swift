import SwiftData
import SwiftUI

struct HealthConnectionSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Status", value: statusTitle)

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
            } footer: {
                Text("CafeineX can import dietary caffeine and save eligible caffeine entries. Nicotine events remain local because Apple Health has no equivalent nicotine quantity type.")
            }

            if let message = viewModel.healthMessage {
                Section("Latest Update") {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy") {
                Text("Apple Health permissions are controlled by the system. CafeineX cannot determine every read permission choice and never writes nicotine records.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.refreshHealthAccessState()
        }
    }

    private var statusTitle: String {
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
}
