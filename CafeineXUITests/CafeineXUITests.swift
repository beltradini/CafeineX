//
//  CafeineXUITests.swift
//  CafeineXUITests
//
//  Created by Alejandro Beltrán on 5/24/26.
//

import XCTest

final class CafeineXUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testPrimaryNavigationAndLandscapeLayout() throws {
        let app = XCUIApplication()
        app.launch()

        let home = navigationButton(named: "Home", in: app)
        let history = navigationButton(named: "History", in: app)
        let profile = navigationButton(named: "Profile", in: app)
        let search = navigationButton(named: "Search", in: app)

        XCTAssertTrue(home.waitForExistence(timeout: 5))
        XCTAssertTrue(history.waitForExistence(timeout: 3))
        XCTAssertTrue(profile.waitForExistence(timeout: 3))
        XCTAssertTrue(search.waitForExistence(timeout: 3))

        history.tap()
        let historyFilters = app.staticTexts["Filters"]
        XCTAssertTrue(historyFilters.waitForExistence(timeout: 3))

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(historyFilters.waitForExistence(timeout: 3))
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    private func navigationButton(
        named name: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let tabBarButton = app.tabBars.buttons[name]
        if tabBarButton.waitForExistence(timeout: 1) {
            return tabBarButton
        }

        return app.buttons[name].firstMatch
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
