import Foundation
import Testing
@testable import Control

@MainActor
struct TrainingEngineTests {
    final class TestClock {
        var now: TimeInterval = 1_000
        func advance(_ seconds: TimeInterval) { now += seconds }
    }

    private let template = TrainingTemplate(
        id: "test", title: "Test", subtitle: "", contractionSeconds: 4, relaxationSeconds: 4,
        repetitions: 3, contentReviewVersion: "test", isApprovedForRelease: false
    )

    private func makeEngine(_ clock: TestClock) -> TrainingEngine {
        TrainingEngine(template: template, preparationSeconds: 3, uptime: { clock.now })
    }

    @Test func startsIdleThenPrepares() {
        let clock = TestClock()
        let engine = makeEngine(clock)
        #expect(engine.status == .idle)

        engine.start()
        #expect(engine.status == .running)
        #expect(engine.phase == .preparing)
        #expect(engine.phaseRemainingSeconds == 3)
        engine.stop()
    }

    @Test func alternatesContractAndRelaxAndCountsFullCycles() {
        let clock = TestClock()
        let engine = makeEngine(clock)
        engine.start()

        clock.advance(3.5)
        engine.refresh()
        #expect(engine.phase == .contract)
        #expect(engine.completedRepetitions == 0)

        clock.advance(4)
        engine.refresh()
        #expect(engine.phase == .relax)
        #expect(engine.completedRepetitions == 0)

        clock.advance(4)
        engine.refresh()
        #expect(engine.phase == .contract)
        #expect(engine.completedRepetitions == 1)
        #expect(engine.currentRepetition == 2)
        engine.stop()
    }

    @Test func pauseFreezesTimeAndResumeContinues() {
        let clock = TestClock()
        let engine = makeEngine(clock)
        engine.start()
        clock.advance(4)
        engine.pause()
        #expect(engine.status == .paused)
        #expect(engine.phaseRemainingSeconds == 3)

        clock.advance(300)
        engine.refresh()
        #expect(engine.phaseRemainingSeconds == 3)
        #expect(engine.trainingElapsed == 1)

        engine.resume()
        clock.advance(1)
        engine.refresh()
        #expect(engine.status == .running)
        #expect(engine.phaseRemainingSeconds == 2)
        engine.stop()
    }

    @Test func completesExactlyOnceAndExcludesPreparation() {
        let clock = TestClock()
        let engine = makeEngine(clock)
        engine.start()

        clock.advance(500)
        engine.refresh()
        #expect(engine.status == .completed)
        #expect(engine.completedRepetitions == 3)
        #expect(engine.totalRemainingSeconds == 0)

        engine.start()
        engine.resume()
        engine.cancel()
        engine.refresh()
        #expect(engine.status == .completed)
        #expect(engine.makeSummary(id: UUID())?.activeDurationSeconds == 24)
    }

    @Test func cancelledSessionHasNoSummary() {
        let clock = TestClock()
        let engine = makeEngine(clock)
        engine.start()
        clock.advance(10)
        engine.cancel()

        #expect(engine.status == .cancelled)
        #expect(engine.makeSummary(id: UUID()) == nil)
    }

    @Test func controlsAreIgnoredInWrongStates() {
        let engine = makeEngine(TestClock())
        engine.pause()
        engine.resume()
        engine.cancel()
        #expect(engine.status == .idle)
    }

    @Test func phaseCueFiresOncePerPhase() {
        let clock = TestClock()
        let engine = makeEngine(clock)
        engine.start()
        #expect(engine.phaseCueCount == 1)

        clock.advance(1)
        engine.refresh()
        #expect(engine.phaseCueCount == 1)

        clock.advance(2.5)
        engine.refresh()
        #expect(engine.phaseCueCount == 2)

        engine.pause()
        engine.resume()
        #expect(engine.phaseCueCount == 2)
        engine.stop()
    }
}

@MainActor
struct SessionStoreTests {
    private func summary(daysAgo: Int, calendar: Calendar) -> SessionSummary {
        SessionSummary(
            id: UUID(), templateID: "t", templateTitle: "T", activeDurationSeconds: 90,
            completedRepetitions: 8, totalRepetitions: 8,
            completedAt: calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
        )
    }

    @Test func recordsEachSessionOnce() {
        let store = SessionStore()
        store.recordCompleted(.preview)
        store.recordCompleted(.preview)
        #expect(store.totalSessions == 1)
    }

    @Test func streakCountsDistinctConsecutiveDays() {
        let store = SessionStore()
        let calendar = store.calendar
        store.recordCompleted(summary(daysAgo: 0, calendar: calendar))
        store.recordCompleted(summary(daysAgo: 0, calendar: calendar))
        store.recordCompleted(summary(daysAgo: 1, calendar: calendar))
        store.recordCompleted(summary(daysAgo: 3, calendar: calendar))

        #expect(store.totalSessions == 4)
        #expect(store.currentStreak() == 2)
        #expect(store.totalMinutes == 6)
    }

    @Test func streakStartsFromYesterdayWhenTodayIsEmpty() {
        let store = SessionStore()
        store.recordCompleted(summary(daysAgo: 1, calendar: store.calendar))
        store.recordCompleted(summary(daysAgo: 2, calendar: store.calendar))
        #expect(store.currentStreak() == 2)
    }

    @Test func discomfortSetsTrainingHold() {
        let store = SessionStore()
        store.recordCompleted(.preview)
        store.saveFeedback(SessionFeedback(difficulty: .easy, discomfort: .no), for: SessionSummary.preview.id)
        #expect(store.trainingHold == false)

        store.saveFeedback(SessionFeedback(difficulty: nil, discomfort: .yes), for: SessionSummary.preview.id)
        #expect(store.trainingHold == true)
        #expect(store.feedbackBySession.count == 1)
    }
}

@MainActor
struct AppRouterTests {
    @Test func completedSessionIsRecordedOnceAndFeedbackSaved() throws {
        let router = AppRouter(template: .uiTestFast, allowsDemoTemplates: true)
        #expect(router.startTraining())
        #expect(router.startTraining() == false)

        guard case .training(let sessionID) = router.trainingStep else {
            Issue.record("Expected training step")
            return
        }
        let summary = SessionSummary(id: sessionID, templateID: "t", templateTitle: "T",
                                     activeDurationSeconds: 8, completedRepetitions: 2,
                                     totalRepetitions: 2, completedAt: .now)
        router.finishTraining(with: summary)
        router.finishTraining(with: summary)
        #expect(router.store.totalSessions == 1)

        router.saveAndContinue(feedback: SessionFeedback(difficulty: .comfortable, discomfort: DiscomfortAnswer.no))
        router.saveAndContinue(feedback: SessionFeedback(difficulty: .tooHard, discomfort: .yes))
        #expect(router.trainingStep == nil)
        #expect(router.store.feedbackBySession[sessionID]?.difficulty == .comfortable)
        #expect(router.store.trainingHold == false)
    }

    @Test func exitingTrainingRecordsNothing() {
        let router = AppRouter(template: .uiTestFast, allowsDemoTemplates: true)
        router.startTraining()
        router.exitTraining()
        #expect(router.trainingStep == nil)
        #expect(router.store.totalSessions == 0)
    }

    @Test func gateBlocksDuringTrainingHold() {
        let router = AppRouter(template: .uiTestFast, allowsDemoTemplates: true)
        router.store.recordCompleted(.preview)
        router.store.saveFeedback(SessionFeedback(discomfort: .yes), for: SessionSummary.preview.id)

        #expect(router.trainingGate() != .allowed)
        #expect(router.startTraining() == false)
        #expect(router.trainingStep == nil)
    }

    @Test func gateBlocksUnreviewedTemplateInRelease() {
        let router = AppRouter(template: .uiTestFast, allowsDemoTemplates: false)
        #expect(router.trainingGate() == .blocked(reason: "Training is not available yet."))
        #expect(router.startTraining() == false)
    }

    @Test func gateBlocksMissingTemplate() {
        let router = AppRouter(template: nil, allowsDemoTemplates: true)
        #expect(router.startTraining() == false)
    }
}
