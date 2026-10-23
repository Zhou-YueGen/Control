import SwiftUI

/// 今日训练卡：图标、标题、时长与次数、圆形开始按钮。
/// 训练入口被守卫阻止时，不显示开始按钮，改为说明原因。
struct TodaySessionCard: View {
    let template: TrainingTemplate?
    let gate: AppRouter.GateResult
    var completedToday = 0
    let onStart: () -> Void

    var body: some View {
        GlassCard(padding: ControlSpacing.space4, cornerRadius: ControlRadius.hero) {
            VStack(alignment: .leading, spacing: ControlSpacing.space3) {
                HStack(spacing: ControlSpacing.space3) {
                    icon
                    details
                    Spacer(minLength: 0)
                    if case .allowed = gate {
                        startButton
                    }
                }

                if case .blocked(let reason) = gate {
                    Label(reason, systemImage: "lock.fill")
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.danger)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("trainingBlockedReason")
                } else if completedToday > 0 {
                    Label(completedToday == 1 ? "Completed today" : "Completed \(completedToday) times today",
                          systemImage: "checkmark.circle.fill")
                        .font(ControlTypography.caption)
                        .foregroundStyle(ControlColors.success)
                }
            }
        }
    }

    private var icon: some View {
        Image(systemName: "square.stack.3d.up.fill")
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(
                LinearGradient(colors: [ControlColors.brandMint, ControlColors.brandDeep],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: ControlRadius.small + 4, style: .continuous)
            )
            .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Today's Training")
                .font(ControlTypography.caption)
                .foregroundStyle(ControlColors.brandDeep)
            Text(template?.title ?? "No session available")
                .font(ControlTypography.cardTitle)
                .foregroundStyle(ControlColors.inkPrimary)
            if let template {
                Text("\(Self.durationText(template)) · \(template.repetitions) reps")
                    .font(ControlTypography.secondary)
                    .foregroundStyle(ControlColors.inkSecondary)
                if !template.isApprovedForRelease {
                    Text("Demo · not clinically reviewed")
                        .font(ControlTypography.caption)
                        .foregroundStyle(ControlColors.inkSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var startButton: some View {
        Button(action: onStart) {
            Image(systemName: "play.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [ControlColors.brandMid, ControlColors.brandDeep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
                .shadow(color: ControlColors.brandDeep.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start \(template?.title ?? "session")")
        .accessibilityIdentifier("startTrainingButton")
    }

    static func durationText(_ template: TrainingTemplate) -> String {
        let minutes = max(1, Int((Double(template.totalSeconds) / 60).rounded()))
        return "\(minutes) min"
    }
}

#Preview("TodaySessionCard") {
    ZStack {
        ControlGradientBackground(theme: .home)
        VStack(spacing: ControlSpacing.space4) {
            TodaySessionCard(template: .demoStandard, gate: .allowed) {}
            TodaySessionCard(template: .demoStandard, gate: .allowed, completedToday: 1) {}
            TodaySessionCard(template: .demoStandard,
                             gate: .blocked(reason: "Please stop training and seek professional guidance if symptoms persist.")) {}
        }
        .padding(ControlSpacing.screenHorizontal)
    }
}
