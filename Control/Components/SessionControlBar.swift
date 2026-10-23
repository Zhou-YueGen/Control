import SwiftUI

/// 训练底栏：左侧已完成次数，中间大号开始/暂停/继续按钮，右侧剩余时间。
struct SessionControlBar: View {
    let completedText: String
    let remainingText: String
    let primarySystemImage: String
    let primaryTitle: String
    var isPrimaryEnabled = true
    let onPrimary: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            stat(value: completedText, label: "reps")
                .frame(maxWidth: .infinity)

            VStack(spacing: ControlSpacing.space1) {
                Button(action: onPrimary) {
                    Image(systemName: primarySystemImage)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            LinearGradient(colors: [ControlColors.brandMid, ControlColors.brandDeep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 2))
                        .shadow(color: ControlColors.brandDeep.opacity(0.35), radius: 14, y: 7)
                }
                .buttonStyle(.plain)
                .disabled(!isPrimaryEnabled)
                .accessibilityLabel(primaryTitle)
                .accessibilityIdentifier("trainingPrimaryControl")

                Text(primaryTitle)
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkSecondary)
                    .accessibilityHidden(true)
            }

            stat(value: remainingText, label: "remaining")
                .frame(maxWidth: .infinity)
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(ControlTypography.metricNumber)
                .foregroundStyle(ControlColors.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(ControlTypography.caption)
                .foregroundStyle(ControlColors.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("SessionControlBar") {
    ZStack {
        ControlGradientBackground(theme: .training)
        SessionControlBar(completedText: "3/8", remainingText: "2:30",
                          primarySystemImage: "pause.fill", primaryTitle: "Pause", onPrimary: {})
            .padding(ControlSpacing.screenHorizontal)
    }
}
