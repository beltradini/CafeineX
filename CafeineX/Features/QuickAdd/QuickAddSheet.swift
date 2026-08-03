import SwiftData
import SwiftUI

enum QuickAddRequest {
    case caffeine(
        drinkID: UUID?,
        name: String,
        milligrams: Double,
        date: Date
    )
    case nicotine(
        product: NicotineProduct,
        quantity: Double,
        unit: NicotineUnit,
        date: Date,
        note: String?,
        cigaretteProfileID: UUID?,
        cigaretteContext: CigaretteContext?
    )
}

struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PersistenceIssueCenter.self) private var persistenceIssues
    @Query(sort: \Drink.name) private var drinks: [Drink]
    @Query private var drinkDetails: [DrinkDetails]
    @Query private var cigaretteProfiles: [CigaretteProfile]
    @Query private var cigarettePreferences: [CigarettePreferences]
    @FocusState private var focusedField: Field?

    @State private var kind: QuickAddKind
    @State private var caffeineName = "Espresso"
    @State private var caffeineMG = 64.0
    @State private var caffeineDate = Date.now
    @State private var selectedDrinkID: UUID?
    @State private var nicotineProduct = NicotineProduct.cigarette
    @State private var nicotineQuantity = 1.0
    @State private var nicotineUnit = NicotineUnit.pieces
    @State private var nicotineDate = Date.now
    @State private var nicotineNote = ""
    @State private var selectedCigaretteProfileID: UUID?
    @State private var cigaretteContext: CigaretteContext?

    private let onSave: (QuickAddRequest) -> Bool

    private enum Field: Hashable {
        case caffeineName
        case caffeineAmount
        case nicotineAmount
        case nicotineNote
    }

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
            .task {
                persistenceIssues.attempt("Preparing quick-add libraries") {
                    try DrinkLibrary.bootstrapIfNeeded(drinks: drinks, context: modelContext)
                    try CigaretteLibrary.bootstrapIfNeeded(
                        profiles: cigaretteProfiles,
                        preferences: cigarettePreferences,
                        context: modelContext
                    )
                }
                await Task.yield()
                if let first = favoriteDrinks.first ?? activeDrinks.first {
                    select(first)
                }
                selectedCigaretteProfileID = activeCigaretteProfiles.first?.id
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
                        ForEach(favoriteDrinks) { drink in
                            Button {
                                select(drink)
                            } label: {
                                Label(drink.name, systemImage: drink.category.symbol)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(
                                selectedDrinkID == drink.id
                                    ? CXTheme.caffeineAccent
                                    : Color.secondary
                            )
                            .accessibilityHint("\(Int(drink.caffeineMG)) milligrams")
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } header: {
                Text("Favorites")
            } footer: {
                if favoriteDrinks.isEmpty {
                    Text("Mark drinks as favorites in My Drinks to place them here.")
                }
            }

            Section {
                Picker("Saved drink", selection: $selectedDrinkID) {
                    Text("Custom entry")
                        .tag(UUID?.none)
                    ForEach(activeDrinks) { drink in
                        Label(drink.name, systemImage: drink.category.symbol)
                            .tag(Optional(drink.id))
                    }
                }
                .onChange(of: selectedDrinkID) { _, identifier in
                    guard let identifier,
                          let drink = activeDrinks.first(where: { $0.id == identifier }) else {
                        return
                    }
                    caffeineName = drink.name
                    caffeineMG = drink.caffeineMG
                }

                NavigationLink {
                    MyDrinksView()
                } label: {
                    Label("Manage My Drinks", systemImage: "slider.horizontal.3")
                }
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

            if nicotineProduct == .cigarette {
                Section("Cigarette Intelligence") {
                    Picker("Saved cigarette", selection: $selectedCigaretteProfileID) {
                        Text("Unspecified").tag(UUID?.none)
                        ForEach(activeCigaretteProfiles) { profile in
                            Text(profile.name).tag(Optional(profile.id))
                        }
                    }

                    Picker("Context", selection: $cigaretteContext) {
                        Text("Not set").tag(CigaretteContext?.none)
                        ForEach(CigaretteContext.allCases) { item in
                            Label(item.title, systemImage: item.symbol)
                                .tag(Optional(item))
                        }
                    }

                    NavigationLink {
                        MyCigarettesView()
                    } label: {
                        Label("Manage My Cigarettes", systemImage: "slider.horizontal.3")
                    }
                }
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
                    drinkID: matchedDrinkID,
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
                    note: nicotineNote,
                    cigaretteProfileID: nicotineProduct == .cigarette ? selectedCigaretteProfileID : nil,
                    cigaretteContext: nicotineProduct == .cigarette ? cigaretteContext : nil
                )
            )
        }

        if didSave {
            dismiss()
        }
    }

    private var activeDrinks: [Drink] {
        drinks
            .filter {
                !(DrinkLibrary.existingDetails(
                    for: $0,
                    in: drinkDetails
                )?.isArchived ?? false)
            }
            .sorted {
                if $0.isFavorite != $1.isFavorite {
                    return $0.isFavorite && !$1.isFavorite
                }
                let lhsDetails = DrinkLibrary.existingDetails(
                    for: $0,
                    in: drinkDetails
                )
                let rhsDetails = DrinkLibrary.existingDetails(
                    for: $1,
                    in: drinkDetails
                )
                if $0.isFavorite,
                   lhsDetails?.favoriteOrder != rhsDetails?.favoriteOrder {
                    return (lhsDetails?.favoriteOrder ?? .max)
                        < (rhsDetails?.favoriteOrder ?? .max)
                }
                if lhsDetails?.lastUsedAt != rhsDetails?.lastUsedAt {
                    return (lhsDetails?.lastUsedAt ?? .distantPast)
                        > (rhsDetails?.lastUsedAt ?? .distantPast)
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var favoriteDrinks: [Drink] {
        activeDrinks.filter(\.isFavorite)
    }

    private var activeCigaretteProfiles: [CigaretteProfile] {
        cigaretteProfiles
            .filter { !$0.isArchived }
            .sorted {
                if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
                if $0.favoriteOrder != $1.favoriteOrder {
                    return ($0.favoriteOrder ?? .max) < ($1.favoriteOrder ?? .max)
                }
                return ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast)
            }
    }

    private var matchedDrinkID: UUID? {
        guard let selectedDrinkID,
              let drink = activeDrinks.first(where: { $0.id == selectedDrinkID }),
              drink.name == caffeineName,
              abs(drink.caffeineMG - caffeineMG) < 0.01 else {
            return nil
        }
        return selectedDrinkID
    }

    private func select(_ drink: Drink) {
        selectedDrinkID = drink.id
        caffeineName = drink.name
        caffeineMG = drink.caffeineMG
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
