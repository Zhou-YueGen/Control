import XCTest

/// 首次引导：Welcome → Goal → Safety Check → Learn Basics / Safety Notice → Home。
final class OnboardingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-UITestFreshInstall"]
        app.launch()
    }

    private func tapScrolling(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(element)", file: file, line: line)
        var attempts = 0
        while !element.isHittable && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
        element.tap()
    }

    private func passWelcomeAndGoal(goal: String = "improveControl") {
        tapScrolling(app.buttons["getStartedButton"])
        let continueButton = app.buttons["goalContinueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertFalse(continueButton.isEnabled)
        tapScrolling(app.buttons["goal-\(goal)"])
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
    }

    private func answerSafety(age: String = "Yes", risk: [String: String] = [:]) {
        let continueButton = app.buttons["safetyContinueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        tapScrolling(app.buttons["safety-age-\(age)"])
        for id in ["pain", "urination", "surgery", "condition"] {
            XCTAssertFalse(continueButton.isEnabled)
            tapScrolling(app.buttons["safety-\(id)-\(risk[id] ?? "No")"])
        }
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
    }

    private func readBasics() {
        let done = app.buttons["basicsDoneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        for id in ["where", "contract", "breathe", "support"] {
            XCTAssertFalse(done.isEnabled)
            tapScrolling(app.buttons["basics-\(id)"])
        }
        XCTAssertTrue(done.isEnabled)
        done.tap()
    }

    private var homeLoaded: Bool {
        app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 5)
    }

    @MainActor
    func testHappyPathUnlocksTraining() throws {
        passWelcomeAndGoal()
        answerSafety()
        readBasics()

        XCTAssertTrue(homeLoaded)
        XCTAssertTrue(app.buttons["startTrainingButton"].firstMatch.exists)
        XCTAssertFalse(app.descendants(matching: .any)["trainingBlockedReason"].firstMatch.exists)
    }

    @MainActor
    func testRiskAnswerLeadsToEducationOnlyHome() throws {
        passWelcomeAndGoal()
        answerSafety(risk: ["pain": "Yes"])

        XCTAssertTrue(app.descendants(matching: .any)["onboardingSafetyNotice"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["basicsDoneButton"].exists)
        app.buttons["safetyNoticeAcknowledgeButton"].tap()

        XCTAssertTrue(homeLoaded)
        XCTAssertFalse(app.buttons["startTrainingButton"].firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["trainingBlockedReason"].firstMatch.exists)
    }

    @MainActor
    func testPreferNotToSayAndRecoveryGoalAreEducationOnly() throws {
        passWelcomeAndGoal(goal: "recoveryInformation")
        answerSafety()
        XCTAssertTrue(app.descendants(matching: .any)["onboardingSafetyNotice"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testBackNavigationKeepsGoal() throws {
        passWelcomeAndGoal(goal: "betterPerformance")
        XCTAssertTrue(app.buttons["safetyContinueButton"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let continueButton = app.buttons["goalContinueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertTrue(continueButton.isEnabled)
        XCTAssertTrue(app.buttons["goal-betterPerformance"].isSelected)
    }

    @MainActor
    func testCompletedOnboardingIsRememberedAfterRelaunch() throws {
        passWelcomeAndGoal()
        answerSafety()
        readBasics()
        XCTAssertTrue(homeLoaded)

        app.terminate()
        app.launchArguments = ["-UITestKeepStore"]
        app.launch()
        XCTAssertTrue(homeLoaded)
        XCTAssertFalse(app.buttons["getStartedButton"].exists)
    }

    @MainActor
    func testInterruptedOnboardingResumesAtSafetyCheck() throws {
        passWelcomeAndGoal()
        XCTAssertTrue(app.buttons["safetyContinueButton"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-UITestKeepStore"]
        app.launch()
        XCTAssertTrue(app.buttons["safetyContinueButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["safetyContinueButton"].isEnabled)
    }
}
