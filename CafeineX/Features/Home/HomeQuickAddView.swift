import SwiftUI

struct HomeQuickAddView: View {
    let favoriteDrinks: [Drink]
    let addDrink: (Drink) -> Void
    let openQuickAdd: (QuickAddKind) -> Void

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
        }
    }
}
