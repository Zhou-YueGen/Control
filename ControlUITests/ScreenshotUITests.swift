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
        app.launchArguments = ["-UITestFastTraining"]
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
        app.launchArguments = ["-UITestFastTraining"]
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

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
