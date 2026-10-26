import Foundation
import Observation

/// 导航状态：首次引导进度、当前 Tab 和训练流程走到哪一步。不负责计时（由 TrainingEngine 负责）。
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case home, learn, train, progress, settings
    }

    enum TrainingStep: Equatable {
        /// 每次开始都有新的 id，保证训练页拿到全新的 TrainingEngine。
        case training(sessionID: UUID)
        case sessionComplete(SessionSummary)
    }

    enum GateResult: Equatable {
        case allowed
        case blocked(reason: String)
    }

    enum GateMessage {
        static let adultsOnly = "Training is for adults 18+."
        static let safetyCheckNeeded = "Complete the safety check first."
        static let educationOnly = "Training isn't available based on your answers. You can explore educational content."
        static let basicsNeeded = "Learn the basics before starting."
        static let hold = "Please stop training and seek professional guidance if symptoms persist."
        static let noTemplate = "Training is not available yet."
    }

    var selectedTab: Tab = .home
    private(set) var trainingStep: TrainingStep?

    let store: SessionStore
    let preferences: PreferencesStore
    let template: TrainingTemplate?
    /// 仅开发版允许启动未经审核的演示模板。
    let allowsDemoTemplates: Bool

    init(
        store: SessionStore = SessionStore(),
        preferences: PreferencesStore = .inMemory(),
        template: TrainingTemplate? = .demoStandard,
        allowsDemoTemplates: Bool = AppRouter.isDebugBuild
    ) {
        self.store = store
        self.preferences = preferences
        self.template = template
        self.allowsDemoTemplates = allowsDemoTemplates
    }

    static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    var isTrainingFlowPresented: Bool { trainingStep != nil }

    // MARK: - Training gate

    /// 唯一的训练入口守卫（USER_FLOW 2.2），按文档表格的顺序检查。所有开始训练的入口都必须经过这里。
    func trainingGate() -> GateResult {
        guard preferences.adultConfirmed else { return .blocked(reason: GateMessage.adultsOnly) }
        switch preferences.safetyAccessStatus {
        case .notScreened: return .blocked(reason: GateMessage.safetyCheckNeeded)
        case .educationOnly: return .blocked(reason: GateMessage.educationOnly)
        case .noPredefinedFlag: break
        }
        guard preferences.basicEducationCompleted, preferences.onboardingCompleted else {
            return .blocked(reason: GateMessage.basicsNeeded)
        }
        if preferences.trainingHold {
            return .blocked(reason: GateMessage.hold)
        }
        guard let template, template.isApprovedForRelease || allowsDemoTemplates else {
            return .blocked(reason: GateMessage.noTemplate)
        }
        return .allowed
    }

    // MARK: - Onboarding

    func completeWelcome() {
        preferences.onboardingStep = .goals
    }

    func selectGoal(_ goal: Goal) {
        preferences.primaryGoal = goal
        preferences.onboardingStep = .safetyCheck
    }

    /// 只保存是否成年和最终分流状态，不保存逐题答案。
    @discardableResult
    func submitSafety(answers: [SafetyQuestion.ID: SafetyAnswer]) -> SafetyScreening.Outcome {
        let outcome = SafetyScreening.evaluate(answers: answers, goal: preferences.primaryGoal)
        preferences.adultConfirmed = answers[SafetyScreening.ageQuestion.id] == .yes
        switch outcome {
        case .learnBasics:
            preferences.safetyAccessStatus = .noPredefinedFlag
            preferences.onboardingStep = .learnBasics
        case .educationOnly:
            preferences.safetyAccessStatus = .educationOnly
            preferences.onboardingStep = .safetyNotice
        }
        return outcome
    }

    /// 教育模式用户确认已阅读安全提示后进入主界面，Basics 仍未完成。
    func acknowledgeSafetyNotice() {
        guard preferences.safetyAccessStatus == .educationOnly else { return }
        preferences.onboardingCompleted = true
        preferences.onboardingStep = .finished
        selectedTab = .home
    }

    func completeBasics() {
        guard preferences.safetyAccessStatus == .noPredefinedFlag else { return }
        preferences.basicEducationCompleted = true
        preferences.onboardingCompleted = true
        preferences.onboardingStep = .finished
        selectedTab = .home
    }

    // MARK: - Data

    /// Settings 的 Delete All Data：删除训练记录与反馈，并把引导和设置恢复为新安装状态，回到 Welcome。
    func deleteAllData() {
        trainingStep = nil
        store.deleteAll()
        preferences.resetAll()
        selectedTab = .home
    }

    // MARK: - Training flow

    /// 通过守卫才开始；训练流程已在进行时忽略重复点击。
    @discardableResult
    func startTraining() -> Bool {
        guard trainingStep == nil, trainingGate() == .allowed else { return false }
        trainingStep = .training(sessionID: UUID())
        return true
    }

    /// 训练正常完成：记录一次并进入完成页。重复调用不会重复记录。
    func finishTraining(with summary: SessionSummary) {
        guard case .training(let sessionID) = trainingStep, summary.id == sessionID else { return }
        store.recordCompleted(summary)
        trainingStep = .sessionComplete(summary)
    }

    /// 还没开始就返回，或确认提前结束。不会产生完成记录。
    func exitTraining() {
        guard case .training = trainingStep else { return }
        trainingStep = nil
        selectedTab = .home
    }

    /// 完成页的 Save & Continue。只在完成页生效，连点也只保存一次；报告不适时设置训练锁。
    func saveAndContinue(feedback: SessionFeedback) {
        guard case .sessionComplete(let summary) = trainingStep else { return }
        if store.saveFeedback(feedback, for: summary.id), feedback.discomfort == .yes {
            preferences.trainingHold = true
        }
        trainingStep = nil
        selectedTab = .home
    }
}
