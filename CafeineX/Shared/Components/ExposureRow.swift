import SwiftUI

struct ExposureRow: View {
    let item: ExposureItem
    var showsDate = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: item.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let note = item.note {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Text(item.amountText)
                .font(.headline)
                .foregroundStyle(tint)
                .multilineTextAlignment(.trailing)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
    }

    private var tint: Color {
        item.kind == .caffeine ? CXTheme.caffeineAccent : CXTheme.nicotineAccent
    }

    private var metadataText: String {
        let date = showsDate
            ? item.date.formatted(date: .abbreviated, time: .shortened)
            : item.date.formatted(date: .omitted, time: .shortened)
        return "\(date) • \(item.sourceTitle)"
    }
}
