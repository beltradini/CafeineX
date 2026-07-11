//
//  CXMetricCard.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

struct CXMetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        CXGlassCard(cornerRadius: CXTheme.smallCornerRadius) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
