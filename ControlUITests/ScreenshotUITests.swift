import XCTest

/// 生成与参考图第 4、5、6 屏对比用的截图（保存在测试结果附件中）。
final class ScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testCaptureTrainingScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestOnboardingDone"]
        app.launch()
        let start = app.buttons["startTrainingButton"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        sleep(1)
        attach("home")

        start.tap()
        let primaryControl = app.buttons["trainingPrimaryControl"]
        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
        sleep(1)
        attach("training-ready")

        primaryControl.tap()
        sleep(5)
        attach("training-contract")

        sleep(4)
        attach("training-relax")

        primaryControl.tap()
        XCTAssertEqual(primaryControl.label, "Resume")
        sleep(1)
        attach("training-paused")
    }

    @MainActor
    func testCaptureSessionComplete() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFastTraining", "-UITestOnboardingDone"]
        app.launch()
        app.buttons["startTrainingButton"].firstMatch.tap()
        let primaryControl = app.buttons["trainingPrimaryControl"]
        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
        primaryControl.tap()

        XCTAssertTrue(app.staticTexts["Great job!"].waitForExistence(timeout: 25))
        sleep(1)
        app.buttons["Comfortable"].tap()
        attach("session-complete")

        app.buttons["discomfort-Yes"].tap()
        sleep(1)
        app.swipeUp()
        sleep(1)
        attach("session-complete-discomfort")
    }

    @MainActor
    func testCaptureHomeAfterSession() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFastTraining", "-UITestOnboardingDone"]
        app.launch()
        app.buttons["startTrainingButton"].firstMatch.tap()
        let primaryControl = app.buttons["trainingPrimaryControl"]
        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
        primaryControl.tap()
        XCTAssertTrue(app.staticTexts["Great job!"].waitForExistence(timeout: 25))
        app.buttons["saveAndContinueButton"].tap()
        XCTAssertTrue(app.buttons["startTrainingButton"].firstMatch.waitForExistence(timeout: 5))
        sleep(1)
        attach("home-after-session")
    }

    @MainActor
    func testCaptureOnboardingScreens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFreshInstall"]
        app.launch()

        let getStarted = app.buttons["getStartedButton"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        sleep(1)
        attach("onboarding-welcome")

        getStarted.tap()
        XCTAssertTrue(app.buttons["goal-improveControl"].waitForExistence(timeout: 5))
        app.buttons["goal-improveControl"].tap()
        sleep(1)
        attach("onboarding-goal")

        app.buttons["goalContinueButton"].tap()
        XCTAssertTrue(app.buttons["safety-age-Yes"].waitForExistence(timeout: 5))
        sleep(1)
        attach("onboarding-safety")

        app.buttons["safety-age-Yes"].tap()
        for id in ["pain", "urination", "surgery", "condition"] {
            let button = app.buttons["safety-\(id)-No"]
            while !button.isHittable { app.swipeUp() }
            button.tap()
        }
        app.buttons["safetyContinueButton"].tap()

        let firstLesson = app.buttons["basics-where"]
        XCTAssertTrue(firstLesson.waitForExistence(timeout: 5))
        firstLesson.tap()
        sleep(1)
        attach("onboarding-learn-basics")
    }

    @MainActor
    func testCaptureSafetyNotice() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFreshInstall"]
        app.launch()
        app.buttons["getStartedButton"].tap()
        XCTAssertTrue(app.buttons["goal-improveControl"].waitForExistence(timeout: 5))
        app.buttons["goal-improveControl"].tap()
        app.buttons["goalContinueButton"].tap()

        XCTAssertTrue(app.buttons["safety-age-Yes"].waitForExistence(timeout: 5))
        app.buttons["safety-age-Yes"].tap()
        for (id, answer) in [("pain", "Yes"), ("urination", "No"), ("surgery", "No"), ("condition", "No")] {
            let button = app.buttons["safety-\(id)-\(answer)"]
            while !button.isHittable { app.swipeUp() }
            button.tap()
        }
        sleep(1)
        attach("onboarding-safety-answered")
        app.buttons["safetyContinueButton"].tap()

        XCTAssertTrue(app.buttons["safetyNoticeAcknowledgeButton"].waitForExistence(timeout: 5))
        sleep(1)
        attach("onboarding-safety-notice")

        app.buttons["safetyNoticeAcknowledgeButton"].tap()
        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 5))
        sleep(1)
        attach("home-education-only")
    }

    @MainActor
    func testCaptureProgressAndSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFastTraining", "-UITestOnboardingDone"]
        app.launch()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Progress"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["progressChart"].waitForExistence(timeout: 5))
        sleep(1)
        attach("progress-empty")

        tabBar.buttons["Home"].tap()
        app.buttons["startTrainingButton"].firstMatch.tap()
        let primaryControl = app.buttons["trainingPrimaryControl"]
        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
        primaryControl.tap()
        XCTAssertTrue(app.staticTexts["Great job!"].waitForExistence(timeout: 25))
        app.buttons["Comfortable"].tap()
        app.buttons["saveAndContinueButton"].tap()

        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Progress"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["progressChart"].waitForExistence(timeout: 5))
        sleep(1)
        attach("progress-data")
        app.swipeUp()
        sleep(1)
        attach("progress-data-calendar")
        app.swipeUp()
        sleep(1)
        attach("progress-data-sessions")

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["soundToggle"].waitForExistence(timeout: 5))
        sleep(1)
        attach("settings")
        app.swipeUp()
        sleep(1)
        attach("settings-bottom")

        app.buttons["deleteAllDataButton"].tap()
        XCTAssertTrue(app.alerts["Delete all data?"].waitForExistence(timeout: 3))
        sleep(1)
        attach("settings-delete-alert")
        app.alerts.buttons["Cancel"].tap()

        app.swipeDown()
        app.buttons["safetyInformationRow"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["safetyStatusCard"].waitForExistence(timeout: 5))
        sleep(1)
        attach("safety-information")
    }

    @MainActor
    func testCaptureHomeDayDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFastTraining", "-UITestOnboardingDone"]
        app.launch()
        app.buttons["startTrainingButton"].firstMatch.tap()
        let primaryControl = app.buttons["trainingPrimaryControl"]
        XCTAssertTrue(primaryControl.waitForExistence(timeout: 5))
        primaryControl.tap()
        XCTAssertTrue(app.staticTexts["Great job!"].waitForExistence(timeout: 25))
        app.buttons["Comfortable"].tap()
        app.buttons["saveAndContinueButton"].tap()
        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 5))

        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'homeDay-' AND label CONTAINS ', today'"))
            .firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["dayDetailSummary"].waitForExistence(timeout: 3))
        sleep(1)
        attach("home-day-detail")
    }

    @MainActor
    func testCaptureLearn() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestOnboardingDone"]
        app.launch()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Learn"].tap()
        XCTAssertTrue(app.buttons["learnFeaturedCard"].waitForExistence(timeout: 5))
        sleep(1)
        attach("learn-basics")

        app.buttons["learnTab-howTo"].tap()
        sleep(1)
        attach("learn-howto")
        app.buttons["learnTab-mistakes"].tap()
        sleep(1)
        attach("learn-mistakes")

        app.buttons["learnTab-basics"].tap()
        app.buttons["learnFeaturedCard"].tap()
        XCTAssertTrue(app.staticTexts["lessonDetailTitle"].waitForExistence(timeout: 3))
        sleep(1)
        attach("learn-lesson-top")
        app.swipeUp()
        sleep(1)
        attach("learn-lesson-middle")
        app.swipeUp()
        sleep(1)
        attach("learn-lesson-bottom")
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
