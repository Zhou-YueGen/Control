import SwiftUI

/// 安全提示卡：图标 + 标题 + 正文，不只依靠颜色表达含义。
/// 使用不透明底色，保证在渐变背景上也清晰可读。文案上线前需经临床审核。
struct SafetyNoticeCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: ControlSpacing.space3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(ControlColors.danger)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: ControlSpacing.space1) {
                Text(title)
                    .font(ControlTypography.cardTitle)
                    .foregroundStyle(ControlColors.danger)
                Text(message)
                    .font(ControlTypography.secondary)
                    .foregroundStyle(ControlColors.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(ControlSpacing.space4)
        .background(ControlColors.warningSurface,
                    in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous)
            .strokeBorder(ControlColors.danger.opacity(0.25), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

#Preview("SafetyNoticeCard") {
    ZStack {
        ControlGradientBackground(theme: .complete)
        SafetyNoticeCard(
            title: "Please stop training for now",
            message: "Pain or discomfort can have many causes. If it continues or worries you, consider speaking with a doctor or pelvic health professional."
        )
        .padding(ControlSpacing.screenHorizontal)
    }
}
