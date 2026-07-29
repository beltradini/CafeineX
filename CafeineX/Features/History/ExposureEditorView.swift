import SwiftData
import SwiftUI

struct ExposureEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: Field?

    let item: ExposureItem

    @State private var caffeineName: String
    @State private var caffeineMG: Double
    @State private var caffeineDate: Date
    @State private var nicotineProduct: NicotineProduct
    @State private var nicotineQuantity: Double
    @State private var nicotineUnit: NicotineUnit
    @State private var nicotineDate: Date
    @State private var nicotineNote: String
    @State private var errorMessage: String?

    private enum Field: Hashable {
        case name
        case amount
        case note
    }

    init(item: ExposureItem) {
        self.item = item

        switch item {
        case .caffeine(let entry):
            _caffeineName = State(initialValue: entry.drinkName)
            _caffeineMG = State(initialValue: entry.caffeineMG)
            _caffeineDate = State(initialValue: entry.consumedAt)
            _nicotineProduct = State(initialValue: .other)
            _nicotineQuantity = State(initialValue: 1)
            _nicotineUnit = State(initialValue: .pieces)
            _nicotineDate = State(initialValue: .now)
            _nicotineNote = State(initialValue: "")
        case .nicotine(let entry):
            _caffeineName = State(initialValue: "")
            _caffeineMG = State(initialValue: 1)
            _caffeineDate = State(initialValue: .now)
            _nicotineProduct = State(initialValue: entry.product)
            _nicotineQuantity = State(initialValue: entry.quantity)
            _nicotineUnit = State(initialValue: entry.unit)
            _nicotineDate = State(initialValue: entry.usedAt)
            _nicotineNote = State(initialValue: entry.note ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                switch item {
                case .caffeine:
                    caffeineForm
                case .nicotine:
                    nicotineForm
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onChange(of: nicotineProduct) { _, product in
                if !product.allowedUnits.contains(nicotineUnit) {
                    nicotineUnit = product.defaultUnit
                }
            }
            .alert(
                "Could Not Save",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var caffeineForm: some View {
        Section("Caffeine") {
            TextField("Drink name", text: $caffeineName)
                .focused($focusedField, equals: .name)

            TextField(
                "Milligrams",
                value: $caffeineMG,
                format: .number.precision(.fractionLength(0...1))
            )
            .keyboardType(.decimalPad)
            .focused($focusedField, equals: .amount)

            DatePicker(
                "Consumed",
                selection: $caffeineDate,
                in: ...Date.now,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var nicotineForm: some View {
        Group {
            Section("Product") {
                Picker("Product", selection: $nicotineProduct) {
                    ForEach(NicotineProduct.allCases) { product in
                        Label(product.title, systemImage: product.symbol)
                            .tag(product)
                    }
                }

                Picker("Unit", selection: $nicotineUnit) {
                    ForEach(nicotineProduct.allowedUnits) { unit in
                        Text(unit.title)
                            .tag(unit)
                    }
                }
            }

            Section("Details") {
                TextField(
                    "Amount",
                    value: $nicotineQuantity,
                    format: .number.precision(.fractionLength(0...1))
                )
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)

                DatePicker(
                    "Used",
                    selection: $nicotineDate,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )

                TextField("Optional note", text: $nicotineNote, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focusedField, equals: .note)
            }
        }
    }

    private var isValid: Bool {
        switch item {
        case .caffeine:
            !caffeineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && caffeineMG.isFinite
                && (1...1_000).contains(caffeineMG)
        case .nicotine:
            nicotineQuantity.isFinite
                && (0.1...1_000).contains(nicotineQuantity)
                && nicotineProduct.allowedUnits.contains(nicotineUnit)
        }
    }

    private func save() {
        switch item {
        case .caffeine(let entry):
            entry.drinkName = caffeineName.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.caffeineMG = caffeineMG
            entry.consumedAt = min(caffeineDate, .now)
        case .nicotine(let entry):
            entry.productRawValue = nicotineProduct.rawValue
            entry.quantity = nicotineQuantity
            entry.unitRawValue = nicotineUnit.rawValue
            entry.usedAt = min(nicotineDate, .now)
            let normalizedNote = nicotineNote.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.note = normalizedNote.isEmpty ? nil : normalizedNote
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
