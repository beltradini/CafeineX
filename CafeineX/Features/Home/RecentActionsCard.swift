import SwiftUI

struct RecentActionsCard: View {
    @Environment(RecentActionStore.self)
    private var recentActionStore

    private let limit: Int

    init(limit: Int = 4) {
        self.limit = limit
    }

    var body: some View {
        let visibleActions = Array(recentActionStore.actions.prefix(limit))

        if !visibleActions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Recent actions", systemImage: "clock.arrow.circlepath")
                        .font(.headline)

                    Spacer()

                    NavigationLink("See all") {
                        RecentActionsView()
                    }
                    .font(.caption.weight(.semibold))
                }

                CXSurfaceCard(
                    contentPadding: EdgeInsets(
                        top: 8,
                        leading: 16,
                        bottom: 8,
                        trailing: 16
                    )
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(visibleActions.enumerated()), id: \.element.id) {
                            index,
                            action in
                            actionRow(action)

                            if index < visibleActions.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("recent-actions-card")
        }
    }

    private func actionRow(_ action: RecentAction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: action.kind.symbolName)
                .foregroundStyle(tint(for: action.kind))
                .font(.headline)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(.subheadline.weight(.semibold))

                if let detail = action.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(action.occurredAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText(for: action))
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
