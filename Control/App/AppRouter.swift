import Foundation
import Observation

/// 导航状态：当前 Tab 和训练流程走到哪一步。不负责计时（由 TrainingEngine 负责）。
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

    var selectedTab: Tab = .home
    private(set) var trainingStep: TrainingStep?

    let store: SessionStore
    let template: TrainingTemplate?
    /// 仅开发版允许启动未经审核的演示模板。
    let allowsDemoTemplates: Bool

    init(
        store: SessionStore = SessionStore(),
        template: TrainingTemplate? = .demoStandard,
        allowsDemoTemplates: Bool = AppRouter.isDebugBuild
    ) {
        self.store = store
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

    /// 唯一的训练入口守卫。所有开始训练的入口都必须经过这里。
    /// 成年确认、安全筛查、基础教学等条件在 Iteration 3 加入。
    func trainingGate() -> GateResult {
        if store.trainingHold {
            return .blocked(reason: "Please stop training and seek professional guidance if symptoms persist.")
        }
        guard let template, template.isApprovedForRelease || allowsDemoTemplates else {
            return .blocked(reason: "Training is not available yet.")
        }
        return .allowed
    }

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

    /// 完成页的 Save & Continue。只在完成页生效，连点也只保存一次。
    func saveAndContinue(feedback: SessionFeedback) {
        guard case .sessionComplete(let summary) = trainingStep else { return }
        store.saveFeedback(feedback, for: summary.id)
        trainingStep = nil
        selectedTab = .home
    }
}
