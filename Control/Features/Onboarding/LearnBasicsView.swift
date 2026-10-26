import SwiftUI

/// 入门必修（USER_FLOW 3.5）：四个短单元，全部展开阅读后才能确认。
/// 完成标记只代表用户已阅读，不代表动作正确。文案为草稿，上线前需临床审核。
struct LearnBasicsView: View {
    let onComplete: () -> Void

    struct Lesson: Identifiable {
        let id: String
        let title: String
        let systemImage: String
        let body: String
    }

    static let lessons = [
        Lesson(id: "where", title: "Where is the pelvic floor?", systemImage: "figure.stand",
               body: "The pelvic floor is a group of muscles at the base of your pelvis, between the tailbone and the pubic bone. They help support the bladder and bowel and play a role in sexual function."),
        Lesson(id: "contract", title: "Contract gently, then fully relax", systemImage: "arrow.down.left.and.arrow.up.right",
               body: "Imagine gently lifting and holding as if stopping wind, without squeezing your buttocks, thighs or stomach. Then let go completely. Relaxing fully is just as important as contracting."),
        Lesson(id: "breathe", title: "Breathe naturally and stop if it hurts", systemImage: "wind",
               body: "Keep breathing normally and never hold your breath. Don't practice while urinating. Stop if you feel pain or discomfort."),
        Lesson(id: "support", title: "When to seek professional support", systemImage: "stethoscope",
               body: "Talk to a doctor or pelvic health professional if you have pain, ongoing bladder or bowel problems, symptoms after surgery, or anything that worries you. This app does not diagnose or treat conditions."),
    ]

    @State private var expanded: Set<String> = []
    @State private var read: Set<String> = []

    private var allRead: Bool { read.count == Self.lessons.count }

    var body: some View {
        OnboardingScaffold(
            theme: .learn,
            step: 4,
            title: "Learn the Basics",
            subtitle: "Open each short lesson before your first session."
        ) {
            VStack(spacing: ControlSpacing.space3) {
                ForEach(Self.lessons) { lesson in
                    lessonCard(lesson)
                }
            }

            Text("Draft educational content · pending clinical review")
                .font(ControlTypography.caption)
                .foregroundStyle(ControlColors.inkSecondary)
                .frame(maxWidth: .infinity)
        } footer: {
            VStack(spacing: ControlSpacing.space2) {
                Text("\(read.count) of \(Self.lessons.count) read")
                    .font(ControlTypography.caption.weight(.semibold))
                    .foregroundStyle(ControlColors.inkSecondary)
                    .accessibilityIdentifier("basicsReadCount")
                PrimaryPillButton(title: "I've read the basics", action: onComplete)
                    .disabled(!allRead)
                    .accessibilityHint(allRead ? "" : "Open every lesson first.")
                    .accessibilityIdentifier("basicsDoneButton")
            }
        }
    }

    private func lessonCard(_ lesson: Lesson) -> some View {
        let isExpanded = expanded.contains(lesson.id)
        let isRead = read.contains(lesson.id)

        return GlassCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded { expanded.remove(lesson.id) } else { expanded.insert(lesson.id) }
                    }
                    read.insert(lesson.id)
                } label: {
                    HStack(spacing: ControlSpacing.space3) {
                        Image(systemName: isRead ? "checkmark.circle.fill" : lesson.systemImage)
                            .font(.title3)
                            .foregroundStyle(isRead ? ControlColors.success : ControlColors.brandDeep)
                            .frame(width: 40, height: 40)
                            .background(ControlColors.tealTint, in: Circle())
                            .accessibilityHidden(true)
                        Text(lesson.title)
                            .font(ControlTypography.body.weight(.semibold))
                            .foregroundStyle(ControlColors.inkPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(ControlColors.inkSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .accessibilityHidden(true)
                    }
                    .padding(ControlSpacing.space4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(isRead ? "Read" : "Not read")
                .accessibilityHint(isExpanded ? "Collapse" : "Expand")
                .accessibilityIdentifier("basics-\(lesson.id)")

                if isExpanded {
                    Text(lesson.body)
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, ControlSpacing.space4)
                        .padding(.bottom, ControlSpacing.space4)
                }
            }
        }
    }
}

#Preview("Learn Basics") {
    NavigationStack { LearnBasicsView(onComplete: {}) }
}
