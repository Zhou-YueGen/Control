import SwiftUI

/// 训练完成页（参考图第 6 屏）。只能在 TrainingEngine 进入 completed 后打开，
/// 进入前训练记录已经保存，反馈是否填写都不影响这条记录。
struct SessionCompleteView: View {
    let summary: SessionSummary
    var onSave: (SessionFeedback) -> Void

    @State private var feedback = SessionFeedback()
    @State private var hasAppeared = false
    @State private var isSaving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: ControlSpacing.space6) {
                Text("Session Complete")
                    .font(ControlTypography.sectionTitle)
                    .foregroundStyle(ControlColors.inkOnDark)
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 1)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, ControlSpacing.space2)

                successBadge

                VStack(spacing: ControlSpacing.space1) {
                    Text("Great job!")
                        .font(ControlTypography.screenTitle)
                        .foregroundStyle(ControlColors.inkPrimary)
                    Text("You completed today's session.")
                        .font(ControlTypography.body)
                        .foregroundStyle(ControlColors.inkSecondary)
                }
                .multilineTextAlignment(.center)
                .accessibilityElement(children: .combine)

                metrics
                difficultySection
                discomfortSection

                if feedback.discomfort == .yes {
                    SafetyNoticeCard(
                        title: "Please stop training for now",
                        message: "Pain or discomfort can have many causes. If it continues, comes back or worries you, consider speaking with a doctor or pelvic health professional. New sessions will be paused."
                    )
                    .accessibilityIdentifier("discomfortSafetyNotice")
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.bottom, ControlSpacing.space6)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: feedback.discomfort)
        }
        .fadesUnderStatusBar()
        .background(ControlGradientBackground(theme: .complete))
        .safeAreaInset(edge: .bottom) {
            PrimaryPillButton(title: "Save & Continue", isLoading: isSaving) {
                guard !isSaving else { return }
                isSaving = true
                onSave(feedback)
            }
            .accessibilityIdentifier("saveAndContinueButton")
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space3)
            .padding(.bottom, ControlSpacing.space2)
            .background(ControlColors.peach.opacity(0.92).ignoresSafeArea())
        }
        .sensoryFeedback(.success, trigger: hasAppeared) { _, newValue in newValue }
        .onAppear {
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) { hasAppeared = true }
            }
        }
    }

    // MARK: - Success badge

    private var successBadge: some View {
        ZStack {
            if !reduceMotion {
                ForEach(0..<10, id: \.self) { index in
                    particle(index)
                }
            }

            Circle()
                .fill(ControlColors.brandMint.opacity(0.28))
                .frame(width: 128, height: 128)
            Circle()
                .fill(LinearGradient(colors: [ControlColors.brandMint, ControlColors.brandDeep],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 96, height: 96)
                .shadow(color: ControlColors.brandDeep.opacity(0.35), radius: 16, y: 8)
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(hasAppeared ? 1 : 0.3)
                .opacity(hasAppeared ? 1 : 0)
        }
        .frame(width: 180, height: 150)
        .accessibilityHidden(true)
    }

    private func particle(_ index: Int) -> some View {
        let angle = Double(index) / 10 * 2 * .pi
        let radius: CGFloat = hasAppeared ? 84 : 40
        let colors = [ControlColors.brandMint, Color.orange.opacity(0.8), ControlColors.lavender, Color.yellow]
        return Circle()
            .fill(colors[index % colors.count])
            .frame(width: index.isMultiple(of: 3) ? 7 : 5, height: index.isMultiple(of: 3) ? 7 : 5)
            .offset(x: cos(angle) * radius, y: sin(angle) * radius * 0.8)
            .opacity(hasAppeared ? 0.9 : 0)
    }

    // MARK: - Metrics

    private var metrics: some View {
        HStack(spacing: ControlSpacing.space3) {
            MetricCard(value: "\(summary.completedRepetitions)", label: "Reps",
                       accessibilityValueText: "\(summary.completedRepetitions) of \(summary.totalRepetitions)")
                .accessibilityIdentifier("completedRepsMetric")
            MetricCard(value: clock(summary.activeDurationSeconds), label: "Practice time",
                       accessibilityValueText: spokenDuration(summary.activeDurationSeconds))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Feedback

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space3) {
            sectionTitle("How did you feel today?", note: "Optional · self-reported")
            DifficultySelector(selection: $feedback.difficulty)
        }
    }

    private var discomfortSection: some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space3) {
            sectionTitle("Did you experience pain or discomfort?", note: "Optional")
            VStack(spacing: ControlSpacing.space2) {
                ForEach(DiscomfortAnswer.allCases) { answer in
                    discomfortRow(answer)
                }
            }
        }
    }

    private func sectionTitle(_ title: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(ControlTypography.cardTitle)
                .foregroundStyle(ControlColors.inkPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(note)
                .font(ControlTypography.caption)
                .foregroundStyle(ControlColors.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func discomfortRow(_ answer: DiscomfortAnswer) -> some View {
        let isSelected = feedback.discomfort == answer
        let shape = RoundedRectangle(cornerRadius: ControlRadius.small + 2, style: .continuous)

        return Button {
            feedback.discomfort = isSelected ? nil : answer
        } label: {
            HStack {
                Text(answer.rawValue)
                    .font(ControlTypography.body)
                    .foregroundStyle(ControlColors.inkPrimary)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? ControlColors.brandDeep : ControlColors.disabled)
            }
            .padding(.horizontal, ControlSpacing.space4)
            .frame(minHeight: 52)
            .background(isSelected ? ControlColors.tealTint : ControlColors.surfaceLight.opacity(0.93), in: shape)
            .overlay(shape.strokeBorder(isSelected ? ControlColors.brandDeep : Color.white.opacity(0.7),
                                        lineWidth: isSelected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(answer.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("discomfort-\(answer.rawValue)")
    }

    // MARK: - Helpers

    private func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func spokenDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        let minuteText = minutes == 1 ? "1 minute" : "\(minutes) minutes"
        let secondText = remainder == 1 ? "1 second" : "\(remainder) seconds"
        return minutes > 0 ? "\(minuteText) \(secondText)" : secondText
    }
}

#Preview("Session Complete") {
    SessionCompleteView(summary: .preview, onSave: { _ in })
}
