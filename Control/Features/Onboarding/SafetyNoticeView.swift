import SwiftUI

/// 安全分流的条件页：说明为什么不提供训练，引导到教育内容。不做诊断，不提供绕过的开始按钮。
struct SafetyNoticeView: View {
    let reason: SafetyScreening.Reason
    let onAcknowledge: () -> Void

    private var notice: (title: String, message: String) {
        switch reason {
        case .underage:
            ("Training is for adults 18+",
             "Control's guided training is designed for adults. You can still read the general educational content.")
        case .riskAnswer:
            ("Training isn't available based on your answers",
             "Some of your answers mean general training may not be right for you. Please speak with a doctor or pelvic health professional, who can give advice for your situation. You can still explore educational content.")
        case .recoveryGoal:
            ("Recovery support needs your care team",
             "Recovery after surgery or treatment should be guided by your doctor or a pelvic health professional. Control offers general educational content only for this goal.")
        }
    }

    var body: some View {
        OnboardingScaffold(
            theme: .safety,
            title: "Before you continue",
            subtitle: "Your safety comes first."
        ) {
            SafetyNoticeCard(title: notice.title, message: notice.message)
                .accessibilityIdentifier("onboardingSafetyNotice")

            GlassCard(style: .dark) {
                VStack(alignment: .leading, spacing: ControlSpacing.space2) {
                    Label("What you can do in Control", systemImage: "book.closed.fill")
                        .font(ControlTypography.cardTitle)
                        .foregroundStyle(ControlColors.inkOnDark)
                    Text("Read about the pelvic floor, healthy habits and when to seek support. Guided training sessions will stay locked.")
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkOnDarkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } footer: {
            PrimaryPillButton(title: "I understand", action: onAcknowledge)
                .accessibilityIdentifier("safetyNoticeAcknowledgeButton")
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview("Safety Notice · Risk") {
    NavigationStack { SafetyNoticeView(reason: .riskAnswer, onAcknowledge: {}) }
}

#Preview("Safety Notice · Under 18") {
    NavigationStack { SafetyNoticeView(reason: .underage, onAcknowledge: {}) }
}
