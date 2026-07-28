import SwiftUI

struct NicotineEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var product = NicotineProduct.cigarette
    @State private var unit = NicotineProduct.cigarette.defaultUnit
    @State private var quantity = 1.0
    @State private var usedAt = Date.now
    @State private var note = ""

    let onSave: (
        NicotineProduct,
        Double,
        NicotineUnit,
        Date,
        String?
    ) -> Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    Picker("Type", selection: $product) {
                        ForEach(NicotineProduct.allCases) { option in
                            Label(option.title, systemImage: option.symbol)
                                .tag(option)
                        }
                    }

                    Picker("Unit", selection: $unit) {
                        ForEach(product.allowedUnits) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        TextField("Amount", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)

                        Text(unit.shortLabel)
                            .foregroundStyle(.secondary)
                    }

                    DatePicker(
                        "Time",
                        selection: $usedAt,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Optional note") {
                    TextField("Context or cue", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Label(
                        "CafeineX records the product, amount, and timing you enter. It does not estimate absorbed nicotine or replace medical advice.",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Log Nicotine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        if onSave(
                            product,
                            quantity,
                            unit,
                            usedAt,
                            normalizedNote.isEmpty ? nil : normalizedNote
                        ) {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: product) { _, newProduct in
                if !newProduct.allowedUnits.contains(unit) {
                    unit = newProduct.defaultUnit
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var isValid: Bool {
        quantity.isFinite && quantity > 0 && quantity <= 1_000
    }
}

#Preview {
    NicotineEntrySheet { _, _, _, _, _ in true }
}
