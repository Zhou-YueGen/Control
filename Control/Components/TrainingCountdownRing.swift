import SwiftUI

/// 训练倒计时圆环：薄荷色底环 + 渐变进度弧 + 白色圆盘，中间放阶段文字和秒数。
/// 只表示预定的倒计时进度，不代表任何身体测量。`progress` 会被限制在 0...1。
struct TrainingCountdownRing<Content: View>: View {
    let progress: Double
    var tint: [Color] = [ControlColors.brandMint, ControlColors.brandMid, ControlColors.brandDeep]
    var lineWidth: CGFloat = 22
    var isDimmed = false
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(ControlColors.brandMint.opacity(0.35), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(colors: tint, center: .center,
                                    startAngle: .degrees(0), endAngle: .degrees(360)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(isDimmed ? 0.45 : 1)

            Circle()
                .fill(ControlColors.surfaceLight)
                .padding(lineWidth * 0.95)
                .shadow(color: ControlColors.brandDeep.opacity(0.16), radius: 18, y: 8)

            content
                .padding(lineWidth * 2)
        }
        .padding(lineWidth / 2)
    }
}

#Preview("TrainingCountdownRing") {
    ZStack {
        ControlGradientBackground(theme: .training)
        TrainingCountdownRing(progress: 0.7) {
            VStack(spacing: 2) {
                Text("Contract").font(ControlTypography.cardTitle)
                Text("4").font(ControlTypography.timerNumber())
                Text("seconds").font(ControlTypography.secondary)
            }
            .foregroundStyle(ControlColors.inkPrimary)
        }
        .frame(width: 280, height: 280)
    }
}
