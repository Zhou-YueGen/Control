import SwiftUI

/// 一条完成记录：模板名、完成时间、自评难度、时长和完成次数。用在浅色卡片上。
struct SessionHistoryRow: View {
    let session: SessionSummary
    let feedback: SessionFeedback?
    var dateFormat: Date.FormatStyle = .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()
    var locale = Locale(identifier: "en_US")

    var body: some View {
        HStack(alignment: .top, spacing: ControlSpacing.space3) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(ControlColors.success)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.templateTitle)
                    .font(ControlTypography.body.weight(.semibold))
                    .foregroundStyle(ControlColors.inkPrimary)
                Text(session.completedAt.formatted(dateFormat.locale(locale)))
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkSecondary)
                if let difficulty = feedback?.difficulty {
                    Label("\(difficulty.rawValue) · self-reported", systemImage: difficulty.systemImage)
                        .font(ControlTypography.caption)
                        .foregroundStyle(ControlColors.brandDeep)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%d:%02d", session.activeDurationSeconds / 60, session.activeDurationSeconds % 60))
                    .font(ControlTypography.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(ControlColors.inkPrimary)
                Text("\(session.completedRepetitions)/\(session.totalRepetitions) reps")
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkSecondary)
            }
        }
        .padding(ControlSpacing.space4)
        .accessibilityElement(children: .combine)
    }
}
