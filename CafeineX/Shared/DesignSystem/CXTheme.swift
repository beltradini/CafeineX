//
//  CXTheme.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import SwiftUI

enum CXTheme {
    static let cornerRadius: CGFloat = 22
    static let smallCornerRadius: CGFloat = 16
    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let rowSpacing: CGFloat = 14
    static let horizontalPadding: CGFloat = 20
    static let bottomContentInset: CGFloat = 112
    static let screenMaxWidth: CGFloat = 900

    static let cardInsets = EdgeInsets(
        top: 18,
        leading: 18,
        bottom: 18,
        trailing: 18
    )

    static let caffeineAccent = Color(red: 0.95, green: 0.58, blue: 0.22)
    static let nicotineAccent = Color(red: 0.58, green: 0.48, blue: 0.98)
    static let healthAccent = Color(red: 0.34, green: 0.86, blue: 0.54)
    static let warningAccent = Color(red: 1.00, green: 0.37, blue: 0.28)

    static let backgroundTop = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let backgroundBottom = Color(red: 0.01, green: 0.02, blue: 0.03)
}
