import SwiftUI

struct RecentActionsView: View {
    @Environment(RecentActionStore.self)
    private var recentActionStore

    var body: some View {
        List {
            if recentActionStore.actions.isEmpty {
                ContentUnavailableView(
                    "No recent actions",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Your CafeineX actions will appear here.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(recentActionStore.actions) { action in
                    HStack(spacing: 12) {
                        Image(systemName: action.kind.symbolName)
                            .foregroundStyle(tint(for: action.kind))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(.headline)

                            if let detail = action.detail {
                                Text(detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(action.occurredAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(action.occurredAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilityText(for: action))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Recent actions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tint(for kind: RecentActionKind) -> Color {
        switch kind {
        case .logged, .loggedAgain:
            CXTheme.caffeineAccent
        case .undone, .synced:
            CXTheme.healthAccent
        case .edited:
            CXTheme.nicotineAccent
        }
    }

    private func accessibilityText(for action: RecentAction) -> String {
        [
            action.title,
            action.detail,
            action.occurredAt.formatted(date: .abbreviated, time: .shortened),
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

