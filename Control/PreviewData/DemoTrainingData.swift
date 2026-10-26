import Foundation

/// 演示用训练参数与预览数据。
/// DEMO / NOT CLINICALLY REVIEWED：只用于界面开发，不是健康建议，也不能用于正式发布。
extension TrainingTemplate {
    static let demoStandard = TrainingTemplate(
        id: "demo-standard",
        title: "Standard Session",
        subtitle: "Slow contractions",
        contractionSeconds: 4,
        relaxationSeconds: 4,
        repetitions: 8,
        contentReviewVersion: "demo",
        isApprovedForRelease: false
    )

    /// UI 自动化测试使用的极短节奏。
    static let uiTestFast = TrainingTemplate(
        id: "ui-test-fast",
        title: "Standard Session",
        subtitle: "Slow contractions",
        contractionSeconds: 2,
        relaxationSeconds: 2,
        repetitions: 2,
        contentReviewVersion: "demo",
        isApprovedForRelease: false
    )
}

extension SessionSummary {
    static let preview = SessionSummary(
        id: UUID(uuidString: "6F1C2C1A-8D7C-4E35-9A5E-2B1D0C9E7F11")!,
        templateID: TrainingTemplate.demoStandard.id,
        templateTitle: TrainingTemplate.demoStandard.title,
        activeDurationSeconds: TrainingTemplate.demoStandard.totalSeconds,
        completedRepetitions: 8,
        totalRepetitions: 8,
        completedAt: .now
    )
}

extension SessionStore {
    /// Preview-only：带一条完成记录的 Store。
    static func previewWithSession() -> SessionStore {
        let store = SessionStore()
        store.recordCompleted(.preview)
        return store
    }
}

extension AppRouter {
    /// Preview-only：已完成首次引导、可以开始训练的 Router。
    static func previewOnboarded() -> AppRouter {
        let preferences = PreferencesStore.inMemory()
        preferences.markOnboardingDoneForTesting()
        return AppRouter(preferences: preferences)
    }
}
