import SwiftUI

/// 安全信息：一般安全说明和当前的训练访问状态。不做诊断，也不提供解除限制的入口。
/// 文案为草稿，上线前需临床审核。
struct SafetyInformationView: View {
    let preferences: PreferencesStore

    private var status: (title: String, message: String, systemImage: String, tint: Color) {
        if preferences.trainingHold {
            return ("Training paused",
                    "You reported pain or discomfort after a session, so new sessions are paused. Please speak with a doctor or pelvic health professional if symptoms continue.",
                    "pause.circle.fill", ControlColors.danger)
        }
        if !preferences.adultConfirmed {
            return ("Training is for adults 18+",
                    "Guided training is only offered to adults. Educational content stays available.",
                    "lock.fill", ControlColors.danger)
        }
        switch preferences.safetyAccessStatus {
        case .educationOnly:
            return ("Education only",
                    "Based on your answers, guided training isn't offered. Please talk to a healthcare professional about what's right for you.",
                    "book.closed.fill", ControlColors.danger)
        case .notScreened:
            return ("Safety check not completed",
                    "Complete the safety check before starting guided training.",
                    "questionmark.circle.fill", ControlColors.inkSecondary)
        case .noPredefinedFlag:
            return ("Guided training available",
                    "Your answers didn't match any of the app's predefined safety flags. This is not a medical assessment.",
                    "checkmark.circle.fill", ControlColors.success)
        }
    }

    private let guidance: [(title: String, body: String)] = [
        ("Stop if it hurts",
         "Stop practicing if you feel pain, pressure or discomfort, and don't continue until you've spoken with a professional."),
        ("Breathe and stay relaxed",
         "Keep breathing normally. Don't hold your breath or squeeze your stomach, buttocks or thighs."),
        ("When to seek support",
         "Talk to a doctor or pelvic health professional if you have ongoing pain, bladder or bowel problems, symptoms after surgery, or anything that worries you."),
        ("What this app is",
         "Control offers general guided practice and education. It does not diagnose, treat or monitor any condition."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ControlSpacing.space5) {
                Text("Safety Information")
                    .font(ControlTypography.screenTitle)
                    .foregroundStyle(ControlColors.inkOnDark)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .top, spacing: ControlSpacing.space3) {
                    Image(systemName: status.systemImage)
                        .font(.title2)
                        .foregroundStyle(status.tint)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: ControlSpacing.space1) {
                        Text(status.title)
                            .font(ControlTypography.cardTitle)
                            .foregroundStyle(ControlColors.inkPrimary)
                        Text(status.message)
                            .font(ControlTypography.secondary)
                            .foregroundStyle(ControlColors.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(ControlSpacing.space4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ControlColors.surfaceLight,
                            in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("safetyStatusCard")

                VStack(alignment: .leading, spacing: ControlSpacing.space4) {
                    ForEach(guidance, id: \.title) { item in
                        VStack(alignment: .leading, spacing: ControlSpacing.space1) {
                            Text(item.title)
                                .font(ControlTypography.body.weight(.semibold))
                                .foregroundStyle(ControlColors.inkPrimary)
                            Text(item.body)
                                .font(ControlTypography.secondary)
                                .foregroundStyle(ControlColors.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(ControlSpacing.space4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ControlColors.surfaceLight,
                            in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))

                Text("Draft safety content · pending clinical review")
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space2)
            .padding(.bottom, ControlSpacing.space6)
        }
        .fadesUnderStatusBar()
        .background(ControlGradientBackground(theme: .settings))
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Safety Information") {
    NavigationStack { SafetyInformationView(preferences: .inMemory()) }
}
