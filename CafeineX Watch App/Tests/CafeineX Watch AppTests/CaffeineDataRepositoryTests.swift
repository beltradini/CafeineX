//
//  CaffeineDataRepositoryTests.swift
//  CafeineX
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import XCTest
import SwiftData
@testable import CafeineX_Watch_App

final class CaffeineDataRepositoryTests: XCTestCase {
    @MainActor
    func testAddAndFetchEntry() throws {
        let modelContainer = try ModelContainer(
            for: Schema([CaffeineEntryModel.self]),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let repository = CaffeineDataRepository(container: modelContainer)
        let entry = CaffeineEntry(beverageName: "Espresso", caffeineMg: 80)
        repository.addEntry(entry)
        let entries = repository.fetchEntries()
        XCTAssertTrue(entries.contains(where: { $0.id == entry.id }))
    }
}
