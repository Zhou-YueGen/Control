import Foundation
import Observation

/// 训练状态机：idle → preparing → contract ⇄ relax → completed，随时可 paused，用户退出为 cancelled。
///
/// 经过时长 = 已累计时长 + (当前单调时钟 - 本次运行起点)。
/// 不依赖刷新回调的次数，所以暂停、后台、卡顿都不会让时间算错。
/// 页面只读取这里的状态并调用 start / pause / resume / cancel。
@Observable
final class TrainingEngine {
    enum Phase: Equatable {
        case preparing
        case contract
        case relax
    }

    enum Status: Equatable {
        case idle
        case running
        case paused
        case completed
        case cancelled
    }

    /// 某一经过时长下的训练进度，由纯函数 `snapshot(elapsed:)` 计算。
    struct Snapshot: Equatable {
        var phase: Phase
        var phaseRemaining: TimeInterval
        var phaseProgress: Double
        var completedRepetitions: Int
        var currentRepetition: Int
        var trainingElapsed: TimeInterval
        var isFinished: Bool
    }

    let template: TrainingTemplate
    let preparationSeconds: TimeInterval

    private(set) var status: Status = .idle
    private(set) var phase: Phase = .preparing
    private(set) var phaseRemaining: TimeInterval
    private(set) var phaseProgress: Double = 0
    private(set) var completedRepetitions = 0
    private(set) var currentRepetition = 1
    /// 不含准备阶段和暂停时间的有效训练时长。
    private(set) var trainingElapsed: TimeInterval = 0
    /// 每次进入新阶段 +1，用于触发声音、振动和 VoiceOver 播报。
    private(set) var phaseCueCount = 0

    @ObservationIgnored private let uptime: () -> TimeInterval
    @ObservationIgnored private var accumulatedElapsed: TimeInterval = 0
    @ObservationIgnored private var runningSince: TimeInterval?
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var lastCueKey: CueKey?

    private struct CueKey: Equatable {
        let repetition: Int
        let phase: Phase
    }

    init(
        template: TrainingTemplate,
        preparationSeconds: TimeInterval = 3,
        uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.template = template
        self.preparationSeconds = preparationSeconds
        self.uptime = uptime
        self.phaseRemaining = preparationSeconds
    }

    // MARK: - Derived values

    var trainingDuration: TimeInterval { TimeInterval(template.totalSeconds) }
    var totalRemainingSeconds: Int { Int(max(trainingDuration - trainingElapsed, 0).rounded(.up)) }
    var phaseRemainingSeconds: Int { Int(phaseRemaining.rounded(.up)) }
    var isActive: Bool { status == .running || status == .paused }

    // MARK: - Controls

    func start() {
        guard status == .idle else { return }
        accumulatedElapsed = 0
        runningSince = uptime()
        status = .running
        refresh()
        startTicker()
    }

    func pause() {
        guard status == .running else { return }
        refresh()
        guard status == .running else { return }
        accumulatedElapsed = currentElapsed()
        runningSince = nil
        status = .paused
        stopTicker()
        refresh()
    }

    func resume() {
        guard status == .paused else { return }
        runningSince = uptime()
        status = .running
        refresh()
        startTicker()
    }

    func togglePause() {
        switch status {
        case .idle: start()
        case .running: pause()
        case .paused: resume()
        case .completed, .cancelled: break
        }
    }

    /// 用户确认提前结束。不会被记为完成。
    func cancel() {
        guard isActive else { return }
        accumulatedElapsed = currentElapsed()
        runningSince = nil
        status = .cancelled
        stopTicker()
    }

    /// 页面消失时调用，确保不会留下仍在运行的计时任务。
    func stop() {
        cancel()
        stopTicker()
    }

    /// 正常完成后生成摘要；未完成时返回 nil。
    func makeSummary(id: UUID, completedAt: Date = .now) -> SessionSummary? {
        guard status == .completed else { return nil }
        return SessionSummary(
            id: id,
            templateID: template.id,
            templateTitle: template.title,
            activeDurationSeconds: Int(trainingElapsed.rounded()),
            completedRepetitions: completedRepetitions,
            totalRepetitions: template.repetitions,
            completedAt: completedAt
        )
    }

    // MARK: - Timing

    /// 按当前时钟重新计算状态。计时任务定期调用；测试中可以手动调用。
    func refresh() {
        guard isActive else { return }

        let snapshot = snapshot(elapsed: currentElapsed())
        phase = snapshot.phase
        phaseRemaining = snapshot.phaseRemaining
        phaseProgress = snapshot.phaseProgress
        completedRepetitions = snapshot.completedRepetitions
        currentRepetition = snapshot.currentRepetition
        trainingElapsed = snapshot.trainingElapsed

        if snapshot.isFinished {
            accumulatedElapsed = preparationSeconds + trainingDuration
            runningSince = nil
            status = .completed
            stopTicker()
            return
        }

        let cueKey = CueKey(repetition: snapshot.currentRepetition, phase: snapshot.phase)
        if status == .running, cueKey != lastCueKey {
            lastCueKey = cueKey
            phaseCueCount += 1
        }
    }

    func snapshot(elapsed: TimeInterval) -> Snapshot {
        let elapsed = max(elapsed, 0)

        if elapsed < preparationSeconds {
            return Snapshot(
                phase: .preparing,
                phaseRemaining: preparationSeconds - elapsed,
                phaseProgress: preparationSeconds > 0 ? elapsed / preparationSeconds : 1,
                completedRepetitions: 0,
                currentRepetition: 1,
                trainingElapsed: 0,
                isFinished: false
            )
        }

        let contract = TimeInterval(template.contractionSeconds)
        let relax = TimeInterval(template.relaxationSeconds)
        let cycle = contract + relax
        let training = min(elapsed - preparationSeconds, trainingDuration)

        guard cycle > 0, training < trainingDuration else {
            return Snapshot(
                phase: .relax,
                phaseRemaining: 0,
                phaseProgress: 1,
                completedRepetitions: template.repetitions,
                currentRepetition: max(template.repetitions, 1),
                trainingElapsed: trainingDuration,
                isFinished: true
            )
        }

        let completed = Int(training / cycle)
        let offset = training - TimeInterval(completed) * cycle
        let isContract = offset < contract
        let phaseLength = isContract ? contract : relax
        let phaseElapsed = isContract ? offset : offset - contract

        return Snapshot(
            phase: isContract ? .contract : .relax,
            phaseRemaining: max(phaseLength - phaseElapsed, 0),
            phaseProgress: phaseLength > 0 ? phaseElapsed / phaseLength : 1,
            completedRepetitions: completed,
            currentRepetition: completed + 1,
            trainingElapsed: training,
            isFinished: false
        )
    }

    private func currentElapsed() -> TimeInterval {
        guard let runningSince else { return accumulatedElapsed }
        return accumulatedElapsed + max(uptime() - runningSince, 0)
    }

    private func startTicker() {
        stopTicker()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                guard let self, !Task.isCancelled else { return }
                self.refresh()
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }
}
