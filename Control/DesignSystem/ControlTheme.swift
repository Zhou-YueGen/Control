import SwiftUI

/// 按页面使用的渐变主题（DESIGN.md 2.2）。
enum ControlTheme {
    case welcome
    case goal
    case safety
    case learn
    case home
    case training
    case complete
    case progress
    case settings

    var colors: [Color] {
        switch self {
        case .welcome: [Color(hex: 0xA9CFE4), Color(hex: 0xE7ECE8), Color(hex: 0xFCE6D2)]
        case .goal: [Color(hex: 0x045D68), Color(hex: 0x153C70), Color(hex: 0x42345D)]
        case .safety: [Color(hex: 0x047F77), Color(hex: 0x20538A), Color(hex: 0x615AA0)]
        case .learn: [Color(hex: 0x2B8CAD), Color(hex: 0xB4DED3), Color(hex: 0xEDE9E5)]
        case .home: [Color(hex: 0x5A86C6), Color(hex: 0x8CBEDC), Color(hex: 0xCFE8EE), Color(hex: 0xEEF1F7)]
        case .training: [Color(hex: 0x165F7F), Color(hex: 0x9EDBD9), Color(hex: 0xF9E9D7)]
        case .complete: [Color(hex: 0x7A8DCB), Color(hex: 0xF4D4CB), Color(hex: 0xFAF0E4)]
        case .progress: [Color(hex: 0x102950), Color(hex: 0x18446D), Color(hex: 0x6E627F)]
        case .settings: [Color(hex: 0x326DAA), Color(hex: 0x9589CA), Color(hex: 0xE9E3F0)]
        }
    }

    /// 主页、欢迎页和教学页从上到下渐变，其他页面沿对角线渐变。
    var direction: (start: UnitPoint, end: UnitPoint) {
        switch self {
        case .home, .welcome, .learn, .settings: (.top, .bottom)
        case .goal, .safety, .training, .complete, .progress: (.topLeading, .bottomTrailing)
        }
    }

    /// 叠加在某个角落的柔和光晕。
    var glow: (color: Color, center: UnitPoint, radius: CGFloat)? {
        switch self {
        case .home: (Color(hex: 0xC7B5DF).opacity(0.8), .topTrailing, 420)
        case .welcome: (Color(hex: 0xFFF4E6).opacity(0.7), .center, 360)
        case .goal, .safety, .learn, .training, .complete, .progress, .settings: nil
        }
    }

    /// 顶部放白色文字的主题，在最浅的色停处加一层很淡的深色蒙层保证可读性。
    var topScrimOpacity: Double {
        switch self {
        case .welcome: 0
        case .home: 0.04
        case .goal, .safety, .progress, .settings: 0.08
        case .training, .learn: 0.10
        case .complete: 0.12
        }
    }
}

/// 覆盖整个安全区域的渐变背景。
struct ControlGradientBackground: View {
    let theme: ControlTheme

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.colors, startPoint: theme.direction.start, endPoint: theme.direction.end)
            if let glow = theme.glow {
                RadialGradient(colors: [glow.color, glow.color.opacity(0)],
                               center: glow.center, startRadius: 0, endRadius: glow.radius)
            }
            LinearGradient(
                colors: [Color.black.opacity(theme.topScrimOpacity), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// 状态栏下方加一层很浅的遮罩，避免滚动文字和时间重叠。
    /// 不用 `mask`：蒙层会裁掉 ScrollView 的可滚动高度，页面就滑不动了。
    func fadesUnderStatusBar() -> some View {
        overlay(alignment: .top) {
            LinearGradient(colors: [Color.black.opacity(0.16), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 28)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

#Preview("Themes") {
    HStack(spacing: 0) {
        ControlGradientBackground(theme: .welcome)
        ControlGradientBackground(theme: .goal)
        ControlGradientBackground(theme: .safety)
        ControlGradientBackground(theme: .learn)
        ControlGradientBackground(theme: .home)
        ControlGradientBackground(theme: .training)
        ControlGradientBackground(theme: .complete)
        ControlGradientBackground(theme: .progress)
        ControlGradientBackground(theme: .settings)
    }
}
