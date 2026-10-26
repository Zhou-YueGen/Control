import Foundation
import Observation
import SwiftData

/// 训练记录与反馈。传入 `ModelContext` 时保存到本地 SwiftData 数据库，否则只在内存中。
/// Home 和 Progress 都从这里读取统计，保证数字只有一个来源（USER_FLOW 7.2）。
@Observable
final class SessionStore {
    /// 按完成时间从早到晚排列。
    private(set) var completedSessions: [SessionSummary] = []
    private(set) var feedbackBySession: [UUID: SessionFeedback] = [:]
    @ObservationIgnored private var dayKeyBySession: [UUID: String] = [:]
    /// 最近一次写入数据库失败时为 true，供界面提示。
    private(set) var lastSaveFailed = false

    let calendar: Calendar
    @ObservationIgnored private let context: ModelContext?

    init(context: ModelContext? = nil, calendar: Calendar = .controlDefault) {
        self.context = context
        self.calendar = calendar
        load()
    }

    private func load() {
        guard let context else { return }
        let descriptor = FetchDescriptor<StoredSession>(sortBy: [SortDescriptor(\.completedAt)])
        let records = (try? context.fetch(descriptor)) ?? []
        completedSessions = records.map(\.summary)
        dayKeyBySession = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0.localDayKey) })
        feedbackBySession = records.reduce(into: [:]) { result, record in
            if let feedback = record.feedback { result[record.id] = feedback }
        }
    }

    // MARK: - Writes

    /// 记录一次正常完成的训练并立即保存。同一个 id 只会记录一次。
    func recordCompleted(_ summary: SessionSummary) {
        guard !completedSessions.contains(where: { $0.id == summary.id }) else { return }
        let dayKey = Self.dayKey(for: summary.completedAt, calendar: calendar)
        completedSessions.append(summary)
        completedSessions.sort { $0.completedAt < $1.completedAt }
        dayKeyBySession[summary.id] = dayKey

        guard let context else { return }
        context.insert(StoredSession(summary: summary, localDayKey: dayKey))
        save()
    }

    /// 按 session id 覆盖保存反馈。只接受已记录的训练。
    @discardableResult
    func saveFeedback(_ feedback: SessionFeedback, for sessionID: UUID) -> Bool {
        guard completedSessions.contains(where: { $0.id == sessionID }) else { return false }
        feedbackBySession[sessionID] = feedback

        if let context, let record = try? context.fetch(
            FetchDescriptor<StoredSession>(predicate: #Predicate { $0.id == sessionID })
        ).first {
            record.apply(feedback)
            save()
        }
        return true
    }

    /// 删除全部训练记录和反馈。
    func deleteAll() {
        completedSessions = []
        feedbackBySession = [:]
        dayKeyBySession = [:]
        guard let context else { return }
        try? context.delete(model: StoredSession.self)
        save()
    }

    private func save() {
        do {
            try context?.save()
            lastSaveFailed = false
        } catch {
            lastSaveFailed = true
        }
    }

    // MARK: - Day keys

    /// 当地日历日期字符串，例如 `2026-10-23`。
    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    func dayKey(for date: Date) -> String { Self.dayKey(for: date, calendar: calendar) }

    private func dayKey(of session: SessionSummary) -> String {
        dayKeyBySession[session.id] ?? dayKey(for: session.completedAt)
    }

    // MARK: - Statistics

    var totalSessions: Int { completedSessions.count }

    var totalSeconds: Int { completedSessions.reduce(0) { $0 + $1.activeDurationSeconds } }

    /// 累计分钟数，按四舍五入取整。
    var totalMinutes: Int { Self.minutes(fromSeconds: totalSeconds) }

    static func minutes(fromSeconds seconds: Int) -> Int { Int((Double(seconds) / 60).rounded()) }

    private var trainingDayKeys: Set<String> { Set(completedSessions.map(dayKey(of:))) }

    func hasSession(on day: Date) -> Bool {
        trainingDayKeys.contains(dayKey(for: day))
    }

    func week(containing date: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    func trainingDaysCount(inWeekContaining date: Date) -> Int {
        week(containing: date).filter(hasSession(on:)).count
    }

    func sessionsCount(on day: Date) -> Int {
        sessions(on: day).count
    }

    /// 某一天（当地日历日）完成的训练，按完成时间从早到晚。
    func sessions(on day: Date) -> [SessionSummary] {
        let key = dayKey(for: day)
        return completedSessions.filter { dayKey(of: $0) == key }
    }

    /// 从今天（今天还没练则从昨天）向前连续的训练日数量。
    func currentStreak(asOf date: Date = .now) -> Int {
        let keys = trainingDayKeys
        var cursor = calendar.startOfDay(for: date)
        if !keys.contains(dayKey(for: cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while keys.contains(dayKey(for: cursor)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    struct DaySummary: Identifiable, Equatable {
        let date: Date
        let sessions: Int
        let seconds: Int
        var id: Date { date }
        var minutes: Double { Double(seconds) / 60 }
    }

    struct RangeSummary: Equatable {
        let days: [DaySummary]
        var totalSessions: Int { days.reduce(0) { $0 + $1.sessions } }
        var totalSeconds: Int { days.reduce(0) { $0 + $1.seconds } }
        var totalMinutes: Int { SessionStore.minutes(fromSeconds: totalSeconds) }
        var trainingDays: Int { days.filter { $0.sessions > 0 }.count }
    }

    /// 截至 `date` 当天（含）最近 `lastDays` 天，每天的次数和练习秒数。
    func summary(lastDays: Int, asOf date: Date = .now) -> RangeSummary {
        let today = calendar.startOfDay(for: date)
        let days = (0..<max(lastDays, 0)).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
        return summary(days: days)
    }

    /// 给定日期（按当地日历日）各自的次数和练习秒数，顺序与传入一致。
    func summary(days: [Date]) -> RangeSummary {
        var byKey: [String: (sessions: Int, seconds: Int)] = [:]
        for session in completedSessions {
            let key = dayKey(of: session)
            byKey[key, default: (0, 0)].sessions += 1
            byKey[key, default: (0, 0)].seconds += session.activeDurationSeconds
        }
        return RangeSummary(days: days.map { day in
            let start = calendar.startOfDay(for: day)
            let totals = byKey[dayKey(for: start)] ?? (0, 0)
            return DaySummary(date: start, sessions: totals.sessions, seconds: totals.seconds)
        })
    }

    /// Progress 页的统计范围。7D 是本周一到周日；其余是截至今天的最近 30 天、3 个月、12 个月。
    func days(in range: ProgressRange, asOf date: Date = .now) -> [Date] {
        let today = calendar.startOfDay(for: date)
        let firstDay: Date?
        switch range {
        case .week: return week(containing: today)
        case .month: firstDay = calendar.date(byAdding: .day, value: -29, to: today)
        case .quarter: firstDay = calendar.date(byAdding: .month, value: -3, to: today)
            .flatMap { calendar.date(byAdding: .day, value: 1, to: $0) }
        case .year: firstDay = calendar.date(byAdding: .year, value: -1, to: today)
            .flatMap { calendar.date(byAdding: .day, value: 1, to: $0) }
        }
        guard let firstDay,
              let count = calendar.dateComponents([.day], from: firstDay, to: today).day else { return [today] }
        return (0...count).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
    }

    func summary(for range: ProgressRange, asOf date: Date = .now) -> RangeSummary {
        summary(days: days(in: range, asOf: date))
    }

    /// 柱状图数据：7D/30D 每天一根，3M 每周一根，1Y 每月一根。`date` 是这一段的第一天。
    func chartBars(for range: ProgressRange, asOf date: Date = .now) -> [DaySummary] {
        let days = summary(for: range, asOf: date).days
        guard range.barUnit != .day else { return days }
        var bars: [DaySummary] = []
        for day in days {
            let start = calendar.dateInterval(of: range.barUnit, for: day.date)?.start ?? day.date
            if let last = bars.last, last.date == start {
                bars[bars.count - 1] = DaySummary(date: start, sessions: last.sessions + day.sessions,
                                                  seconds: last.seconds + day.seconds)
            } else {
                bars.append(DaySummary(date: start, sessions: day.sessions, seconds: day.seconds))
            }
        }
        return bars
    }

    /// 按完成时间从新到旧排列的记录，供完成记录列表使用。
    var recentSessions: [SessionSummary] { completedSessions.reversed() }
}

extension Calendar {
    /// 周一为一周开始、英文区域格式，与界面语言一致。
    static var controlDefault: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }
}
