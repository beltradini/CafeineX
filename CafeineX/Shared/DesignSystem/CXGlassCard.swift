//
//  CXGlassCard.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

struct CXGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

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
                            .stroke(
                                colorScheme == .dark
                                    ? .white.opacity(0.16)
                                    : .white.opacity(0.72),
                                lineWidth: 1
                            )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.22 : 0.09),
                radius: 24,
                x: 0,
                y: 14
            )
            .modifier(CXLiquidGlassModifier(cornerRadius: cornerRadius))
    }
}
