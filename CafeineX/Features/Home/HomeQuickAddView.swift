import SwiftUI

struct HomeQuickAddView: View {
    let favoriteDrinks: [Drink]
    let addDrink: (Drink) -> Void
    let openQuickAdd: (QuickAddKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Favorites")
                        .font(.title2.bold())
                    Text("One tap logs it now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("More") {
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
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(favoriteDrinks.prefix(6)) { drink in
                        Button {
                            addDrink(drink)
                        } label: {
                            CXSurfaceCard(cornerRadius: CXTheme.smallCornerRadius) {
                                VStack(spacing: 8) {
                                    Image(systemName: drink.category.symbol)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(CXTheme.caffeineAccent)

                                    Text(drink.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text("\(Int(drink.caffeineMG.rounded())) mg")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 76)
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

            HStack {
                Button {
                    openQuickAdd(.nicotine)
                } label: {
                    Label("Log nicotine", systemImage: "waveform.path.ecg")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CXTheme.nicotineAccent)

                NavigationLink {
                    MyDrinksView()
                } label: {
                    Label("My Drinks", systemImage: "mug.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(CXTheme.caffeineAccent)
            }
        }
    }
}
