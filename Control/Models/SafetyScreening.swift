import Foundation

enum SafetyAnswer: String, CaseIterable, Identifiable {
    case no = "No"
    case yes = "Yes"
    case preferNotToSay = "Prefer not to say"

    var id: String { rawValue }
}

struct SafetyQuestion: Identifiable, Equatable {
    let id: String
    let text: String
    let options: [SafetyAnswer]
}

/// 首次安全筛查（USER_FLOW 3.4）。这是保守的非诊断分流初稿，问题和规则上线前需临床审核。
/// 逐题答案只在本次筛查期间存在于内存，提交后只保存最终状态。
enum SafetyScreening {
    static let ageQuestion = SafetyQuestion(id: "age", text: "Are you 18 years or older?", options: [.no, .yes])

    static let riskQuestions = [
        SafetyQuestion(id: "pain", text: "Do you currently have pelvic pain?", options: SafetyAnswer.allCases),
        SafetyQuestion(id: "urination", text: "Do you have difficulty urinating?", options: SafetyAnswer.allCases),
        SafetyQuestion(id: "surgery", text: "Have you had prostate or other pelvic surgery?", options: SafetyAnswer.allCases),
        SafetyQuestion(id: "condition",
                       text: "Have you been diagnosed with a condition, or advised to avoid these exercises?",
                       options: SafetyAnswer.allCases),
    ]

    static var allQuestions: [SafetyQuestion] { [ageQuestion] + riskQuestions }

    enum Reason: String, Equatable {
        case underage
        case riskAnswer
        case recoveryGoal
    }

    enum Outcome: Equatable {
        case learnBasics
        case educationOnly(Reason)
    }

    static func isComplete(_ answers: [SafetyQuestion.ID: SafetyAnswer]) -> Bool {
        allQuestions.allSatisfy { answers[$0.id] != nil }
    }

    /// 未答、Yes、Prefer not to say 一律按保守分支处理。
    static func evaluate(answers: [SafetyQuestion.ID: SafetyAnswer], goal: Goal?) -> Outcome {
        guard answers[ageQuestion.id] == .yes else { return .educationOnly(.underage) }
        guard riskQuestions.allSatisfy({ answers[$0.id] == .no }) else { return .educationOnly(.riskAnswer) }
        guard let goal, !goal.isEducationOnly else { return .educationOnly(.recoveryGoal) }
        return .learnBasics
    }
}
