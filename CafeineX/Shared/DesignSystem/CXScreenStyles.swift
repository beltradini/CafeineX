import SwiftUI

extension View {
    /// Applies CafeineX's ambient content background while preserving native
    /// List and Form behavior, including accessibility material fallbacks.
    func cxContentBackground() -> some View {
        scrollContentBackground(.hidden)
            .background {
                CXBackgroundView()
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
    }

    /// Keeps root scrolling content reachable above the floating tab/search bar.
    func cxRootScrollInsets() -> some View {
        contentMargins(.bottom, CXTheme.bottomContentInset, for: .scrollContent)
    }
}
