import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppearanceStore.self) private var appearanceStore

    var body: some View {
        @Bindable var appearanceStore = appearanceStore

        Form {
            Section {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        appearanceStore.setSelection(appearance)
                    } label: {
                        HStack {
                            Label(appearance.title, systemImage: appearance.symbol)
                                .foregroundStyle(.primary)
                            Spacer()
                            if appearanceStore.selection == appearance {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(CXTheme.caffeineAccent)
                            }
                        }
                    }
                    .accessibilityValue(
                        appearanceStore.selection == appearance ? "Selected" : ""
                    )
                }
            } footer: {
                Text("System follows the appearance selected for your device. Liquid Glass and CafeineX backgrounds adapt automatically.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
