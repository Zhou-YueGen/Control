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

    @Test func feedbackIsSavedOnlyForRecordedSessions() {
        let store = SessionStore()
        #expect(store.saveFeedback(SessionFeedback(difficulty: .easy), for: SessionSummary.preview.id) == false)

        store.recordCompleted(.preview)
        #expect(store.saveFeedback(SessionFeedback(difficulty: .easy, discomfort: .no), for: SessionSummary.preview.id))
        #expect(store.saveFeedback(SessionFeedback(discomfort: .yes), for: SessionSummary.preview.id))
        #expect(store.feedbackBySession.count == 1)
        #expect(store.feedbackBySession[SessionSummary.preview.id]?.discomfort == .yes)
    }
}

@MainActor
struct AppRouterTests {
    private func onboardedRouter(hasTemplate: Bool = true, allowsDemo: Bool = true) -> AppRouter {
        let preferences = PreferencesStore.inMemory()
        preferences.markOnboardingDoneForTesting()
        return AppRouter(preferences: preferences, template: hasTemplate ? .uiTestFast : nil,
                         allowsDemoTemplates: allowsDemo)
    }

    private func finishSession(_ router: AppRouter) -> UUID? {
        guard router.startTraining(), case .training(let sessionID) = router.trainingStep else { return nil }
        router.finishTraining(with: SessionSummary(id: sessionID, templateID: "t", templateTitle: "T",
                                                   activeDurationSeconds: 8, completedRepetitions: 2,
                                                   totalRepetitions: 2, completedAt: .now))
        return sessionID
    }

    @Test func completedSessionIsRecordedOnceAndFeedbackSaved() throws {
        let router = onboardedRouter()
        let sessionID = try #require(finishSession(router))
        #expect(router.startTraining() == false)
        router.finishTraining(with: SessionSummary(id: sessionID, templateID: "t", templateTitle: "T",
                                                   activeDurationSeconds: 8, completedRepetitions: 2,
                                                   totalRepetitions: 2, completedAt: .now))
        #expect(router.store.totalSessions == 1)

        router.saveAndContinue(feedback: SessionFeedback(difficulty: .comfortable, discomfort: DiscomfortAnswer.no))
        router.saveAndContinue(feedback: SessionFeedback(difficulty: .tooHard, discomfort: .yes))
        #expect(router.trainingStep == nil)
        #expect(router.store.feedbackBySession[sessionID]?.difficulty == .comfortable)
        #expect(router.preferences.trainingHold == false)
    }

    @Test func reportingDiscomfortSetsHoldAndBlocksTraining() throws {
        let router = onboardedRouter()
        _ = try #require(finishSession(router))
        router.saveAndContinue(feedback: SessionFeedback(discomfort: .yes))

        #expect(router.preferences.trainingHold)
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.hold))
        #expect(router.startTraining() == false)
    }

    @Test func exitingTrainingRecordsNothing() {
        let router = onboardedRouter()
        router.startTraining()
        router.exitTraining()
        #expect(router.trainingStep == nil)
        #expect(router.store.totalSessions == 0)
    }

    @Test func gateBlocksUnreviewedTemplateInRelease() {
        let router = onboardedRouter(allowsDemo: false)
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.noTemplate))
        #expect(router.startTraining() == false)
    }

    @Test func gateBlocksMissingTemplate() {
        #expect(onboardedRouter(hasTemplate: false).startTraining() == false)
    }

    @Test func gateChecksOnboardingInDocumentedOrder() {
        let router = AppRouter(preferences: .inMemory(), template: .uiTestFast, allowsDemoTemplates: true)
        let preferences = router.preferences
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.adultsOnly))

        preferences.adultConfirmed = true
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.safetyCheckNeeded))

        preferences.safetyAccessStatus = .educationOnly
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.educationOnly))

        preferences.safetyAccessStatus = .noPredefinedFlag
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.basicsNeeded))

        preferences.basicEducationCompleted = true
        preferences.onboardingCompleted = true
        #expect(router.trainingGate() == .allowed)
    }
}

@MainActor
struct SafetyScreeningTests {
    private func answers(age: SafetyAnswer = .yes, risk: SafetyAnswer = .no) -> [SafetyQuestion.ID: SafetyAnswer] {
        var result = [SafetyScreening.ageQuestion.id: age]
        for question in SafetyScreening.riskQuestions { result[question.id] = risk }
        return result
    }

    @Test func adultWithNoFlagsGoesToBasics() {
        #expect(SafetyScreening.evaluate(answers: answers(), goal: .improveControl) == .learnBasics)
    }

    @Test func underageIsEducationOnly() {
        #expect(SafetyScreening.evaluate(answers: answers(age: .no), goal: .improveControl) == .educationOnly(.underage))
    }

    @Test func anyYesOrPreferNotToSayIsEducationOnly() {
        for answer in [SafetyAnswer.yes, .preferNotToSay] {
            for question in SafetyScreening.riskQuestions {
                var values = answers()
                values[question.id] = answer
                #expect(SafetyScreening.evaluate(answers: values, goal: .improveControl) == .educationOnly(.riskAnswer))
            }
        }
    }

    @Test func unansweredQuestionIsTreatedConservatively() {
        var values = answers()
        values[SafetyScreening.riskQuestions[0].id] = nil
        #expect(SafetyScreening.isComplete(values) == false)
        #expect(SafetyScreening.evaluate(answers: values, goal: .improveControl) == .educationOnly(.riskAnswer))
        #expect(SafetyScreening.evaluate(answers: [:], goal: .improveControl) == .educationOnly(.underage))
    }

    @Test func recoveryGoalIsEducationOnly() {
        #expect(SafetyScreening.evaluate(answers: answers(), goal: .recoveryInformation) == .educationOnly(.recoveryGoal))
    }
}

@MainActor
struct OnboardingTests {
    @Test func preferencesPersistAcrossInstances() throws {
        let suite = "control.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let first = PreferencesStore(defaults: defaults)
        #expect(first.onboardingStep == .welcome)
        #expect(first.soundEnabled)
        first.markOnboardingDoneForTesting()
        first.trainingHold = true
        first.soundEnabled = false

        let second = PreferencesStore(defaults: defaults)
        #expect(second.onboardingCompleted)
        #expect(second.onboardingStep == .finished)
        #expect(second.primaryGoal == .improveControl)
        #expect(second.safetyAccessStatus == .noPredefinedFlag)
        #expect(second.trainingHold)
        #expect(second.soundEnabled == false)
        #expect(second.hapticsEnabled)
    }

    @Test func happyPathUnlocksTraining() {
        let router = AppRouter(preferences: .inMemory(), template: .uiTestFast, allowsDemoTemplates: true)
        router.completeWelcome()
        #expect(router.preferences.onboardingStep == .goals)
        router.selectGoal(.improveControl)
        #expect(router.preferences.onboardingStep == .safetyCheck)

        var answers = [SafetyScreening.ageQuestion.id: SafetyAnswer.yes]
        for question in SafetyScreening.riskQuestions { answers[question.id] = .no }
        #expect(router.submitSafety(answers: answers) == .learnBasics)
        #expect(router.preferences.onboardingStep == .learnBasics)
        #expect(router.preferences.onboardingCompleted == false)

        router.completeBasics()
        #expect(router.preferences.onboardingCompleted)
        #expect(router.preferences.basicEducationCompleted)
        #expect(router.trainingGate() == .allowed)
    }

    @Test func riskPathCompletesOnboardingInEducationMode() {
        let router = AppRouter(preferences: .inMemory(), template: .uiTestFast, allowsDemoTemplates: true)
        router.selectGoal(.generalPelvicHealth)
        var answers = [SafetyScreening.ageQuestion.id: SafetyAnswer.yes]
        for question in SafetyScreening.riskQuestions { answers[question.id] = .no }
        answers[SafetyScreening.riskQuestions[1].id] = .yes

        #expect(router.submitSafety(answers: answers) == .educationOnly(.riskAnswer))
        #expect(router.preferences.onboardingStep == .safetyNotice)

        router.completeBasics()
        #expect(router.preferences.basicEducationCompleted == false)

        router.acknowledgeSafetyNotice()
        #expect(router.preferences.onboardingCompleted)
        #expect(router.preferences.basicEducationCompleted == false)
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.educationOnly))
        #expect(router.startTraining() == false)
    }

    @Test func underageIsNotAdultConfirmed() {
        let router = AppRouter(preferences: .inMemory(), template: .uiTestFast, allowsDemoTemplates: true)
        router.selectGoal(.improveControl)
        var answers = [SafetyScreening.ageQuestion.id: SafetyAnswer.no]
        for question in SafetyScreening.riskQuestions { answers[question.id] = .no }
        router.submitSafety(answers: answers)
        router.acknowledgeSafetyNotice()

        #expect(router.preferences.adultConfirmed == false)
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.adultsOnly))
    }

    @Test func resumePathMatchesSavedStep() {
        let preferences = PreferencesStore.inMemory()
        #expect(OnboardingFlowView.initialPath(for: preferences).isEmpty)
        preferences.onboardingStep = .safetyCheck
        #expect(OnboardingFlowView.initialPath(for: preferences) == [.goals, .safetyCheck])
        preferences.onboardingStep = .safetyNotice
        #expect(OnboardingFlowView.initialPath(for: preferences) == [.safetyNotice(.underage)])
    }
}
