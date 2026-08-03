import SwiftUI

struct HomeTimelineView: View {
    let items: [ExposureItem]
    let openQuickAdd: () -> Void
    let repeatItem: (ExposureItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.title2.bold())

            if items.isEmpty {
                CXSurfaceCard {
                    ContentUnavailableView {
                        Label("No exposure logged", systemImage: "clock")
                    } description: {
                        Text("Caffeine and nicotine events will appear here.")
                    } actions: {
                        Button("Quick Add", action: openQuickAdd)
                            .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ForEach(items) { item in
                    NavigationLink {
                        ExposureDetailView(item: item)
                    } label: {
                        CXSurfaceCard(cornerRadius: CXTheme.smallCornerRadius) {
                            ExposureRow(item: item)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            repeatItem(item)
                        } label: {
                            Label("Log Again", systemImage: "arrow.clockwise")
                        }
                    }
                    .accessibilityHint("Open details. Long press to log again.")
                }
            }
        }
    }
}
