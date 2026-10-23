import Foundation
import Observation

/// 本次运行期间的训练记录、反馈与偏好。只保存在内存中，关闭 App 后清空。
/// Home 和以后的 Progress 都从这里读取统计，保证数字只有一个来源。
@Observable
final class SessionStore {
    private(set) var completedSessions: [SessionSummary] = []
    private(set) var feedbackBySession: [UUID: SessionFeedback] = [:]

    /// 用户报告不适后为 true，之后所有训练入口都被阻止。
    private(set) var trainingHold = false
    var soundEnabled = true
    var hapticsEnabled = true

    let calendar: Calendar

    init(calendar: Calendar = .controlDefault) {
        self.calendar = calendar
    }

    // MARK: - Writes

    /// 记录一次正常完成的训练。同一个 id 只会记录一次。
    func recordCompleted(_ summary: SessionSummary) {
        guard !completedSessions.contains(where: { $0.id == summary.id }) else { return }
        completedSessions.append(summary)
    }

    /// 按 session id 覆盖保存反馈；报告不适时设置 trainingHold。
    func saveFeedback(_ feedback: SessionFeedback, for sessionID: UUID) {
        guard completedSessions.contains(where: { $0.id == sessionID }) else { return }
        feedbackBySession[sessionID] = feedback
        if feedback.discomfort == .yes {
            trainingHold = true
        }
    }

    // MARK: - Statistics

    var totalSessions: Int { completedSessions.count }

    var totalSeconds: Int { completedSessions.reduce(0) { $0 + $1.activeDurationSeconds } }

    /// 累计分钟数，按四舍五入取整。
    var totalMinutes: Int { Int((Double(totalSeconds) / 60).rounded()) }

    private var trainingDays: Set<Date> {
        Set(completedSessions.map { calendar.startOfDay(for: $0.completedAt) })
    }

    func hasSession(on day: Date) -> Bool {
        trainingDays.contains(calendar.startOfDay(for: day))
    }

    func week(containing date: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    func trainingDaysCount(inWeekContaining date: Date) -> Int {
        week(containing: date).filter(hasSession(on:)).count
    }

    func sessionsCount(on day: Date) -> Int {
        completedSessions.filter { calendar.isDate($0.completedAt, inSameDayAs: day) }.count
    }

    /// 从今天（今天还没练则从昨天）向前连续的训练日数量。
    func currentStreak(asOf date: Date = .now) -> Int {
        let days = trainingDays
        var cursor = calendar.startOfDay(for: date)
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
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
