import SwiftUI

struct StorageUnavailableView: View {
    let failure: CafeineXPersistenceController.Failure
    let retry: () -> Void
    let preserveAndStartFresh: () -> Void

    @State private var isConfirmingRecovery = false

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Storage Needs Attention", systemImage: "internaldrive.fill.trianglebadge.exclamationmark")
            } description: {
                VStack(spacing: 12) {
                    Text(failure.summary)
                    Text("Try opening it again first. If that still fails, CafeineX can preserve the unreadable store in Recovery and create a fresh local store.")
                }
            } actions: {
                VStack(spacing: 12) {
                    Button("Try Again", action: retry)
                        .buttonStyle(.borderedProminent)

                    Button("Preserve Data and Start Fresh", role: .destructive) {
                        isConfirmingRecovery = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("CafeineX Support")
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 6) {
                    Text("Pilot support: use Send Beta Feedback in TestFlight.")
                    Text("Begin the message with STORAGE-OPEN and include the details below.")
                    Text(failure.technicalDetails)
                        .font(.caption2.monospaced())
                        .lineLimit(4)
                        .textSelection(.enabled)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding()
            }
        }
        .confirmationDialog(
            "Create a fresh local store?",
            isPresented: $isConfirmingRecovery,
            titleVisibility: .visible
        ) {
            Button("Preserve Existing Store and Continue", role: .destructive) {
                preserveAndStartFresh()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("CafeineX will copy the current store and its sidecar files into the Recovery folder before replacing the active store. The recovered app starts without the unavailable local records.")
        }
    }
}
