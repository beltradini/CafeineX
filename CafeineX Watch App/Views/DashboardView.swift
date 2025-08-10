//
//  DashboardView.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/29/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var catalogViewModel: BeverageCatalogViewModel
    @State private var showAddDrink = false

    var progress: Double {
        min(viewModel.dailyTotal / viewModel.dailyLimit, 1.0)
    }

    var body: some View {
        ZStack {
            // Fondo dinámico con gradiente
            LinearGradient(
                colors: [Color.black, Color.blue.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Header con logo o ícono
                HStack {
                    Image(systemName: "bolt.capsule.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.accentColor)
                    Spacer()
                    Text("CafeineX")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal)

                // Progreso visual animado
                ZStack {
                    Circle()
                        .stroke(lineWidth: 14)
                        .opacity(0.16)
                        .foregroundStyle(.thinMaterial)
                        .frame(width: 110, height: 110)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress < 1
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.red),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                        .frame(width: 110, height: 110)

                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.dailyTotal)) mg")
                            .font(.title.bold())
                            .foregroundColor(progress < 1 ? .primary : .red)
                        Text("of \(Int(viewModel.dailyLimit)) mg")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 2)

                // Mensaje si supera el límite
                if progress >= 1 {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Limit exceeded!")
                            .font(.footnote.bold())
                            .foregroundColor(.red)
                    }
                    .transition(.opacity.combined(with: .scale))
                }

                // Botón grande: Añadir bebida
                Button {
                    showAddDrink = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Drink")
                            .font(.headline)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("AddDrinkButton")
                .shadow(radius: 2, y: 2)

                Spacer(minLength: 0)
            }
            .padding(.top, 18)
            .padding(.horizontal, 8)
        }
        .sheet(isPresented: $showAddDrink) {
            AddBeverageView(
                catalogViewModel: catalogViewModel,
                onAdd: { beverage in
                    let entry = CaffeineEntry(beverageName: beverage.name, caffeineMg: beverage.caffeineMg)
                    Task {
                        await viewModel.addEntry(entry)
                        showAddDrink = false
                    }
                },
                onCancel: { showAddDrink = false }
            )
        }
        .navigationTitle("CafeineX")
    }
}

extension DashboardViewModel {
    static var mock: DashboardViewModel {
        DashboardViewModel(
            dataSource: MockHealthKitService() as CaffeineDataSourceProtocol,
            syncService: MockCaffeineSyncService(),
            healthKitService: MockHealthKitService(),
            dataRepository: MockCaffeineDataRepository()
        )
    }
}

#Preview {
    DashboardView(viewModel: .mock)
        .environmentObject(BeverageCatalogViewModel(service: MockBeverageService()))
}
