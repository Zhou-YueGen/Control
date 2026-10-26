import SwiftUI

/// 首次引导导航：Welcome → Goal → Safety Check → Learn Basics（或 Safety Notice）。
/// 起始页面由保存的 `onboardingStep` 决定，中断后回到未完成的那一步。
struct OnboardingFlowView: View {
    let router: AppRouter

    enum Route: Hashable {
        case goals
        case safetyCheck
        case safetyNotice(SafetyScreening.Reason)
        case learnBasics
    }

    @State private var path: [Route]

    init(router: AppRouter) {
        self.router = router
        _path = State(initialValue: Self.initialPath(for: router.preferences))
    }

    private var preferences: PreferencesStore { router.preferences }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                router.completeWelcome()
                path = [.goals]
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
        .tint(.white)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .goals:
            GoalSelectionView(initialGoal: preferences.primaryGoal) { goal in
                router.selectGoal(goal)
                path.append(.safetyCheck)
            }
        case .safetyCheck:
            SafetyCheckView { answers in
                switch router.submitSafety(answers: answers) {
                case .learnBasics: path.append(.learnBasics)
                case .educationOnly(let reason): path = [.safetyNotice(reason)]
                }
            }
        case .safetyNotice(let reason):
            SafetyNoticeView(reason: reason, onAcknowledge: router.acknowledgeSafetyNotice)
        case .learnBasics:
            LearnBasicsView(onComplete: router.completeBasics)
        }
    }

    /// 逐题答案不保存，所以恢复到提示页时只能根据成年确认区分原因。
    static func initialPath(for preferences: PreferencesStore) -> [Route] {
        switch preferences.onboardingStep {
        case .welcome, .finished: []
        case .goals: [.goals]
        case .safetyCheck: [.goals, .safetyCheck]
        case .safetyNotice: [.safetyNotice(preferences.adultConfirmed ? .riskAnswer : .underage)]
        case .learnBasics: [.goals, .safetyCheck, .learnBasics]
        }
    }
}

#Preview("Onboarding") {
    OnboardingFlowView(router: AppRouter())
}
