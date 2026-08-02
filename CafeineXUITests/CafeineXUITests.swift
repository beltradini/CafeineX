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
        let historyNavigationBar = app.navigationBars["History"]
        XCTAssertTrue(historyNavigationBar.waitForExistence(timeout: 3))

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(historyNavigationBar.waitForExistence(timeout: 3))
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testProfileOpensPersonalDrinkLibrary() throws {
        let app = XCUIApplication()
        app.launch()

        let profile = navigationButton(named: "Profile", in: app)
        XCTAssertTrue(profile.waitForExistence(timeout: 5))
        profile.tap()

        XCTAssertTrue(app.staticTexts["Your Focus"].waitForExistence(timeout: 3))

        let myDrinks = app.staticTexts["My Drinks"].firstMatch
        if !myDrinks.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        if !myDrinks.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(myDrinks.waitForExistence(timeout: 3))
        myDrinks.tap()

        XCTAssertTrue(app.navigationBars["My Drinks"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["New Drink"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Archived Drinks"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomePresentsOptionalSleepContext() throws {
        let app = XCUIApplication()
        app.launch()

        let sleepContext = app.otherElements["health-insights-card"]
        if !sleepContext.waitForExistence(timeout: 2) {
            app.swipeUp()
        }

        XCTAssertTrue(sleepContext.waitForExistence(timeout: 3))

        let chooseAccess = app.buttons["choose-sleep-access-button"]
        if chooseAccess.exists {
            XCTAssertTrue(chooseAccess.isHittable)
        }
    }

    @MainActor
    func testCigaretteIntelligenceLogsAndUndoesOneEvent() throws {
        let app = XCUIApplication()
        app.launch()

        let card = app.otherElements["cigarette-intelligence-card"]
        for _ in 0..<4 where !card.exists {
            app.swipeUp()
        }
        XCTAssertTrue(card.waitForExistence(timeout: 3))

        let logButton = app.buttons["Log One Cigarette"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 3))
        logButton.tap()

        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        undo.tap()
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
