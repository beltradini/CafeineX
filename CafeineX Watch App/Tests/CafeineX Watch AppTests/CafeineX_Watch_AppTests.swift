//
//  CafeineX_Watch_AppTests.swift
//  CafeineX Watch AppTests
//
//  Created by Alejandro Beltrán on 7/9/25.
//

import XCTest
import SwiftData
@testable import CafeineX_Watch_App

// MARK: - Beverage Catalog Service

@MainActor
final class BeverageCatalogServiceTests: XCTestCase {
    var testContainer: ModelContainer!
    var service: BeverageCatalogService!
    
    override func setUp() {
        testContainer = try! ModelContainer(
            for: BeverageTypeModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        service = BeverageCatalogService(container: testContainer)
    }
    
    override func tearDown() {
        testContainer = nil
        service = nil
        super.tearDown()
    }
}
