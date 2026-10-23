import SwiftUI

/// 呼吸/放松引导波形：收缩时轻微聚拢，放松时缓慢展开。
/// 只是节奏引导，不是生物反馈。开启"减弱动态效果"时保持静态。
struct GuidanceWaveView: View {
    /// 0 = 聚拢，1 = 完全展开。
    let openness: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let value = reduceMotion ? 1 : min(max(openness, 0), 1)
        let widthScale = 0.82 + 0.18 * value
        let heightScale = 1.25 - 0.25 * value

        ZStack {
            LensShape()
                .fill(ControlColors.brandMint.opacity(0.22))
                .frame(width: 250, height: 54)
                .offset(y: 8)
            LensShape()
                .fill(LinearGradient(colors: [ControlColors.brandMint.opacity(0.7), ControlColors.brandMid.opacity(0.35)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 200, height: 56)
            LensShape()
                .fill(LinearGradient(colors: [Color.white.opacity(0.7), ControlColors.brandMint.opacity(0.2)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 130, height: 30)
                .offset(y: -6)
        }
        .scaleEffect(x: widthScale, y: heightScale)
        .frame(height: 76)
        .accessibilityHidden(true)
    }
}

/// 上方隆起、下方平缓的透镜形状。
private struct LensShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.72))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY * 0.72),
            control1: CGPoint(x: rect.width * 0.3, y: rect.minY - rect.height * 0.35),
            control2: CGPoint(x: rect.width * 0.7, y: rect.minY - rect.height * 0.35)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY * 0.72),
            control: CGPoint(x: rect.midX, y: rect.maxY * 1.1)
        )
        path.closeSubpath()
        return path
    }
}

#Preview("GuidanceWaveView") {
    ZStack {
        ControlGradientBackground(theme: .training)
        VStack(spacing: 40) {
            GuidanceWaveView(openness: 0)
            GuidanceWaveView(openness: 1)
        }
    }
}
