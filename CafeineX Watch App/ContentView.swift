//
//  ContentView.swift
//  CafeineX Watch App
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BeverageTypeModel.self, configurations: config)

        return ContentView()
            .modelContainer(container)
    } catch {
        fatalError("Failed to create model container for preview: \\(error)")
    }
}
