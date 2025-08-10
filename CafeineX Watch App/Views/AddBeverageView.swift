//
//  AddBeverageView.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/20/25.
//

import SwiftUI
import SwiftData

struct AddBeverageView: View {
    @ObservedObject var catalogViewModel: BeverageCatalogViewModel
    var onAdd: (BeverageTypeModel) -> Void
    var onCancel: () -> Void

    @State private var showCustomForm = false
    @State private var customName: String = ""
    @State private var customCaffeine: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Favorites")
                    .font(.headline)
                    .padding(.leading)
                if catalogViewModel.favoriteBeverages.isEmpty {
                    Text("No favorites yet")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                } else {
                    ForEach(catalogViewModel.favoriteBeverages, id: \.id) { beverage in
                        Button {
                            onAdd(beverage)
                        } label: {
                            HStack {
                                Text(beverage.name)
                                    .font(.body)
                                Spacer()
                                Text("\(Int(beverage.caffeineMg)) mg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                Text("All Drinks")
                    .font(.headline)
                    .padding(.leading)
                ForEach(catalogViewModel.allBeverages, id: \.id) { beverage in
                    Button {
                        onAdd(beverage)
                    } label: {
                        HStack {
                            Text(beverage.name)
                                .font(.body)
                            Spacer()
                            Text("\(Int(beverage.caffeineMg)) mg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if beverage.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                Button(action: { showCustomForm = true }) {
                    Label("Add Custom Drink", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical)
        }
        .navigationTitle("Add Drink")
        .sheet(isPresented: $showCustomForm) {
            CustomBeverageForm(
                name: $customName,
                caffeine: $customCaffeine,
                onSave: {
                    if let caffeineMg = Double(customCaffeine), !customName.isEmpty {
                        catalogViewModel.addBeverage(name: customName, caffeineMg: caffeineMg)
                        if let newBeverage = catalogViewModel.allBeverages.first(where: { $0.name == customName && $0.caffeineMg == caffeineMg }) {
                            onAdd(newBeverage)
                        }
                    }
                    customName = ""
                    customCaffeine = ""
                    showCustomForm = false
                },
                onCancel: {
                    showCustomForm = false
                }
            )
        }
    }
}

struct CustomBeverageForm: View {
    @Binding var name: String
    @Binding var caffeine: String
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Custom Drink")
                .font(.title2.bold())
            TextField("Name", text: $name)
            TextField("Caffeine (mg)", text: $caffeine)
            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Add", action: onSave)
                    .disabled(name.isEmpty || Double(caffeine) == nil)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

#Preview("Custom Beverage Form") {
    CustomBeverageForm(
        name: .constant("Coffee"),
        caffeine: .constant("95"),
        onSave: {},
        onCancel: {}
    )
}
