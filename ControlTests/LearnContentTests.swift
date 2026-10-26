import Testing
@testable import Control

@MainActor
struct LearnContentTests {
    @Test func lessonIDsAreUnique() {
        let ids = LearnLibrary.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyLessonHasContent() {
        for lesson in LearnLibrary.all {
            #expect(!lesson.title.isEmpty)
            #expect(!lesson.summary.isEmpty)
            #expect(!lesson.sections.isEmpty, "\(lesson.id) has no sections")
            #expect(!lesson.keyPoints.isEmpty, "\(lesson.id) has no key points")
            #expect(lesson.minutes > 0)
        }
    }

    @Test func basicsMatchesReferenceList() {
        #expect(LearnCategory.basics.featured.title == "Where is the pelvic floor?")
        #expect(LearnCategory.basics.lessons.map(\.numberedTitle) == [
            "1. What is the pelvic floor?",
            "2. How to contract correctly",
            "3. How to relax and breathe",
            "4. Common mistakes",
            "5. Safety and best practices",
        ])
    }

    @Test func nextLessonFollowsReadingOrderWithinCategory() {
        for category in LearnCategory.allCases {
            let order = category.readingOrder
            #expect(order.allSatisfy { $0.category == category })
            for (index, lesson) in order.enumerated() {
                #expect(lesson.next == (index + 1 < order.count ? order[index + 1] : nil))
            }
            #expect(category.lessons.map(\.number) == category.lessons.indices.map { $0 + 1 })
        }
    }
}
