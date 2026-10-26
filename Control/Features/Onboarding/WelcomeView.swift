import SwiftUI

/// S01 Welcome：品牌、标语、三条价值点和 Get Started。
/// 底部的远山剪影是授权照片到位之前的占位插画。
struct WelcomeView: View {
    let onGetStarted: () -> Void

    private let valuePoints: [(icon: String, text: String)] = [
        ("figure.mind.and.body", "Guided daily practice"),
        ("book.closed.fill", "Learn the basics first"),
        ("lock.fill", "Private, on your device"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: ControlSpacing.space6) {
                brand
                valueList
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space8)
            .padding(.bottom, ControlSpacing.space6)
        }
        .scrollBounceBehavior(.basedOnSize)
        .fadesUnderStatusBar()
        .safeAreaInset(edge: .bottom) {
            PrimaryPillButton(title: "Get Started", systemImage: "arrow.right", action: onGetStarted)
                .accessibilityIdentifier("getStartedButton")
                .padding(.horizontal, ControlSpacing.screenHorizontal)
                .padding(.bottom, ControlSpacing.space4)
        }
        .background(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                ControlGradientBackground(theme: .welcome)
                WelcomeLandscape()
                    .frame(height: 360)
                    .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var brand: some View {
        VStack(spacing: ControlSpacing.space3) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(colors: [ControlColors.brandMid, ControlColors.brandDeep],
                                   startPoint: .top, endPoint: .bottom)
                )
                .accessibilityHidden(true)
            Text("Control")
                .font(ControlTypography.brandTitle)
                .foregroundStyle(ControlColors.inkPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("Train Control.\nLearn to Relax.")
                .font(ControlTypography.sectionTitle.weight(.medium))
                .foregroundStyle(ControlColors.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var valueList: some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space3) {
            ForEach(valuePoints, id: \.text) { point in
                HStack(spacing: ControlSpacing.space3) {
                    Image(systemName: point.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(ControlColors.brandDeep)
                        .frame(width: 36, height: 36)
                        .background(ControlColors.tealTint.opacity(0.9), in: Circle())
                        .accessibilityHidden(true)
                    Text(point.text)
                        .font(ControlTypography.body.weight(.medium))
                        .foregroundStyle(ControlColors.inkPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ControlSpacing.space2)
    }
}

/// 两层柔和远山与晨光，静态绘制。
private struct WelcomeLandscape: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Ridge(peaks: [0.55, 0.35, 0.5, 0.25, 0.45])
                .fill(LinearGradient(colors: [Color(hex: 0x9DBFD3), Color(hex: 0xC9D9DE)],
                                     startPoint: .top, endPoint: .bottom))
                .opacity(0.7)
            Ridge(peaks: [0.75, 0.6, 0.7, 0.5, 0.68])
                .fill(LinearGradient(colors: [Color(hex: 0x5E8FA0), Color(hex: 0x86B0B5)],
                                     startPoint: .top, endPoint: .bottom))
                .opacity(0.75)
        }
    }
}

/// 用平滑曲线连接的山脊。`peaks` 是每个控制点距顶部的比例。
private struct Ridge: Shape {
    let peaks: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard peaks.count > 1 else { return path }
        let step = rect.width / CGFloat(peaks.count - 1)
        let points = peaks.enumerated().map { CGPoint(x: CGFloat($0.offset) * step, y: rect.height * $0.element) }

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: points[0])
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midX = (previous.x + current.x) / 2
            path.addCurve(to: current,
                          control1: CGPoint(x: midX, y: previous.y),
                          control2: CGPoint(x: midX, y: current.y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview("Welcome") {
    NavigationStack { WelcomeView(onGetStarted: {}) }
}
