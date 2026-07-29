import SwiftData
import SwiftUI
import UIKit

struct DrinkEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let drink: Drink?
    let isArchived: Bool

    @State private var name: String
    @State private var caffeineMG: Double
    @State private var category: DrinkCategory
    @State private var isFavorite: Bool

    init(
        drink: Drink? = nil,
        isArchived: Bool = false
    ) {
        self.drink = drink
        self.isArchived = isArchived
        _name = State(initialValue: drink?.name ?? "")
        _caffeineMG = State(initialValue: drink?.caffeineMG ?? 80)
        _category = State(initialValue: drink?.category ?? .coffee)
        _isFavorite = State(initialValue: drink?.isFavorite ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Drink name", text: $name)
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
                } header: {
                    Text("Serving")
                } footer: {
                    Text("Use the amount shown on the package or menu when available.")
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
    }

    private func save() {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let drink {
            drink.name = normalizedName
            drink.caffeineMG = caffeineMG
            drink.categoryRawValue = category.rawValue
            drink.isFavorite = isArchived ? false : isFavorite
        } else {
            modelContext.insert(
                Drink(
                    name: normalizedName,
                    caffeineMG: caffeineMG,
                    category: category,
                    isFavorite: isFavorite
                )
            )
        }

        try? modelContext.save()
        dismiss()
    }
}
