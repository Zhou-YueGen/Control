import XCTest

/// 在模拟器中真实点击：Home → Training → Session Complete → Home，以及暂停、退出、后台和不适锁定。
final class TrainingFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-UITestFastTraining", "-UITestOnboardingDone"]
        app.launch()
    }

    private var startButton: XCUIElement { app.buttons["startTrainingButton"].firstMatch }
    private var primaryControl: XCUIElement { app.buttons["trainingPrimaryControl"] }

    private func openTraining() {
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
    }

    private func completeSession() {
        openTraining()
        primaryControl.tap()
        XCTAssertTrue(app.staticTexts["Great job!"].waitForExistence(timeout: 25))
    }

    @MainActor
    func testCompletingSessionUpdatesHome() throws {
        XCTAssertEqual(app.staticTexts["weeklyProgressCount"].label, "0 / 7 days")
        completeSession()

        app.buttons["Comfortable"].tap()
        app.buttons["discomfort-No"].tap()
        app.buttons["saveAndContinueButton"].tap()

        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["weeklyProgressCount"].label, "1 / 7 days")
        XCTAssertTrue(app.staticTexts["Completed today"].exists)
    }

    @MainActor
    func testPauseResumeAndEndSessionIsNotCompleted() throws {
        openTraining()
        primaryControl.tap()
        XCTAssertEqual(primaryControl.label, "Pause")

        primaryControl.tap()
        XCTAssertEqual(primaryControl.label, "Resume")
        let pausedSubtitle = app.staticTexts["trainingSubtitle"].label
        sleep(3)
        XCTAssertEqual(app.staticTexts["trainingSubtitle"].label, pausedSubtitle)

        primaryControl.tap()
        XCTAssertEqual(primaryControl.label, "Pause")

        app.buttons["trainingBackButton"].tap()
        let alert = app.alerts["End session?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Continue training"].tap()
        XCTAssertEqual(primaryControl.label, "Resume")

        app.buttons["trainingBackButton"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["End session"].tap()

        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["weeklyProgressCount"].label, "0 / 7 days")
    }

    @MainActor
    func testGoingToBackgroundPausesAndStaysPaused() throws {
        openTraining()
        primaryControl.tap()
        XCTAssertEqual(primaryControl.label, "Pause")

        XCUIDevice.shared.press(.home)
        sleep(12)
        app.activate()

        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
        XCTAssertEqual(primaryControl.label, "Resume")
        XCTAssertFalse(app.staticTexts["Great job!"].exists)
    }

    @MainActor
    func testReportingDiscomfortLocksTraining() throws {
        completeSession()
        app.buttons["discomfort-Yes"].tap()
        XCTAssertTrue(app.staticTexts["Please stop training for now"].waitForExistence(timeout: 3))
        app.buttons["saveAndContinueButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["trainingBlockedReason"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(startButton.exists)
    }

    @MainActor
    func testTabBarSwitchesPages() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        for name in ["Home", "Learn", "Train", "Progress", "Settings"] {
            XCTAssertTrue(tabBar.buttons[name].exists, "Missing tab \(name)")
        }

        tabBar.buttons["Train"].tap()
        XCTAssertTrue(app.staticTexts["Session details"].waitForExistence(timeout: 3))
        startButton.tap()
        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
        app.buttons["trainingBackButton"].tap()

        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 5))
        tabBar.buttons["Learn"].tap()
        XCTAssertFalse(app.staticTexts["weeklyProgressCount"].exists)
        XCTAssertFalse(startButton.exists)

        tabBar.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testBackFromReadyReturnsHome() throws {
        openTraining()
        app.buttons["trainingBackButton"].tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
    }
}
