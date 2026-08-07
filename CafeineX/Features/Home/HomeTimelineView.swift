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
                    CXSurfaceCard(cornerRadius: CXTheme.smallCornerRadius) {
                        HStack(spacing: 10) {
                            NavigationLink {
                                ExposureDetailView(item: item)
                            } label: {
                                ExposureRow(item: item)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)

                            Button {
                                repeatItem(item)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.weight(.bold))
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.bordered)
                            .tint(item.kind == .caffeine
                                ? CXTheme.caffeineAccent
                                : CXTheme.nicotineAccent)
                            .accessibilityLabel("Log \(item.title) again")
                            .accessibilityHint("Adds the same amount at the current time")
                        }
                    }
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
