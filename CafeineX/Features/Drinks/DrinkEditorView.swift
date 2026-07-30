import SwiftData
import SwiftUI
import UIKit

struct DrinkEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allDetails: [DrinkDetails]

    let drink: Drink?
    let details: DrinkDetails?
    let isArchived: Bool

    @State private var name: String
    @State private var brand: String
    @State private var caffeineMG: Double
    @State private var category: DrinkCategory
    @State private var servingAmount: Double
    @State private var servingUnit: DrinkServingUnit
    @State private var personalNotes: String
    @State private var isFavorite: Bool

    init(
        drink: Drink? = nil,
        details: DrinkDetails? = nil,
        isArchived: Bool = false
    ) {
        self.drink = drink
        self.details = details
        self.isArchived = isArchived
        _name = State(initialValue: drink?.name ?? "")
        _brand = State(initialValue: details?.brand ?? "")
        _caffeineMG = State(initialValue: drink?.caffeineMG ?? 80)
        _category = State(initialValue: drink?.category ?? .coffee)
        _servingAmount = State(initialValue: details?.servingAmount ?? 0)
        _servingUnit = State(initialValue: details?.servingUnit ?? .milliliters)
        _personalNotes = State(initialValue: details?.personalNotes ?? "")
        _isFavorite = State(initialValue: drink?.isFavorite ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Drink name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Brand or café (optional)", text: $brand)
                        .textInputAutocapitalization(.words)

                    Picker("Category", selection: $category) {
                        ForEach(DrinkCategory.allCases, id: \.self) { category in
                            Label(category.title, systemImage: category.symbol)
                                .tag(category)
                        }
                    }

                    Toggle("Favorite", isOn: $isFavorite)
                        .disabled(isArchived)
                }

                Section {
                    TextField(
                        "Caffeine",
                        value: $caffeineMG,
                        format: .number.precision(.fractionLength(0...1)),
                        prompt: Text("mg")
                    )
                    .keyboardType(.decimalPad)

                    TextField(
                        "Serving size",
                        value: $servingAmount,
                        format: .number.precision(.fractionLength(0...1))
                    )
                    .keyboardType(.decimalPad)

                    Picker("Serving unit", selection: $servingUnit) {
                        ForEach(DrinkServingUnit.allCases) { unit in
                            Text(unit.title)
                                .tag(unit)
                        }
                    }
                } header: {
                    Text("Serving")
                } footer: {
                    Text("Serving size is optional. Use the amount shown on the package or menu when available.")
                }

                Section("Personal Notes") {
                    TextField(
                        "Recipe, size, or context",
                        text: $personalNotes,
                        axis: .vertical
                    )
                    .lineLimit(2...5)
                }
            }
            .navigationTitle(drink == nil ? "New Drink" : "Edit Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && caffeineMG.isFinite
            && (1...1_000).contains(caffeineMG)
            && servingAmount.isFinite
            && (0...5_000).contains(servingAmount)
    }

    private func save() {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let drink {
            drink.name = normalizedName
            drink.caffeineMG = caffeineMG
            drink.categoryRawValue = category.rawValue
            let persistedDetails = details ?? DrinkLibrary.details(
                for: drink,
                in: allDetails,
                context: modelContext
            )
            update(persistedDetails)
            DrinkLibrary.setFavorite(
                isArchived ? false : isFavorite,
                for: drink,
                detailsValues: allDetails + [persistedDetails],
                context: modelContext
            )
        } else {
            let createdDrink = Drink(
                name: normalizedName,
                caffeineMG: caffeineMG,
                category: category,
                isFavorite: isFavorite
            )
            let createdDetails = DrinkDetails(
                drinkID: createdDrink.id,
                favoriteOrder: isFavorite
                    ? DrinkLibrary.nextFavoriteOrder(in: allDetails)
                    : nil,
                drink: createdDrink
            )
            update(createdDetails)
            modelContext.insert(createdDrink)
            modelContext.insert(createdDetails)
        }

        try? modelContext.save()
        dismiss()
    }

    private func update(_ details: DrinkDetails) {
        details.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        details.servingAmount = servingAmount
        details.servingUnit = servingUnit
        details.personalNotes = personalNotes.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        details.updatedAt = .now
    }
}
