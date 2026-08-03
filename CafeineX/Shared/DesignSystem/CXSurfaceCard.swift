//
//  CXSurfaceCard.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

/// A calm content-layer surface. Liquid Glass is intentionally reserved for
/// navigation and important interactive controls supplied by the system.
struct CXSurfaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private let content: Content
    private let cornerRadius: CGFloat
    private let contentPadding: EdgeInsets

    init(
        cornerRadius: CGFloat = CXTheme.cornerRadius,
        contentPadding: EdgeInsets = CXTheme.cardInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                borderColor,
                                lineWidth: 1
                            )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.14 : 0.07),
                radius: 12,
                x: 0,
                y: 6
            )
    }

    private var borderColor: Color {
        if colorSchemeContrast == .increased {
            return colorScheme == .dark
                ? .white.opacity(0.34)
                : .black.opacity(0.2)
        }
        return colorScheme == .dark
            ? .white.opacity(0.1)
            : .black.opacity(0.07)
    }
}
