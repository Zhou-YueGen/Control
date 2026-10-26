import Foundation
import SwiftData

/// 本地保存的一次完成训练及其主观反馈。反馈按 session id 原地更新，不另建表。
@Model
final class StoredSession {
    @Attribute(.unique) var id: UUID
    var templateID: String
    var templateTitle: String
    var activeDurationSeconds: Int
    var completedRepetitions: Int
    var totalRepetitions: Int
    var completedAt: Date
    /// 完成时按当地日历生成的日期（如 2026-10-23），跨时区后历史打卡不会移到别的日期。
    var localDayKey: String
    var difficulty: String?
    var discomfort: String?

    init(summary: SessionSummary, localDayKey: String) {
        id = summary.id
        templateID = summary.templateID
        templateTitle = summary.templateTitle
        activeDurationSeconds = summary.activeDurationSeconds
        completedRepetitions = summary.completedRepetitions
        totalRepetitions = summary.totalRepetitions
        completedAt = summary.completedAt
        self.localDayKey = localDayKey
    }

    var summary: SessionSummary {
        SessionSummary(
            id: id,
            templateID: templateID,
            templateTitle: templateTitle,
            activeDurationSeconds: activeDurationSeconds,
            completedRepetitions: completedRepetitions,
            totalRepetitions: totalRepetitions,
            completedAt: completedAt
        )
    }

    /// 两项都没填时为 nil，表示用户没有保存过反馈。
    var feedback: SessionFeedback? {
        guard difficulty != nil || discomfort != nil else { return nil }
        return SessionFeedback(
            difficulty: difficulty.flatMap(Difficulty.init(rawValue:)),
            discomfort: discomfort.flatMap(DiscomfortAnswer.init(rawValue:))
        )
    }

    func apply(_ feedback: SessionFeedback) {
        difficulty = feedback.difficulty?.rawValue
        discomfort = feedback.discomfort?.rawValue
    }
}

extension ModelContainer {
    /// 只存在内存中的数据库，用于 Preview 和单元测试。
    static func controlInMemory() -> ModelContainer {
        let configuration = ModelConfiguration(schema: Schema([StoredSession.self]), isStoredInMemoryOnly: true)
        return try! ModelContainer(for: StoredSession.self, configurations: configuration)
    }
}
