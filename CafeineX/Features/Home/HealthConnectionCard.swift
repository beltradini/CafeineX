import SwiftUI

struct HealthConnectionCard: View {
    let state: HomeViewModel.HealthAccessState
    let isSyncing: Bool
    let action: () -> Void

    var body: some View {
        CXSurfaceCard(cornerRadius: CXTheme.smallCornerRadius) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health")
                        .font(.headline)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button(action: action) {
                    if isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(state == .notRequested ? "Connect" : "Sync")
                            .font(.caption.weight(.semibold))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(state == .unavailable || isSyncing)
                .accessibilityHint("Imports caffeine records and updates eligible entries")
            }
        }
    }

    private var symbol: String {
        switch state {
        case .writeEnabled: "heart.fill"
        case .notRequested: "heart.circle"
        case .writeDisabled, .unavailable: "heart.slash.fill"
        }
    }

    private var tint: Color {
        state == .writeEnabled ? CXTheme.healthAccent : CXTheme.warningAccent
    }

    private var statusText: String {
        switch state {
        case .unavailable:
            "Unavailable on this device."
        case .notRequested:
            "Connect to import and save caffeine records."
        case .writeEnabled:
            "Connected. Imported records follow your read choice."
        case .writeDisabled:
            "Writing is off. Local tracking remains available."
        }
    }
}
