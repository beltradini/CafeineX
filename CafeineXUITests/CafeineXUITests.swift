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
        let app = makeApp()
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
        let app = makeApp()
        app.launch()

        let profile = navigationButton(named: "Profile", in: app)
        XCTAssertTrue(profile.waitForExistence(timeout: 5))
        profile.tap()

        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 8))

        let myDrinks = app.descendants(matching: .any)["profile-my-drinks-link"].firstMatch
        try scrollToHittable(myDrinks, in: app.collectionViews.firstMatch)
        myDrinks.tap()

        XCTAssertTrue(app.navigationBars["My Drinks"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["New Drink"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Archived Drinks"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomePresentsOptionalSleepContext() throws {
        let app = makeApp()
        app.launch()

        let sleepContext = app.descendants(matching: .any)["health-insights-card"].firstMatch
        XCTAssertTrue(sleepContext.waitForExistence(timeout: 3))

        let chooseAccess = app.descendants(matching: .any)["choose-sleep-access-button"].firstMatch
        if chooseAccess.exists {
            try scrollToHittable(chooseAccess, in: app.scrollViews.firstMatch)
        }
    }

    @MainActor
    func testQuickAddOpensWithoutMissingPersistenceEnvironmentCrash() throws {
        let app = makeApp()
        app.launch()

        let quickAdd = app.buttons["Quick Add"].firstMatch
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 8))
        quickAdd.tap()

        XCTAssertTrue(app.navigationBars["Add exposure"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Customize caffeine"].exists)
    }

    @MainActor
    func testWelcomeOnboardingCanBeCompleted() throws {
        let app = makeApp()
        app.launchArguments.append("-show-onboarding")
        app.launchArguments.append("-show-whats-new")
        app.launch()

        XCTAssertTrue(app.staticTexts["Understand the timing of your stimulants"].waitForExistence(timeout: 8))

        for _ in 0..<4 {
            app.buttons["onboarding-primary-action"].tap()
        }

        XCTAssertTrue(app.staticTexts["Your next moment starts here"].waitForExistence(timeout: 3))
        app.buttons["onboarding-primary-action"].tap()
        XCTAssertTrue(app.staticTexts["A clearer way to notice your day"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Sleep stages timeline"].exists)
        XCTAssertTrue(app.staticTexts["Quick Add"].exists)
        XCTAssertTrue(app.staticTexts["Cigarette intelligence"].exists)
        XCTAssertTrue(app.staticTexts["Local privacy"].exists)
        XCTAssertTrue(app.staticTexts["Apple Health integration"].exists)
        app.buttons["whats-new-continue-button"].tap()
        XCTAssertTrue(navigationButton(named: "Home", in: app).waitForExistence(timeout: 8))
    }

    @MainActor
    func testWhatsNewTourShowsPilotFeatures() throws {
        let app = makeApp()
        app.launchArguments.append("-show-whats-new")
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["whats-new-screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["whats-new-continue-button"].exists)
    }

    @MainActor
    func testEmptyHomeOffersFirstEntryActions() throws {
        let app = makeApp()
        app.launch()

        let emptyState = app.descendants(matching: .any)["home-empty-state-card"].firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["empty-state-log-caffeine-button"].exists)
        XCTAssertTrue(app.buttons["empty-state-log-nicotine-button"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["health-connection-card"].exists)
        XCTAssertTrue(app.staticTexts["Saved on this device"].exists)
        XCTAssertTrue(app.staticTexts["Health & sync status"].exists)
    }

    @MainActor
    func testCigaretteIntelligenceLogsAndUndoesOneEvent() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = makeApp()
        app.launch()

        let logButton = app.descendants(matching: .any)["cigarette-log-one-button"].firstMatch
        try scrollToHittable(logButton, in: app.scrollViews.firstMatch)
        logButton.tap()

        let undo = app.descendants(matching: .any)["undo-last-add-button"].firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        XCTAssertTrue(undo.isHittable)
        undo.tap()
        XCTAssertTrue(logButton.waitForExistence(timeout: 3))
    }

    @MainActor
    func testPrimarySurfacesPassAccessibilityAudit() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(navigationButton(named: "Home", in: app).waitForExistence(timeout: 8))
        try app.performAccessibilityAudit(for: primarySurfaceAuditTypes)

        let history = navigationButton(named: "History", in: app)
        XCTAssertTrue(history.waitForExistence(timeout: 3))
        history.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
        try app.performAccessibilityAudit(for: primarySurfaceAuditTypes)

        let search = navigationButton(named: "Search", in: app)
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 3))
        try app.performAccessibilityAudit(for: primarySurfaceAuditTypes)
    }

    private var primarySurfaceAuditTypes: XCUIAccessibilityAuditType {
        .all.subtracting([.contrast, .dynamicType, .hitRegion, .textClipped])
    }

    @MainActor
    private func scrollToHittable(
        _ element: XCUIElement,
        in scrollView: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        XCTAssertTrue(
            scrollView.waitForExistence(timeout: 5),
            "The expected scroll view is unavailable",
            file: file,
            line: line
        )

        for _ in 0..<10 where !element.isHittable {
            if element.exists, element.frame.midY < scrollView.frame.minY {
                scrollView.swipeDown(velocity: .slow)
            } else {
                scrollView.swipeUp(velocity: .slow)
            }
        }

        XCTAssertTrue(
            element.exists,
            "The accessibility identifier was not found",
            file: file,
            line: line
        )
        XCTAssertTrue(
            element.isHittable,
            "The identified control could not be brought on screen",
            file: file,
            line: line
        )
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
    private func makeApp() -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        return app
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments.append("-ui-testing")
            app.launch()
        }
    }
}
