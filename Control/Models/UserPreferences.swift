import Foundation
import Observation

/// 首次引导中用户选择的主要目标（USER_FLOW 2.1）。
enum Goal: String, CaseIterable, Identifiable {
    case improveControl
    case betterPerformance
    case generalPelvicHealth
    case recoveryInformation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .improveControl: "Improve control"
        case .betterPerformance: "Better performance"
        case .generalPelvicHealth: "General pelvic health"
        case .recoveryInformation: "Recovery information"
        }
    }

    var subtitle: String {
        switch self {
        case .improveControl: "Learn to contract and fully relax"
        case .betterPerformance: "Build a steady practice habit"
        case .generalPelvicHealth: "Understand your pelvic floor"
        case .recoveryInformation: "Education only · talk to your care team"
        }
    }

    var systemImage: String {
        switch self {
        case .improveControl: "bolt.fill"
        case .betterPerformance: "chart.bar.fill"
        case .generalPelvicHealth: "heart.fill"
        case .recoveryInformation: "cross.case.fill"
        }
    }

    /// 只提供教育内容，不进入通用训练。
    var isEducationOnly: Bool { self == .recoveryInformation }
}

/// 引导进度。`safetyNotice` 用于在提示页中断后回到同一页，而不是重新答题。
enum OnboardingStep: String {
    case welcome, goals, safetyCheck, safetyNotice, learnBasics, finished
}

/// 安全分流结果。`noPredefinedFlag` 只表示未触发预设规则，不是医学上的训练适宜性确认。
enum SafetyAccessStatus: String {
    case notScreened
    case noPredefinedFlag
    case educationOnly
}

/// 引导状态、训练锁和训练偏好，保存在 UserDefaults 中，重启 App 后依然有效。
/// 不保存安全问卷的逐题答案。
@Observable
final class PreferencesStore {
    private enum Key {
        static let adultConfirmed = "prefs.adultConfirmed"
        static let primaryGoal = "prefs.primaryGoal"
        static let onboardingStep = "prefs.onboardingStep"
        static let onboardingCompleted = "prefs.onboardingCompleted"
        static let basicEducationCompleted = "prefs.basicEducationCompleted"
        static let safetyAccessStatus = "prefs.safetyAccessStatus"
        static let trainingHold = "prefs.trainingHold"
        static let soundEnabled = "prefs.soundEnabled"
        static let hapticsEnabled = "prefs.hapticsEnabled"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var adultConfirmed: Bool {
        didSet { defaults.set(adultConfirmed, forKey: Key.adultConfirmed) }
    }
    var primaryGoal: Goal? {
        didSet { defaults.set(primaryGoal?.rawValue, forKey: Key.primaryGoal) }
    }
    var onboardingStep: OnboardingStep {
        didSet { defaults.set(onboardingStep.rawValue, forKey: Key.onboardingStep) }
    }
    var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) }
    }
    var basicEducationCompleted: Bool {
        didSet { defaults.set(basicEducationCompleted, forKey: Key.basicEducationCompleted) }
    }
    var safetyAccessStatus: SafetyAccessStatus {
        didSet { defaults.set(safetyAccessStatus.rawValue, forKey: Key.safetyAccessStatus) }
    }
    /// 用户报告不适后为 true，之后所有训练入口都被阻止。
    var trainingHold: Bool {
        didSet { defaults.set(trainingHold, forKey: Key.trainingHold) }
    }
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) }
    }
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        adultConfirmed = defaults.bool(forKey: Key.adultConfirmed)
        primaryGoal = defaults.string(forKey: Key.primaryGoal).flatMap(Goal.init(rawValue:))
        onboardingStep = defaults.string(forKey: Key.onboardingStep).flatMap(OnboardingStep.init(rawValue:)) ?? .welcome
        onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
        basicEducationCompleted = defaults.bool(forKey: Key.basicEducationCompleted)
        safetyAccessStatus = defaults.string(forKey: Key.safetyAccessStatus)
            .flatMap(SafetyAccessStatus.init(rawValue:)) ?? .notScreened
        trainingHold = defaults.bool(forKey: Key.trainingHold)
        soundEnabled = defaults.object(forKey: Key.soundEnabled) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true
    }

    /// 不写入磁盘的实例，用于 Preview 和单元测试。
    static func inMemory() -> PreferencesStore {
        let suite = "control.inMemory.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return PreferencesStore(defaults: defaults)
    }

    /// Delete All Data：引导、安全状态、训练锁和设置全部恢复为新安装时的状态。
    func resetAll() {
        adultConfirmed = false
        primaryGoal = nil
        safetyAccessStatus = .notScreened
        basicEducationCompleted = false
        trainingHold = false
        soundEnabled = true
        hapticsEnabled = true
        onboardingStep = .welcome
        onboardingCompleted = false
    }

    /// 已完成引导、可以训练的状态，用于 Preview 和 UI 测试。
    func markOnboardingDoneForTesting() {
        adultConfirmed = true
        primaryGoal = .improveControl
        safetyAccessStatus = .noPredefinedFlag
        basicEducationCompleted = true
        onboardingCompleted = true
        onboardingStep = .finished
    }
}
