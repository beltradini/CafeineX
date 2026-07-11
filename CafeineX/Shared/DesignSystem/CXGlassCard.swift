//
//  CXGlassCard.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

struct CXGlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat

    init(
        cornerRadius: CGFloat = CXTheme.cornerRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 14)
            .modifier(CXLiquidGlassModifier(cornerRadius: cornerRadius))
    }
}
