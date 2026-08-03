//
//  CXMetricTile.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

struct CXMetricTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            tint.opacity(0.08),
            in: RoundedRectangle(cornerRadius: CXTheme.smallCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CXTheme.smallCornerRadius, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        }
    }
}
