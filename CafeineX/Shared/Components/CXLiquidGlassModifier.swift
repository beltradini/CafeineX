//
//  CXLiquidGlassModifier.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

struct CXLiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, watchOS 26.0, *) {
            content
                .glassEffect(
                    .regular,
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
        }
    }
}
