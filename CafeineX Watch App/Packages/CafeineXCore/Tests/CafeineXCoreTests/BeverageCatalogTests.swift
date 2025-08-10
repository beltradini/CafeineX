import XCTest
@testable import CafeineXCore

final class BeverageCatalogTests: XCTestCase {
    func testLoadDefaultsReturnsItems() throws {
        let catalog = BeverageCatalog()
        let items = try catalog.loadDefaults()
        XCTAssertFalse(items.isEmpty)
        XCTAssertTrue(items.contains { $0.name.lowercased().contains("espresso") })
    }
}
