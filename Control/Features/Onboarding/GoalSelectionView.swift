import SwiftUI

/// S02 Goal Selection：单选且必选，Recovery 明确标为仅教育内容。
struct GoalSelectionView: View {
    let initialGoal: Goal?
    let onContinue: (Goal) -> Void

    @State private var selection: Goal?

    init(initialGoal: Goal?, onContinue: @escaping (Goal) -> Void) {
        self.initialGoal = initialGoal
        self.onContinue = onContinue
        _selection = State(initialValue: initialGoal)
    }

    var body: some View {
        OnboardingScaffold(
            theme: .goal,
            step: 2,
            title: "What's your main goal?",
            subtitle: "Choose one. You can change it later."
        ) {
            VStack(spacing: ControlSpacing.space3) {
                ForEach(Goal.allCases) { goal in
                    goalCard(goal)
                }
            }
        } footer: {
            PrimaryPillButton(title: "Continue") {
                if let selection { onContinue(selection) }
            }
            .disabled(selection == nil)
            .accessibilityHint(selection == nil ? "Choose a goal first." : "")
            .accessibilityIdentifier("goalContinueButton")
        }
    }

    private func goalCard(_ goal: Goal) -> some View {
        let isSelected = selection == goal
        let shape = RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous)

        return Button {
            selection = goal
        } label: {
            HStack(spacing: ControlSpacing.space3) {
                Image(systemName: goal.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? ControlColors.inkOnDark : ControlColors.brandMint)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(isSelected ? 0.2 : 0.08),
                                in: RoundedRectangle(cornerRadius: ControlRadius.small, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(ControlTypography.cardTitle)
                        .foregroundStyle(ControlColors.inkOnDark)
                    Text(goal.subtitle)
                        .font(ControlTypography.caption)
                        .foregroundStyle(ControlColors.inkOnDarkMuted)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? ControlColors.brandMint : Color.white.opacity(0.45))
                    .accessibilityHidden(true)
            }
            .padding(ControlSpacing.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    shape.fill(LinearGradient(colors: [ControlColors.brandMid, ControlColors.brandDeep],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                } else {
                    shape.fill(ControlColors.surfaceDark.opacity(0.55))
                }
            }
            .overlay(shape.strokeBorder(isSelected ? ControlColors.brandMint : Color.white.opacity(0.14),
                                        lineWidth: isSelected ? 1.5 : 1))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("goal-\(goal.rawValue)")
    }
}

#Preview("Goal Selection") {
    NavigationStack { GoalSelectionView(initialGoal: nil, onContinue: { _ in }) }
}
