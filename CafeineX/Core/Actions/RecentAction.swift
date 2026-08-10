//
//  RecentAction.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 8/10/26.
//

import Foundation

enum RecentActionKind: String, Codable, Sendable {
    case logged
    case loggedAgain
    case undone
    case edited
    case synced

    var titlePrefix: String {
        switch self {
        case .logged: return "Logged"
        case .loggedAgain: return "Logged Again"
        case .undone: return "Undone"
        case .edited: return "Edited"
        case .synced: return "Synced"
        }
    }

    var symbolName: String {
        switch self {
        case .logged:
            "plus.circle.fill"
        case .loggedAgain:
            "arrow.clockwise.circle.fill"
        case .undone:
            "arrow.uturn.backward.circle.fill"
        case .edited:
            "pencil.circle.fill"
        case .synced:
            "arrow.triangle.2.circlepath.circle.fill"
        }
    }
}

struct RecentAction: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: RecentActionKind
    let title: String
    let detail: String?
    let occurredAt: Date
    let relatedEntryID: UUID?

    init(
        id: UUID = UUID(),
        kind: RecentActionKind,
        title: String,
        detail: String? = nil,
        occurredAt: Date = .now,
        relatedEntryID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.occurredAt = occurredAt
        self.relatedEntryID = relatedEntryID
    }
}
