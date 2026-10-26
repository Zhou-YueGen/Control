import SwiftUI

/// 全屏训练页（参考图第 5 屏）。计时与状态全部来自 TrainingEngine，页面只负责显示和转发操作。
struct TrainingView: View {
    @Bindable var preferences: PreferencesStore
    let sessionID: UUID
    var onCompleted: (SessionSummary) -> Void
    var onExit: () -> Void

    @State private var engine: TrainingEngine
    @State private var voiceGuide = VoiceGuide()
    @State private var isShowingEndConfirmation = false
    @Environment(\.scenePhase) private var scenePhase

    init(
        template: TrainingTemplate,
        preferences: PreferencesStore,
        sessionID: UUID,
        onCompleted: @escaping (SessionSummary) -> Void,
        onExit: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.sessionID = sessionID
        self.onCompleted = onCompleted
        self.onExit = onExit
        _engine = State(initialValue: TrainingEngine(template: template))
    }

    private var template: TrainingTemplate { engine.template }

    /// 阶段开始时播报阶段名，之后每秒播报剩余秒数。
    private var currentPhaseLength: Int {
        switch engine.phase {
        case .preparing: Int(engine.preparationSeconds)
        case .contract: template.contractionSeconds
        case .relax: template.relaxationSeconds
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let ringSize = min(max(min(geometry.size.width * 0.74, geometry.size.height * 0.42), 220), 300)

            ScrollView {
                VStack(spacing: 0) {
                    topBar

                    Spacer(minLength: ControlSpacing.space5)

                    ring
                        .frame(width: ringSize, height: ringSize)

                    GuidanceWaveView(openness: waveOpenness)
                        .padding(.top, ControlSpacing.space4)
                        .animation(.easeInOut(duration: 0.3), value: engine.status)

                    guidanceText
                        .padding(.top, ControlSpacing.space3)

                    Spacer(minLength: ControlSpacing.space5)

                    SessionControlBar(
                        completedText: "\(engine.completedRepetitions)/\(template.repetitions)",
                        remainingText: clock(engine.totalRemainingSeconds),
                        primarySystemImage: engine.status == .running ? "pause.fill" : "play.fill",
                        primaryTitle: primaryControlTitle,
                        isPrimaryEnabled: engine.status == .idle || engine.isActive,
                        onPrimary: engine.togglePause
                    )
                }
                .padding(.horizontal, ControlSpacing.screenHorizontal)
                .padding(.bottom, ControlSpacing.space4)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(ControlGradientBackground(theme: .training))
        .onChange(of: engine.status) { _, newStatus in
            if newStatus != .running { voiceGuide.stop() }
            if newStatus == .completed, let summary = engine.makeSummary(id: sessionID) {
                onCompleted(summary)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { engine.pause() }
        }
        .onChange(of: engine.phaseCueCount) {
            if preferences.soundEnabled {
                voiceGuide.announce(engine.phase)
            } else {
                AccessibilityNotification.Announcement(phaseTitle).post()
            }
        }
        .onChange(of: engine.phaseRemainingSeconds) { _, seconds in
            guard preferences.soundEnabled, engine.status == .running, seconds < currentPhaseLength else { return }
            voiceGuide.count(seconds)
        }
        .onChange(of: preferences.soundEnabled) { _, isEnabled in
            if !isEnabled { voiceGuide.stop() }
        }
        .sensoryFeedback(trigger: engine.phaseCueCount) { _, _ in
            preferences.hapticsEnabled ? .impact(weight: .medium) : nil
        }
        .onDisappear {
            engine.stop()
            voiceGuide.stop()
        }
        .alert("End session?", isPresented: $isShowingEndConfirmation) {
            Button("Continue training", role: .cancel) {}
            Button("End session", role: .destructive) {
                engine.cancel()
                onExit()
            }
        } message: {
            Text("Your current session won't count as completed.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 0) {
            HStack {
                iconButton("chevron.left", label: engine.status == .idle ? "Back" : "End session") {
                    if engine.status == .idle { onExit() } else { requestEnd() }
                }
                .accessibilityIdentifier("trainingBackButton")
                Spacer(minLength: 0)
            }
            .frame(width: ControlSpacing.hitTargetMin * 2)

            VStack(spacing: 2) {
                Text(template.title)
                    .font(ControlTypography.cardTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkOnDarkMuted)
                    .monospacedDigit()
                    .accessibilityIdentifier("trainingSubtitle")
            }
            .foregroundStyle(ControlColors.inkOnDark)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                iconButton(preferences.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                           label: "Sound guidance", value: preferences.soundEnabled ? "On" : "Off") {
                    preferences.soundEnabled.toggle()
                }
                iconButton(preferences.hapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                           label: "Haptic feedback", value: preferences.hapticsEnabled ? "On" : "Off") {
                    preferences.hapticsEnabled.toggle()
                }
            }
            .frame(width: ControlSpacing.hitTargetMin * 2)
        }
        .padding(.top, ControlSpacing.space2)
    }

    private var subtitle: String {
        let demo = template.isApprovedForRelease ? "" : " · Demo"
        switch engine.status {
        case .idle, .completed, .cancelled:
            return "\(template.subtitle)\(demo)"
        case .running, .paused:
            if engine.phase == .preparing { return "Get ready\(demo)" }
            return "Rep \(engine.currentRepetition) of \(template.repetitions)\(demo)"
        }
    }

    private func iconButton(_ systemImage: String, label: String, value: String? = nil,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(ControlColors.inkOnDark)
                .frame(width: ControlSpacing.hitTargetMin, height: ControlSpacing.hitTargetMin)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityValue(value ?? "")
    }

    // MARK: - Ring

    private var ringProgress: Double {
        switch engine.status {
        case .idle, .cancelled: 0
        case .completed: 1
        case .running, .paused:
            switch engine.phase {
            case .preparing, .contract: engine.phaseProgress
            case .relax: 1 - engine.phaseProgress
            }
        }
    }

    private var ringTint: [Color] {
        switch engine.phase {
        case .preparing: [ControlColors.brandMint.opacity(0.6), ControlColors.brandMint]
        case .contract: [ControlColors.brandMint, ControlColors.brandMid, ControlColors.brandDeep]
        case .relax: [ControlColors.brandMint.opacity(0.7), ControlColors.brandMint]
        }
    }

    private var phaseTitle: String {
        switch engine.status {
        case .idle: "Ready"
        case .paused: "Paused"
        case .completed: "Complete"
        case .cancelled: "Ended"
        case .running:
            switch engine.phase {
            case .preparing: "Get ready"
            case .contract: "Contract"
            case .relax: "Relax"
            }
        }
    }

    private var phaseSymbol: String {
        if engine.status == .paused { return "pause.fill" }
        switch engine.phase {
        case .preparing: return "timer"
        case .contract: return "arrow.down.right.and.arrow.up.left"
        case .relax: return "arrow.up.left.and.arrow.down.right"
        }
    }

    private var ring: some View {
        TrainingCountdownRing(progress: ringProgress, tint: ringTint, isDimmed: engine.status == .paused) {
            VStack(spacing: ControlSpacing.space1) {
                if engine.status == .idle {
                    Text("Ready")
                        .font(ControlTypography.cardTitle)
                        .foregroundStyle(ControlColors.brandDeep)
                    Text(clock(template.totalSeconds))
                        .font(ControlTypography.timerNumber(size: 56))
                        .foregroundStyle(ControlColors.inkPrimary)
                    Text("total time")
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkSecondary)
                } else {
                    Label(phaseTitle, systemImage: phaseSymbol)
                        .font(ControlTypography.cardTitle)
                        .foregroundStyle(engine.status == .paused ? ControlColors.inkSecondary : ControlColors.brandDeep)
                        .accessibilityIdentifier("trainingPhaseLabel")
                    Text("\(engine.phaseRemainingSeconds)")
                        .font(ControlTypography.timerNumber())
                        .foregroundStyle(ControlColors.inkPrimary)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy, value: engine.phaseRemainingSeconds)
                    Text(engine.phaseRemainingSeconds == 1 ? "second" : "seconds")
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
        }
        .animation(.easeInOut(duration: 0.3), value: engine.phase)
        .animation(.easeInOut(duration: 0.3), value: engine.status)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ringAccessibilityLabel)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var ringAccessibilityLabel: String {
        switch engine.status {
        case .idle:
            "Ready. Total time \(clock(template.totalSeconds))."
        case .running, .paused:
            "\(phaseTitle). \(engine.phaseRemainingSeconds) seconds remaining."
        case .completed, .cancelled:
            phaseTitle
        }
    }

    // MARK: - Guidance

    private var waveOpenness: Double {
        guard engine.isActive else { return 1 }
        switch engine.phase {
        case .preparing: return 1
        case .contract: return 1 - engine.phaseProgress
        case .relax: return engine.phaseProgress
        }
    }

    private var guidanceLine: String {
        switch engine.status {
        case .idle: "Find a comfortable position. Tap Start when you're ready."
        case .paused: "Paused. Resume when you're ready."
        case .completed, .cancelled: "Take a moment before you continue."
        case .running:
            switch engine.phase {
            case .preparing: "Get comfortable and breathe normally."
            case .contract: "Gently contract your pelvic floor. Keep breathing normally."
            case .relax: "Release fully and keep breathing."
            }
        }
    }

    private var guidanceText: some View {
        VStack(spacing: ControlSpacing.space1) {
            Text(guidanceLine)
                .font(ControlTypography.body.weight(.medium))
                .foregroundStyle(ControlColors.inkPrimary)
                .accessibilityIdentifier("trainingGuidance")
            Text("Visual guide only · Stop if you feel pain or discomfort.")
                .font(ControlTypography.caption)
                .foregroundStyle(ControlColors.inkSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private var primaryControlTitle: String {
        switch engine.status {
        case .idle: "Start"
        case .running: "Pause"
        case .paused: "Resume"
        case .completed, .cancelled: "Done"
        }
    }

    /// 先暂停再询问，确认框显示期间时间不会继续流逝。
    private func requestEnd() {
        guard engine.isActive else { return }
        engine.pause()
        if engine.status == .paused {
            isShowingEndConfirmation = true
        }
    }

    private func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview("Training") {
    TrainingView(template: .demoStandard, preferences: .inMemory(), sessionID: UUID(),
                 onCompleted: { _ in }, onExit: {})
}
