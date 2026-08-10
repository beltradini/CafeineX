import SwiftUI

struct HomeQuickAddView: View {
    let favoriteDrinks: [Drink]
    let addDrink: (Drink) -> Void
    let openQuickAdd: (QuickAddKind) -> Void
    let nicotineProduct: NicotineProduct
    let nicotineQuantity: Double
    let logNicotine: () -> Bool

    @State private var isLoggingNicotine = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Favorites", systemImage: "star.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CXTheme.caffeineAccent)

                Spacer()

                Button("See all") {
                    openQuickAdd(.caffeine)
                }
                .font(.subheadline.weight(.semibold))
            }

            if favoriteDrinks.isEmpty {
                CXSurfaceCard(cornerRadius: CXTheme.smallCornerRadius) {
                    ContentUnavailableView {
                        Label("No favorite drinks", systemImage: "star")
                    } description: {
                        Text("Choose favorites from your drink library.")
                    } actions: {
                        NavigationLink("Manage My Drinks") {
                            MyDrinksView()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(favoriteDrinks.prefix(6)) { drink in
                            Button {
                                addDrink(drink)
                            } label: {
                                CXSurfaceCard(cornerRadius: CXTheme.smallCornerRadius) {
                                    HStack(spacing: 10) {
                                        Image(systemName: drink.category.symbol)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(CXTheme.caffeineAccent)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(drink.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)

                                            Text("\(Int(drink.caffeineMG.rounded())) mg")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(width: 142, alignment: .leading)
                                    .frame(minHeight: 54)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                "Add \(drink.name), \(Int(drink.caffeineMG)) milligrams"
                            )
                            .accessibilityHint("Logs it at the current time")
                        }
                    }
                }
            }

            nicotineQuickAction
        }
    }

    private var nicotineQuickAction: some View {
        Button {
            guard !isLoggingNicotine else { return }
            isLoggingNicotine = true
            _ = logNicotine()

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                isLoggingNicotine = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: nicotineProduct.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CXTheme.nicotineAccent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Log nicotine")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(nicotineProduct.title) · \(nicotineQuantity.formatted(.number.precision(.fractionLength(0...1))))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CXTheme.nicotineAccent)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .background(CXTheme.nicotineAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: CXTheme.smallCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: CXTheme.smallCornerRadius)
                    .stroke(CXTheme.nicotineAccent.opacity(0.28), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoggingNicotine)
        .accessibilityLabel("Log \(nicotineProduct.title), \(nicotineQuantity.formatted(.number.precision(.fractionLength(0...1))))")
        .accessibilityHint("Records your usual nicotine exposure now")
        .accessibilityIdentifier("home-quick-log-nicotine-button")
        .contextMenu {
            Button {
                openQuickAdd(.nicotine)
            } label: {
                Label("Customize nicotine", systemImage: "slider.horizontal.3")
            }
        }
    }
}
