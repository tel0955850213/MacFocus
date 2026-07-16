import XCTest

final class FocusArcanaSmokeUITests: XCTestCase {
    func testTimerAndPrimaryTabsAreInteractive() {
        let app = XCUIApplication()
        app.launchArguments += ["-macfocus.onboarded", "true", "-AppleLanguages", "(en)"]
        app.launch()

        let start = app.buttons["Start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        let pause = app.buttons["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 2))
        pause.tap()
        XCTAssertTrue(start.waitForExistence(timeout: 2))

        app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.staticTexts["Hero Collection"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Summon"].tap()
        XCTAssertTrue(app.staticTexts["Gate of Summoning"].waitForExistence(timeout: 3))

        app.buttons["debug-grant-coins"].tap()
        let balance = app.staticTexts["coin-balance"]
        XCTAssertTrue(balance.waitForExistence(timeout: 2))
        let balanceBeforeDraw = coinValue(from: balance.label)

        let card = app.buttons.matching(identifier: "summon-card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.2,
                   thenDragTo: card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.35)),
                   withVelocity: .slow,
                   thenHoldForDuration: 0.1)

        let collect = app.buttons["Collect"]
        XCTAssertTrue(collect.waitForExistence(timeout: 5))
        collect.tap()
        XCTAssertTrue(balance.waitForExistence(timeout: 3))
        let balanceAfterDraw = coinValue(from: balance.label)
        XCTAssertTrue(balanceAfterDraw == balanceBeforeDraw - 100 ||
                      balanceAfterDraw == balanceBeforeDraw - 50,
                      "A new draw costs 100 coins; a duplicate refunds 50 coins")
    }

    private func coinValue(from label: String) -> Int {
        Int(label.filter(\.isNumber)) ?? -1
    }
}
