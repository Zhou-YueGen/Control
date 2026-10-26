import XCTest

/// 主页日期条和 Weekly Progress 可以点击：查看某天的记录，或跳到 Progress。
final class HomeInteractionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-UITestFastTraining", "-UITestOnboardingDone"]
        app.launch()
        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 5))
    }

    private var todayInStrip: XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'homeDay-' AND label CONTAINS ', today'")).firstMatch
    }

    private var summary: XCUIElement { app.descendants(matching: .any)["dayDetailSummary"] }

    private func closeSheet() {
        app.buttons["dayDetailDoneButton"].tap()
        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testEveryDateOpensDayDetail() throws {
        for index in 0..<7 {
            app.buttons["homeDay-\(index)"].tap()
            XCTAssertTrue(summary.waitForExistence(timeout: 3), "Day \(index) did not open")
            XCTAssertTrue(summary.label.hasPrefix("0 sessions"))
            XCTAssertTrue(app.descendants(matching: .any)["dayDetailEmpty"].exists)
            closeSheet()
        }
    }

    @MainActor
    func testWeeklyDotsOpenDayDetail() throws {
        for index in 0..<7 {
            app.buttons["weeklyDot-\(index)"].tap()
            XCTAssertTrue(summary.waitForExistence(timeout: 3), "Dot \(index) did not open")
            closeSheet()
        }
    }

    @MainActor
    func testWeeklyProgressHeaderOpensProgress() throws {
        app.buttons["weeklyProgressHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["progressSessionsMetric"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testTodayShowsCompletedSessionAndLinksToProgress() throws {
        app.buttons["startTrainingButton"].firstMatch.tap()
        let primary = app.buttons["trainingPrimaryControl"]
        XCTAssertTrue(primary.waitForExistence(timeout: 5))
        primary.tap()
        XCTAssertTrue(app.staticTexts["Great job!"].waitForExistence(timeout: 25))
        app.buttons["Comfortable"].tap()
        app.buttons["saveAndContinueButton"].tap()
        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 5))

        todayInStrip.tap()
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        XCTAssertTrue(summary.label.hasPrefix("1 session"))
        XCTAssertTrue(app.descendants(matching: .any)["dayDetailSessionRow"].exists)

        app.buttons["dayDetailProgressButton"].tap()
        let sessions = app.descendants(matching: .any)["progressSessionsMetric"]
        XCTAssertTrue(sessions.waitForExistence(timeout: 3))
        XCTAssertEqual(sessions.value as? String, "1")
    }
}
