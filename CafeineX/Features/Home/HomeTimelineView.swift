import SwiftUI

struct HomeTimelineView: View {
    let items: [ExposureItem]
    let openQuickAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.title2.bold())

            if items.isEmpty {
                CXGlassCard {
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
                    CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
                        ExposureRow(item: item)
                    }
                }
            }
        }
    }
}
