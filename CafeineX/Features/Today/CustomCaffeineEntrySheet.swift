import SwiftUI

struct CustomCaffeineEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = "Coffee"
    @State private var milligrams = 80.0
    @State private var consumedAt = Date.now

    let onSave: (_ name: String, _ milligrams: Double, _ consumedAt: Date) -> Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Drink") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    HStack {
                        TextField("Caffeine", value: $milligrams, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.decimalPad)
                        Text("mg")
                            .foregroundStyle(.secondary)
                    }

                    DatePicker(
                        "Consumed",
                        selection: $consumedAt,
                        in: ...Date.now,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section {
                    Text("Caffeine varies by serving size and preparation. Use the label or café information when available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Caffeine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onSave(name, milligrams, consumedAt) {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && milligrams.isFinite
            && (1...1_000).contains(milligrams)
    }
}

#Preview {
    CustomCaffeineEntrySheet { _, _, _ in true }
}
