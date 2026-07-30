import SwiftData
import SwiftUI

struct MyDrinksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Drink.name) private var drinks: [Drink]
    @Query private var detailsValues: [DrinkDetails]

    @State private var searchText = ""
    @State private var editingDrink: Drink?
    @State private var isCreatingDrink = false
    @State private var showingArchived = false
    @State private var permanentlyDeleting: Drink?
    @State private var feedbackTrigger = 0

    var body: some View {
        List {
            if visibleDrinks.isEmpty {
                ContentUnavailableView {
                    Label(
                        showingArchived ? "No archived drinks" : "No matching drinks",
                        systemImage: showingArchived ? "archivebox" : "mug"
                    )
                } description: {
                    Text(
                        showingArchived
                            ? "Archived drinks stay out of Quick Add until you restore them."
                            : "Create a drink or try another search."
                    )
                }
                .listRowBackground(Color.clear)
            } else if !showingArchived && searchText.isEmpty {
                if !favoriteDrinks.isEmpty {
                    Section("Favorites") {
                        ForEach(favoriteDrinks) { drink in
                            managedRow(drink)
                        }
                        .onMove(perform: moveFavorites)
                    }
                }

                if !otherActiveDrinks.isEmpty {
                    Section("Other Drinks") {
                        ForEach(otherActiveDrinks) { drink in
                            managedRow(drink)
                        }
                    }
                }
            } else {
                ForEach(visibleDrinks) { drink in
                    managedRow(drink)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My Drinks")
        .searchable(text: $searchText, prompt: "Search drinks")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingArchived.toggle()
                } label: {
                    Label(
                        showingArchived ? "Active Drinks" : "Archived Drinks",
                        systemImage: showingArchived ? "mug.fill" : "archivebox"
                    )
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !showingArchived, searchText.isEmpty, !favoriteDrinks.isEmpty {
                    EditButton()
                }

                Button {
                    isCreatingDrink = true
                } label: {
                    Label("New Drink", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreatingDrink) {
            DrinkEditorView()
        }
        .sheet(item: $editingDrink) { drink in
            DrinkEditorView(
                drink: drink,
                details: DrinkLibrary.existingDetails(
                    for: drink,
                    in: detailsValues
                ),
                isArchived: isArchived(drink)
            )
        }
        .confirmationDialog(
            "Delete this archived drink permanently?",
            isPresented: Binding(
                get: { permanentlyDeleting != nil },
                set: { if !$0 { permanentlyDeleting = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                if let drink = permanentlyDeleting {
                    if let details = DrinkLibrary.existingDetails(
                        for: drink,
                        in: detailsValues
                    ) {
                        modelContext.delete(details)
                    }
                    modelContext.delete(drink)
                    try? modelContext.save()
                }
                permanentlyDeleting = nil
            }
            Button("Cancel", role: .cancel) {
                permanentlyDeleting = nil
            }
        } message: {
            Text("Past exposure events will remain in History.")
        }
        .sensoryFeedback(.success, trigger: feedbackTrigger)
        .task {
            DrinkLibrary.bootstrapIfNeeded(drinks: drinks, context: modelContext)
        }
    }

    private func managedRow(_ drink: Drink) -> some View {
        drinkRow(drink)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if !isArchived(drink) {
                    Button {
                        DrinkLibrary.setFavorite(
                            !drink.isFavorite,
                            for: drink,
                            detailsValues: detailsValues,
                            context: modelContext
                        )
                        feedbackTrigger += 1
                    } label: {
                        Label(
                            drink.isFavorite ? "Unfavorite" : "Favorite",
                            systemImage: drink.isFavorite ? "star.slash" : "star.fill"
                        )
                    }
                    .tint(CXTheme.caffeineAccent)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if isArchived(drink) {
                    Button {
                        DrinkLibrary.restore(
                            drink,
                            detailsValues: detailsValues,
                            context: modelContext
                        )
                        feedbackTrigger += 1
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                    .tint(CXTheme.healthAccent)

                    Button("Delete", systemImage: "trash", role: .destructive) {
                        permanentlyDeleting = drink
                    }
                } else {
                    Button {
                        DrinkLibrary.archive(
                            drink,
                            detailsValues: detailsValues,
                            context: modelContext
                        )
                        feedbackTrigger += 1
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.gray)
                }
            }
    }

    private func drinkRow(_ drink: Drink) -> some View {
        Button {
            editingDrink = drink
        } label: {
            HStack(spacing: 14) {
                Image(systemName: drink.category.symbol)
                    .font(.title3)
                    .foregroundStyle(
                        isArchived(drink) ? Color.secondary : CXTheme.caffeineAccent
                    )
                    .frame(width: 34, height: 34)
                    .background(CXTheme.caffeineAccent.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(drink.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if drink.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(CXTheme.caffeineAccent)
                                .accessibilityLabel("Favorite")
                        }
                    }

                    Text(drinkDescription(drink))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if useCount(for: drink) > 0 {
                        Text("Used \(useCount(for: drink)) \(useCount(for: drink) == 1 ? "time" : "times")")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Edit this drink")
    }

    private var visibleDrinks: [Drink] {
        drinks
            .filter { isArchived($0) == showingArchived }
            .filter {
                searchText.isEmpty
                    || $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.category.title.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                if $0.isFavorite != $1.isFavorite {
                    return $0.isFavorite && !$1.isFavorite
                }
                let lhsOrder = details(for: $0)?.favoriteOrder
                let rhsOrder = details(for: $1)?.favoriteOrder
                if $0.isFavorite, lhsOrder != rhsOrder {
                    return (lhsOrder ?? .max) < (rhsOrder ?? .max)
                }
                if showingArchived {
                    let lhsArchivedAt = details(for: $0)?.archivedAt
                    let rhsArchivedAt = details(for: $1)?.archivedAt
                    if lhsArchivedAt != rhsArchivedAt {
                        return (lhsArchivedAt ?? .distantPast)
                            > (rhsArchivedAt ?? .distantPast)
                    }
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var favoriteDrinks: [Drink] {
        visibleDrinks.filter(\.isFavorite)
    }

    private var otherActiveDrinks: [Drink] {
        visibleDrinks.filter { !$0.isFavorite }
    }

    private func details(for drink: Drink) -> DrinkDetails? {
        DrinkLibrary.existingDetails(for: drink, in: detailsValues)
    }

    private func isArchived(_ drink: Drink) -> Bool {
        details(for: drink)?.isArchived ?? false
    }

    private func useCount(for drink: Drink) -> Int {
        details(for: drink)?.useCount ?? 0
    }

    private func drinkDescription(_ drink: Drink) -> String {
        let details = details(for: drink)
        return [
            "\(Int(drink.caffeineMG.rounded())) mg",
            details?.brand.nilIfEmpty,
            details?.servingDescription,
            drink.category.title,
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
    }

    private func moveFavorites(
        from source: IndexSet,
        to destination: Int
    ) {
        var reordered = favoriteDrinks
        reordered.move(fromOffsets: source, toOffset: destination)
        DrinkLibrary.reorderFavorites(
            reordered,
            detailsValues: detailsValues,
            context: modelContext
        )
        feedbackTrigger += 1
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
