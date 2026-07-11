//
//  CXBackgroundView.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

struct CXBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CXTheme.backgroundTop,
                    CXTheme.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(CXTheme.caffeineAccent.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -120, y: -220)

            Circle()
                .fill(CXTheme.healthAccent.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 140, y: 260)
        }
    }
}
