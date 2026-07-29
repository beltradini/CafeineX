import SwiftUI

enum QuickAddRequest {
    case caffeine(name: String, milligrams: Double, date: Date)
    case nicotine(
        product: NicotineProduct,
        quantity: Double,
        unit: NicotineUnit,
        date: Date,
        note: String?
    )
}

struct QuickAddSheet: View {
    private struct CaffeinePreset: Identifiable {
        let name: String
        let milligrams: Double
        let symbol: String

        var id: String { name }
    }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var kind: QuickAddKind
    @State private var caffeineName = "Espresso"
    @State private var caffeineMG = 64.0
    @State private var caffeineDate = Date.now
    @State private var nicotineProduct = NicotineProduct.cigarette
    @State private var nicotineQuantity = 1.0
    @State private var nicotineUnit = NicotineUnit.pieces
    @State private var nicotineDate = Date.now
    @State private var nicotineNote = ""

    private let onSave: (QuickAddRequest) -> Bool

    private enum Field: Hashable {
        case caffeineName
        case caffeineAmount
        case nicotineAmount
        case nicotineNote
    }

    private let caffeinePresets = [
        CaffeinePreset(name: "Espresso", milligrams: 64, symbol: "cup.and.saucer.fill"),
        CaffeinePreset(name: "Americano", milligrams: 150, symbol: "mug.fill"),
        CaffeinePreset(name: "Latte", milligrams: 120, symbol: "takeoutbag.and.cup.and.straw.fill"),
        CaffeinePreset(name: "Cold Brew", milligrams: 200, symbol: "snowflake"),
    ]

    init(
        initialKind: QuickAddKind = .caffeine,
        onSave: @escaping (QuickAddRequest) -> Bool
    ) {
        _kind = State(initialValue: initialKind)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Exposure type", selection: $kind) {
                        ForEach(QuickAddKind.allCases) { item in
                            Text(item.title)
                                .tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Exposure type")
                }

                switch kind {
                case .caffeine:
                    caffeineForm
                case .nicotine:
                    nicotineForm
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
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
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var caffeineForm: some View {
        Group {
            Section {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(caffeinePresets) { preset in
                            Button {
                                caffeineName = preset.name
                                caffeineMG = preset.milligrams
                            } label: {
                                Label(preset.name, systemImage: preset.symbol)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityHint("\(Int(preset.milligrams)) milligrams")
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } header: {
                Text("Favorites")
            }

            Section {
                TextField("Drink name", text: $caffeineName)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .caffeineName)

                TextField(
                    "Caffeine",
                    value: $caffeineMG,
                    format: .number.precision(.fractionLength(0...1)),
                    prompt: Text("mg")
                )
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .caffeineAmount)

                DatePicker(
                    "Consumed",
                    selection: $caffeineDate,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
            } header: {
                Text("Details")
            } footer: {
                Text("Enter the amount shown on the product when available.")
            }
        }
    }

    private var nicotineForm: some View {
        Group {
            Section {
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
            } header: {
                Text("Product")
            }

            Section {
                TextField(
                    "Amount",
                    value: $nicotineQuantity,
                    format: .number.precision(.fractionLength(0...1))
                )
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .nicotineAmount)

                DatePicker(
                    "Used",
                    selection: $nicotineDate,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )

                TextField("Optional note", text: $nicotineNote, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focusedField, equals: .nicotineNote)
            } header: {
                Text("Details")
            } footer: {
                Text("CafeineX records the product label amount or number of uses. It does not estimate absorbed nicotine.")
            }
        }
    }

    private var isValid: Bool {
        switch kind {
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
        let didSave: Bool
        switch kind {
        case .caffeine:
            didSave = onSave(
                .caffeine(
                    name: caffeineName,
                    milligrams: caffeineMG,
                    date: caffeineDate
                )
            )
        case .nicotine:
            didSave = onSave(
                .nicotine(
                    product: nicotineProduct,
                    quantity: nicotineQuantity,
                    unit: nicotineUnit,
                    date: nicotineDate,
                    note: nicotineNote
                )
            )
        }

        if didSave {
            dismiss()
        }
    }
}

struct QuickAddToolbarButton: View {
    @Environment(QuickAddCoordinator.self) private var coordinator

    var body: some View {
        Button {
            coordinator.present()
        } label: {
            Label("Quick Add", systemImage: "plus")
        }
        .accessibilityHint("Log caffeine or nicotine")
    }
}
