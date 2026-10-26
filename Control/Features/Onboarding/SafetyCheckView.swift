import SwiftUI

/// S03 Health & Safety Check：第一题是 18 岁确认，没有默认答案，全部答完才能继续。
/// 答案只保存在本页的状态中，提交后由 AppRouter 只保存最终结果。
struct SafetyCheckView: View {
    let onSubmit: ([SafetyQuestion.ID: SafetyAnswer]) -> Void

    @State private var answers: [SafetyQuestion.ID: SafetyAnswer] = [:]

    private var isComplete: Bool { SafetyScreening.isComplete(answers) }

    var body: some View {
        OnboardingScaffold(
            theme: .safety,
            step: 3,
            title: "Health & Safety Check",
            subtitle: "A few questions to help decide whether general training is suitable to offer you. This is not a medical assessment."
        ) {
            VStack(spacing: 0) {
                ForEach(Array(SafetyScreening.allQuestions.enumerated()), id: \.element.id) { index, question in
                    if index > 0 {
                        Divider().overlay(ControlColors.separatorLight)
                    }
                    questionRow(question)
                }
            }
            .padding(.horizontal, ControlSpacing.space4)
            .background(ControlColors.surfaceLight,
                        in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))

            GlassCard(style: .dark) {
                HStack(alignment: .top, spacing: ControlSpacing.space3) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(ControlColors.brandMint)
                        .accessibilityHidden(true)
                    Text("If you have pain, ongoing urination problems, recent surgery or other concerns, please talk to a healthcare professional before starting.")
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkOnDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } footer: {
            PrimaryPillButton(title: "Continue") {
                guard isComplete else { return }
                onSubmit(answers)
            }
            .disabled(!isComplete)
            .accessibilityHint(isComplete ? "" : "Answer every question first.")
            .accessibilityIdentifier("safetyContinueButton")
        }
    }

    private func questionRow(_ question: SafetyQuestion) -> some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space2) {
            Text(question.text)
                .font(ControlTypography.body.weight(.medium))
                .foregroundStyle(ControlColors.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: ControlSpacing.space2) {
                    options(for: question)
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: ControlSpacing.space2) {
                    options(for: question)
                }
            }
        }
        .padding(.vertical, ControlSpacing.space3)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func options(for question: SafetyQuestion) -> some View {
        ForEach(question.options) { option in
            let isSelected = answers[question.id] == option
            Button {
                answers[question.id] = option
            } label: {
                Text(option.rawValue)
                    .font(ControlTypography.secondary.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(isSelected ? ControlColors.inkOnDark : ControlColors.inkPrimary)
                    .padding(.horizontal, ControlSpacing.space4)
                    .frame(minHeight: ControlSpacing.hitTargetMin)
                    .background(isSelected ? ControlColors.brandDeep : ControlColors.tealTint.opacity(0.6),
                                in: Capsule())
                    .overlay(Capsule().strokeBorder(isSelected ? ControlColors.brandDeep : ControlColors.separatorLight))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(option.rawValue)
            .accessibilityHint(question.text)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("safety-\(question.id)-\(option.rawValue)")
        }
    }
}

#Preview("Safety Check") {
    NavigationStack { SafetyCheckView(onSubmit: { _ in }) }
}
