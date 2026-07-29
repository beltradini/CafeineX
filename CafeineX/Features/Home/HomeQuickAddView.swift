import SwiftUI

struct HomeQuickAddView: View {
    let addCaffeine: (String, Double) -> Void
    let openQuickAdd: (QuickAddKind) -> Void

    private let presets: [(name: String, mg: Double, symbol: String)] = [
        ("Espresso", 64, "cup.and.saucer.fill"),
        ("Americano", 150, "mug.fill"),
        ("Latte", 120, "takeoutbag.and.cup.and.straw.fill"),
        ("Cold Brew", 200, "snowflake"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Quick Add")
                    .font(.title2.bold())

                Spacer()

                Button("More") {
                    openQuickAdd(.caffeine)
                }
                .font(.subheadline.weight(.semibold))
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                spacing: 12
            ) {
                ForEach(presets, id: \.name) { preset in
                    Button {
                        addCaffeine(preset.name, preset.mg)
                    } label: {
                        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
                            VStack(spacing: 8) {
                                Image(systemName: preset.symbol)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(CXTheme.caffeineAccent)

                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("\(Int(preset.mg)) mg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 76)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(preset.name), \(Int(preset.mg)) milligrams")
                    .accessibilityHint("Logs it at the current time")
                }
            }

            Button {
                openQuickAdd(.nicotine)
            } label: {
                Label("Log nicotine", systemImage: "waveform.path.ecg")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(CXTheme.nicotineAccent)
        }
    }
}
