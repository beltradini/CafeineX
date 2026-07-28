import Foundation
import SwiftData

@Model
final class NicotineEntry {
    var id: UUID
    var productRawValue: String
    var quantity: Double
    var unitRawValue: String
    var usedAt: Date
    var sourceRawValue: String
    var note: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        product: NicotineProduct,
        quantity: Double,
        unit: NicotineUnit,
        usedAt: Date = .now,
        source: NicotineSource = .manual,
        note: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.productRawValue = product.rawValue
        self.quantity = quantity
        self.unitRawValue = unit.rawValue
        self.usedAt = usedAt
        self.sourceRawValue = source.rawValue
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.createdAt = createdAt
    }

    var product: NicotineProduct {
        NicotineProduct(rawValue: productRawValue) ?? .other
    }

    var unit: NicotineUnit {
        NicotineUnit(rawValue: unitRawValue) ?? product.defaultUnit
    }

    var source: NicotineSource {
        NicotineSource(rawValue: sourceRawValue) ?? .manual
    }

    var event: NicotineEvent {
        NicotineEvent(
            id: id,
            product: product,
            quantity: quantity,
            unit: unit,
            usedAt: usedAt
        )
    }
}

nonisolated enum NicotineProduct: String, Codable, CaseIterable, Identifiable, Sendable {
    case cigarette
    case cigar
    case vape
    case pouch
    case gum
    case lozenge
    case patch
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .cigarette: "Cigarette"
        case .cigar: "Cigar"
        case .vape: "Vape"
        case .pouch: "Nicotine pouch"
        case .gum: "Nicotine gum"
        case .lozenge: "Lozenge"
        case .patch: "Patch"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .cigarette, .cigar: "smoke.fill"
        case .vape: "wind"
        case .pouch: "square.stack.3d.up.fill"
        case .gum: "circle.grid.2x2.fill"
        case .lozenge: "pills.fill"
        case .patch: "cross.case.fill"
        case .other: "leaf.fill"
        }
    }

    var defaultUnit: NicotineUnit {
        switch self {
        case .cigarette, .cigar:
            .pieces
        case .vape:
            .puffs
        case .pouch, .gum, .lozenge, .patch:
            .milligrams
        case .other:
            .pieces
        }
    }

    var allowedUnits: [NicotineUnit] {
        switch self {
        case .cigarette, .cigar:
            [.pieces]
        case .vape:
            [.puffs, .milligrams]
        case .pouch, .gum, .lozenge, .patch:
            [.milligrams, .pieces]
        case .other:
            NicotineUnit.allCases
        }
    }
}

nonisolated enum NicotineUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case milligrams
    case pieces
    case puffs

    var id: Self { self }

    var title: String {
        switch self {
        case .milligrams: "Milligrams"
        case .pieces: "Uses"
        case .puffs: "Puffs"
        }
    }

    var shortLabel: String {
        switch self {
        case .milligrams: "mg"
        case .pieces: "uses"
        case .puffs: "puffs"
        }
    }

    func formatted(quantity: Double) -> String {
        "\(quantity.formatted(.number.precision(.fractionLength(0...1)))) \(shortLabel)"
    }
}

nonisolated enum NicotineSource: String, Codable, CaseIterable, Sendable {
    case manual
    case appleWatch
    case siri
    case widget
}

nonisolated struct NicotineEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let product: NicotineProduct
    let quantity: Double
    let unit: NicotineUnit
    let usedAt: Date
}

private extension String {
    nonisolated var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
