import Foundation

enum ExposureKind: String, CaseIterable, Identifiable {
    case caffeine
    case nicotine

    var id: Self { self }

    var title: String {
        switch self {
        case .caffeine: "Caffeine"
        case .nicotine: "Nicotine"
        }
    }
}

enum ExposureItem: Identifiable {
    case caffeine(CaffeineEntry)
    case nicotine(NicotineEntry)

    var id: String {
        "\(kind.rawValue)-\(modelID.uuidString)"
    }

    var modelID: UUID {
        switch self {
        case .caffeine(let entry): entry.id
        case .nicotine(let entry): entry.id
        }
    }

    var kind: ExposureKind {
        switch self {
        case .caffeine: .caffeine
        case .nicotine: .nicotine
        }
    }

    var date: Date {
        switch self {
        case .caffeine(let entry): entry.consumedAt
        case .nicotine(let entry): entry.usedAt
        }
    }

    var title: String {
        switch self {
        case .caffeine(let entry): entry.drinkName
        case .nicotine(let entry): entry.product.title
        }
    }

    var amountText: String {
        switch self {
        case .caffeine(let entry):
            "\(Int(entry.caffeineMG.rounded())) mg"
        case .nicotine(let entry):
            entry.unit.formatted(quantity: entry.quantity)
        }
    }

    var symbol: String {
        switch self {
        case .caffeine(let entry):
            Self.caffeineSymbol(for: entry.drinkName)
        case .nicotine(let entry):
            entry.product.symbol
        }
    }

    var sourceTitle: String {
        switch self {
        case .caffeine(let entry):
            switch entry.source {
            case .manual: "Manual"
            case .appleWatch: "Apple Watch"
            case .siri: "Siri"
            case .widget: "Widget"
            case .healthKit: "Apple Health"
            }
        case .nicotine(let entry):
            switch entry.source {
            case .manual: "Manual"
            case .appleWatch: "Apple Watch"
            case .siri: "Siri"
            case .widget: "Widget"
            }
        }
    }

    var note: String? {
        guard case .nicotine(let entry) = self else { return nil }
        return entry.note
    }

    var isHealthKit: Bool {
        guard case .caffeine(let entry) = self else { return false }
        return entry.source == .healthKit
    }

    var isHealthLinked: Bool {
        guard case .caffeine(let entry) = self else { return false }
        return entry.source == .healthKit || entry.healthKitUUID != nil
    }

    var canModify: Bool {
        !isHealthLinked
    }

    var searchableText: String {
        [
            title,
            kind.title,
            sourceTitle,
            amountText,
            note,
            date.formatted(date: .abbreviated, time: .shortened),
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    var accessibilityLabel: String {
        "\(kind.title), \(title), \(amountText), \(date.formatted(date: .abbreviated, time: .shortened)), \(sourceTitle)"
    }

    static func combined(
        caffeineEntries: [CaffeineEntry],
        nicotineEntries: [NicotineEntry]
    ) -> [ExposureItem] {
        (
            caffeineEntries.map(ExposureItem.caffeine)
                + nicotineEntries.map(ExposureItem.nicotine)
        )
        .sorted { $0.date > $1.date }
    }

    private static func caffeineSymbol(for drinkName: String) -> String {
        let name = drinkName.lowercased()

        if name.contains("espresso") {
            return "cup.and.saucer.fill"
        }
        if name.contains("americano") {
            return "mug.fill"
        }
        if name.contains("latte") {
            return "takeoutbag.and.cup.and.straw.fill"
        }
        if name.contains("cold") {
            return "snowflake"
        }
        return "cup.and.saucer"
    }
}

struct ExposureSearchEngine {
    func results(
        in items: [ExposureItem],
        query: String,
        kind: ExposureKind? = nil
    ) -> [ExposureItem] {
        let terms = query
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        return items.filter { item in
            guard kind == nil || item.kind == kind else { return false }
            guard !terms.isEmpty else { return true }

            let haystack = item.searchableText.folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: .current
            )
            return terms.allSatisfy(haystack.contains)
        }
    }
}
