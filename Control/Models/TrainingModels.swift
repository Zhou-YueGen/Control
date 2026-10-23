import Foundation

/// 训练节奏配置。只描述节奏，不包含医学处方。
struct TrainingTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let contractionSeconds: Int
    let relaxationSeconds: Int
    let repetitions: Int
    let contentReviewVersion: String
    /// 只有经过专业审核的模板才能在正式版中启动。
    let isApprovedForRelease: Bool

    var cycleSeconds: Int { contractionSeconds + relaxationSeconds }
    var totalSeconds: Int { cycleSeconds * repetitions }
}

/// 一次正常完成的训练，数据全部来自 TrainingEngine。
struct SessionSummary: Identifiable, Equatable, Hashable {
    let id: UUID
    let templateID: String
    let templateTitle: String
    let activeDurationSeconds: Int
    let completedRepetitions: Int
    let totalRepetitions: Int
    let completedAt: Date
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case comfortable = "Comfortable"
    case challenging = "Challenging"
    case tooHard = "Too hard"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .easy: "leaf"
        case .comfortable: "face.smiling"
        case .challenging: "flame"
        case .tooHard: "exclamationmark.circle"
        }
    }
}

enum DiscomfortAnswer: String, CaseIterable, Identifiable {
    case no = "No"
    case yes = "Yes"
    case preferNotToSay = "Prefer not to say"

    var id: Self { self }
}

/// 用户自行填写的主观反馈，两项都可以为空。
struct SessionFeedback: Equatable {
    var difficulty: Difficulty?
    var discomfort: DiscomfortAnswer?
}
