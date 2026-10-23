import SwiftUI

/// 指标卡：数字 + 单位/说明 + 可选图标。数字必须来自真实记录。
struct MetricCard: View {
    let value: String
    let label: String
    var systemImage: String? = nil
    var iconColor: Color = ControlColors.brandMid
    var accessibilityValueText: String? = nil

    var body: some View {
        GlassCard(padding: ControlSpacing.space3, cornerRadius: ControlRadius.card - 4) {
            VStack(spacing: ControlSpacing.space1) {
                HStack(spacing: ControlSpacing.space1) {
                    Text(value)
                        .font(ControlTypography.metricNumber)
                        .foregroundStyle(ControlColors.inkPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(iconColor)
                    }
                }
                Text(label)
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValueText ?? value)
    }
}

#Preview("MetricCard") {
    ZStack {
        ControlGradientBackground(theme: .home)
        HStack(spacing: ControlSpacing.space3) {
            MetricCard(value: "0", label: "Total Sessions")
            MetricCard(value: "0", label: "Day Streak", systemImage: "flame.fill", iconColor: .orange)
            MetricCard(value: "0", label: "Total Minutes", systemImage: "chart.bar.fill")
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(ControlSpacing.screenHorizontal)
    }
}
