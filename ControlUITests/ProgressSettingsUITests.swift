import XCTest

/// Progress、Settings 和本地数据保存：记录与设置在重启后保留，Delete All Data 回到 Welcome。
final class ProgressSettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-UITestFastTraining", "-UITestOnboardingDone"]
        app.launch()
    }

    private var tabBar: XCUIElement { app.tabBars.firstMatch }
    private var sessionsMetric: XCUIElement { app.descendants(matching: .any)["progressSessionsMetric"] }

    private func relaunchKeepingData() {
        app.terminate()
        app.launchArguments = ["-UITestFastTraining", "-UITestKeepStore"]
        app.launch()
    }

    private func completeSession() {
        let start = app.buttons["startTrainingButton"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let primary = app.buttons["trainingPrimaryControl"]
        XCTAssertTrue(primary.waitForExistence(timeout: 5))
        primary.tap()
        XCTAssertTrue(app.staticTexts["Great job!"].waitForExistence(timeout: 25))
        app.buttons["Comfortable"].tap()
        app.buttons["saveAndContinueButton"].tap()
        XCTAssertTrue(app.staticTexts["weeklyProgressCount"].waitForExistence(timeout: 5))
    }

    private func openProgress() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Progress"].tap()
        XCTAssertTrue(sessionsMetric.waitForExistence(timeout: 5))
    }

    private func openSettings() {
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Settings"].tap()
    }

    /// SwiftUI 的 Toggle 只响应开关本身，点整行中心不会切换。
    private func flip(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    }

    @MainActor
    func testNewUserSeesEmptyProgress() throws {
        openProgress()
        XCTAssertEqual(sessionsMetric.value as? String, "0")
        XCTAssertTrue(app.descendants(matching: .any)["progressChart"].exists)
        XCTAssertTrue(app.staticTexts["This Week"].exists)
        XCTAssertTrue(app.staticTexts["Training Consistency"].exists)
        XCTAssertFalse(app.buttons["Start a session"].exists)
        for range in ["7D", "30D", "3M", "1Y"] {
            XCTAssertTrue(app.buttons["range-\(range)"].exists)
        }
        app.buttons["range-1Y"].tap()
        XCTAssertTrue(app.staticTexts["Last 12 Months"].waitForExistence(timeout: 2))
        XCTAssertEqual(sessionsMetric.value as? String, "0")
    }

    @MainActor
    func testCompletedSessionIsSavedAcrossRelaunch() throws {
        completeSession()
        openProgress()
        XCTAssertEqual(sessionsMetric.value as? String, "1")
        relaunchKeepingData()
        XCTAssertEqual(app.staticTexts["weeklyProgressCount"].label, "1 / 7 days")
        openProgress()
        XCTAssertEqual(sessionsMetric.value as? String, "1")
        let recent = app.descendants(matching: .any)["recentSessionRow"].firstMatch
        var swipes = 0
        while !recent.isHittable && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(recent.waitForExistence(timeout: 3))
        XCTAssertTrue(recent.isHittable, "Completed sessions should appear after scrolling")
        XCTAssertTrue(app.staticTexts["Comfortable · self-reported"].exists
                      || app.descendants(matching: .any)["recentSessionRow"].firstMatch.label.contains("Comfortable"))

        for range in ["30D", "3M", "1Y"] {
            app.buttons["range-\(range)"].tap()
            XCTAssertEqual(sessionsMetric.value as? String, "1")
        }
    }

    @MainActor
    func testSoundSettingIsSavedAcrossRelaunch() throws {
        openSettings()
        let sound = app.switches["soundToggle"]
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "1")
        flip(sound)
        XCTAssertEqual(sound.value as? String, "0")

        relaunchKeepingData()
        openSettings()
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "0")
        XCTAssertEqual(app.switches["hapticsToggle"].value as? String, "1")
    }

    @MainActor
    func testSafetyInformationShowsCurrentStatus() throws {
        openSettings()
        app.buttons["safetyInformationRow"].tap()
        let status = app.descendants(matching: .any)["safetyStatusCard"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Guided training available"))
    }

    @MainActor
    func testDeleteAllDataReturnsToWelcome() throws {
        completeSession()
        openSettings()

        let delete = app.buttons["deleteAllDataButton"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        let alert = app.alerts["Delete all data?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Cancel"].tap()
        openProgress()
        XCTAssertEqual(sessionsMetric.value as? String, "1")

        openSettings()
        delete.tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["getStartedButton"].waitForExistence(timeout: 5))

        relaunchKeepingData()
        XCTAssertTrue(app.buttons["getStartedButton"].waitForExistence(timeout: 5))
    }
}
