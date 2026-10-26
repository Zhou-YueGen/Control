import SwiftUI

/// Train Tab（P0）：唯一的基础训练入口，与首页共用同一个训练守卫。
struct TrainEntryView: View {
    let template: TrainingTemplate?
    let gate: AppRouter.GateResult
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ControlSpacing.space6) {
                VStack(alignment: .leading, spacing: ControlSpacing.space1) {
                    Text("Train")
                        .font(ControlTypography.screenTitle)
                        .foregroundStyle(ControlColors.inkOnDark)
                        .accessibilityAddTraits(.isHeader)
                    Text("One guided session with contract and relax phases.")
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkOnDarkMuted)
                }

                TodaySessionCard(template: template, gate: gate, onStart: onStart)

                if let template {
                    GlassCard {
                        VStack(alignment: .leading, spacing: ControlSpacing.space2) {
                            Text("Session details")
                                .font(ControlTypography.cardTitle)
                                .foregroundStyle(ControlColors.inkPrimary)
                            detailRow("Contract", "\(template.contractionSeconds) seconds")
                            detailRow("Relax", "\(template.relaxationSeconds) seconds")
                            detailRow("Repetitions", "\(template.repetitions)")
                            Text("Stop if you feel pain or discomfort.")
                                .font(ControlTypography.secondary)
                                .foregroundStyle(ControlColors.danger)
                                .padding(.top, ControlSpacing.space1)
                        }
                    }
                }
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space2)
        }
        .background(ControlGradientBackground(theme: .training))
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(ControlColors.inkSecondary)
            Spacer()
            Text(value).foregroundStyle(ControlColors.inkPrimary)
        }
        .font(ControlTypography.body)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Train") {
    TrainEntryView(template: .demoStandard, gate: .allowed, onStart: {})
}
