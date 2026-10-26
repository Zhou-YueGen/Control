import Foundation
import SwiftData
import Testing
@testable import Control

@MainActor
struct PersistenceTests {
    private func summary(daysAgo: Int, seconds: Int = 90, calendar: Calendar = .controlDefault) -> SessionSummary {
        SessionSummary(
            id: UUID(), templateID: "t", templateTitle: "T", activeDurationSeconds: seconds,
            completedRepetitions: 8, totalRepetitions: 8,
            completedAt: calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
        )
    }

    @Test func recordsAndFeedbackSurviveANewContext() {
        let container = ModelContainer.controlInMemory()
        let first = SessionStore(context: ModelContext(container))
        first.recordCompleted(.preview)
        first.recordCompleted(.preview)
        first.saveFeedback(SessionFeedback(difficulty: .easy, discomfort: .no), for: SessionSummary.preview.id)
        first.saveFeedback(SessionFeedback(difficulty: .challenging), for: SessionSummary.preview.id)

        let second = SessionStore(context: ModelContext(container))
        #expect(second.totalSessions == 1)
        #expect(second.completedSessions.first == .preview)
        #expect(second.feedbackBySession[SessionSummary.preview.id] == SessionFeedback(difficulty: .challenging))
    }

    @Test func sessionWithoutFeedbackHasNoFeedbackEntry() {
        let container = ModelContainer.controlInMemory()
        SessionStore(context: ModelContext(container)).recordCompleted(.preview)
        let reloaded = SessionStore(context: ModelContext(container))
        #expect(reloaded.totalSessions == 1)
        #expect(reloaded.feedbackBySession.isEmpty)
    }

    @Test func deleteAllDataClearsStoreAndOnboarding() {
        let container = ModelContainer.controlInMemory()
        let preferences = PreferencesStore.inMemory()
        preferences.markOnboardingDoneForTesting()
        preferences.trainingHold = true
        preferences.soundEnabled = false
        let router = AppRouter(store: SessionStore(context: ModelContext(container)), preferences: preferences,
                               template: .uiTestFast, allowsDemoTemplates: true)
        router.store.recordCompleted(summary(daysAgo: 0))
        router.store.recordCompleted(summary(daysAgo: 1))

        router.deleteAllData()

        #expect(router.store.totalSessions == 0)
        #expect(router.store.currentStreak() == 0)
        #expect(SessionStore(context: ModelContext(container)).totalSessions == 0)
        #expect(preferences.onboardingCompleted == false)
        #expect(preferences.onboardingStep == .welcome)
        #expect(preferences.safetyAccessStatus == .notScreened)
        #expect(preferences.adultConfirmed == false)
        #expect(preferences.trainingHold == false)
        #expect(preferences.soundEnabled)
        #expect(router.trainingGate() == .blocked(reason: AppRouter.GateMessage.adultsOnly))
    }

    @Test func rangeSummaryOnlyCountsSessionsInRange() {
        let store = SessionStore()
        store.recordCompleted(summary(daysAgo: 0, seconds: 60))
        store.recordCompleted(summary(daysAgo: 0, seconds: 30))
        store.recordCompleted(summary(daysAgo: 3, seconds: 120))
        store.recordCompleted(summary(daysAgo: 10, seconds: 600))
        store.recordCompleted(summary(daysAgo: 40, seconds: 600))

        let week = store.summary(lastDays: 7)
        #expect(week.days.count == 7)
        #expect(week.totalSessions == 3)
        #expect(week.totalSeconds == 210)
        #expect(week.totalMinutes == 4)
        #expect(week.trainingDays == 2)
        #expect(week.days.last?.sessions == 2)
        #expect(store.calendar.isDateInToday(week.days.last!.date))

        let month = store.summary(lastDays: 30)
        #expect(month.days.count == 30)
        #expect(month.totalSessions == 4)
        #expect(month.trainingDays == 3)
    }

    @Test func progressRangesCoverExpectedDays() {
        let calendar = Calendar.controlDefault
        let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 10))!
        let store = SessionStore(calendar: calendar)

        let week = store.days(in: .week, asOf: today)
        #expect(week.count == 7)
        #expect(SessionStore.dayKey(for: week.first!, calendar: calendar) == "2026-10-19")
        #expect(SessionStore.dayKey(for: week.last!, calendar: calendar) == "2026-10-25")

        #expect(store.days(in: .month, asOf: today).count == 30)
        let quarter = store.days(in: .quarter, asOf: today)
        #expect(SessionStore.dayKey(for: quarter.first!, calendar: calendar) == "2026-07-23")
        #expect(SessionStore.dayKey(for: quarter.last!, calendar: calendar) == "2026-10-22")
        let year = store.days(in: .year, asOf: today)
        #expect(SessionStore.dayKey(for: year.first!, calendar: calendar) == "2025-10-23")
        #expect(year.count == 365)
    }

    @Test func chartBarsGroupByWeekAndMonth() {
        let calendar = Calendar.controlDefault
        let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 10))!
        let store = SessionStore(calendar: calendar)
        func record(_ day: Int, month: Int, seconds: Int) {
            let date = calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 9))!
            store.recordCompleted(SessionSummary(id: UUID(), templateID: "t", templateTitle: "T",
                                                 activeDurationSeconds: seconds, completedRepetitions: 8,
                                                 totalRepetitions: 8, completedAt: date))
        }
        record(20, month: 10, seconds: 60)
        record(21, month: 10, seconds: 120)
        record(5, month: 9, seconds: 300)

        #expect(store.summary(for: .week, asOf: today).totalSessions == 2)
        #expect(store.chartBars(for: .week, asOf: today).count == 7)

        let weekly = store.chartBars(for: .quarter, asOf: today)
        #expect(weekly.last?.seconds == 180)
        #expect(weekly.reduce(0) { $0 + $1.sessions } == 3)

        let monthly = store.chartBars(for: .year, asOf: today)
        #expect(monthly.count == 13)
        #expect(monthly.last?.seconds == 180)
        #expect(monthly[monthly.count - 2].seconds == 300)
        #expect(store.summary(for: .year, asOf: today).totalSessions == 3)
    }

    @Test func dayKeyUsesLocalCalendarDate() {
        var calendar = Calendar.controlDefault
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: 23, minute: 30))!
        #expect(SessionStore.dayKey(for: date, calendar: calendar) == "2026-03-05")

        var utc = calendar
        utc.timeZone = TimeZone(identifier: "UTC")!
        #expect(SessionStore.dayKey(for: date, calendar: utc) == "2026-03-05")
        let lateNight = calendar.date(from: DateComponents(year: 2026, month: 3, day: 6, hour: 2))!
        #expect(SessionStore.dayKey(for: lateNight, calendar: utc) == "2026-03-05")
    }

    @Test func savedDayKeyIsKeptAfterReload() throws {
        let container = ModelContainer.controlInMemory()
        let context = ModelContext(container)
        let session = summary(daysAgo: 0)
        SessionStore(context: context).recordCompleted(session)

        let record = try #require(try context.fetch(FetchDescriptor<StoredSession>()).first)
        #expect(record.localDayKey == SessionStore.dayKey(for: session.completedAt, calendar: .controlDefault))
        #expect(SessionStore(context: ModelContext(container)).hasSession(on: .now))
    }
}
