//
//  CXBackgroundView.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

struct CXBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    backgroundTop,
                    backgroundBottom
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

    private var backgroundTop: Color {
        colorScheme == .dark
            ? CXTheme.backgroundTop
            : Color(red: 0.96, green: 0.95, blue: 0.93)
    }

    private var backgroundBottom: Color {
        colorScheme == .dark
            ? CXTheme.backgroundBottom
            : Color(red: 0.91, green: 0.94, blue: 0.94)
    }
}
