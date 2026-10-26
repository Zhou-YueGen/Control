import XCTest

/// Learn：三个分类的置顶课程和每一节课都能打开对应的详情页。
final class LearnUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-UITestOnboardingDone"]
        app.launch()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Learn"].tap()
    }

    private var detailTitle: XCUIElement { app.staticTexts["lessonDetailTitle"] }

    private func goBack() {
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["learnFeaturedCard"].waitForExistence(timeout: 3))
    }

    private func open(_ element: XCUIElement, expecting title: String) {
        var swipes = 0
        while !element.isHittable && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        element.tap()
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 3))
        XCTAssertEqual(detailTitle.label, title)
        goBack()
    }

    @MainActor
    func testBasicsMatchesReference() throws {
        XCTAssertTrue(app.staticTexts["Learn"].exists)
        for tab in ["basics", "howTo", "mistakes"] {
            XCTAssertTrue(app.buttons["learnTab-\(tab)"].exists)
        }
        XCTAssertEqual(app.buttons["learnFeaturedCard"].label, "Where is the pelvic floor?")
        XCTAssertTrue(app.buttons["learnLesson-what"].exists)
        XCTAssertTrue(app.buttons["learnLesson-safety"].exists)
        XCTAssertFalse(app.buttons["learnLesson-safety"].isHittable,
                       "Lesson 5 should start below the fold so we can verify scrolling")
        app.swipeUp()
        XCTAssertTrue(app.buttons["learnLesson-safety"].waitForExistence(timeout: 2))
        var swipes = 0
        while !app.buttons["learnLesson-safety"].isHittable && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(app.buttons["learnLesson-safety"].isHittable)
    }

    @MainActor
    func testEveryLessonOpensItsDetail() throws {
        let catalog: [(tab: String, featured: String, lessons: [(String, String)])] = [
            ("basics", "Where is the pelvic floor?", [
                ("what", "What is the pelvic floor?"),
                ("contract", "How to contract correctly"),
                ("relax", "How to relax and breathe"),
                ("mistakes", "Common mistakes"),
                ("safety", "Safety and best practices"),
            ]),
            ("howTo", "Your first guided session", [
                ("find", "Finding the right muscles"),
                ("hold", "Contract and hold"),
                ("release", "Letting go completely"),
                ("positions", "Choosing a position"),
                ("routine", "Building a gentle routine"),
            ]),
            ("mistakes", "Why technique matters", [
                ("breath-holding", "Holding your breath"),
                ("wrong-muscles", "Squeezing the wrong muscles"),
                ("bearing-down", "Pushing down instead of lifting"),
                ("no-relax", "Skipping the relaxation"),
                ("on-toilet", "Practicing on the toilet"),
                ("overdoing", "Doing too much, too soon"),
            ]),
        ]

        for entry in catalog {
            app.swipeDown()
            app.buttons["learnTab-\(entry.tab)"].tap()
            open(app.buttons["learnFeaturedCard"], expecting: entry.featured)
            for (id, title) in entry.lessons {
                open(app.buttons["learnLesson-\(id)"], expecting: title)
            }
        }
    }

    @MainActor
    func testNextLessonNavigation() throws {
        app.buttons["learnFeaturedCard"].tap()
        XCTAssertEqual(detailTitle.label, "Where is the pelvic floor?")
        XCTAssertTrue(app.descendants(matching: .any)["lessonKeyPoints"].exists)

        let next = app.buttons["lessonNextButton"]
        while !next.isHittable { app.swipeUp() }
        next.tap()
        XCTAssertTrue(app.staticTexts["What is the pelvic floor?"].waitForExistence(timeout: 3))
    }
}
