import SwiftUI

/// 按页面使用的渐变主题（DESIGN.md 2.2）。本阶段只实现三屏所需的主题。
enum ControlTheme {
    case home
    case training
    case complete

    var colors: [Color] {
        switch self {
        case .home: [Color(hex: 0x5A86C6), Color(hex: 0x8CBEDC), Color(hex: 0xCFE8EE), Color(hex: 0xEEF1F7)]
        case .training: [Color(hex: 0x165F7F), Color(hex: 0x9EDBD9), Color(hex: 0xF9E9D7)]
        case .complete: [Color(hex: 0x7A8DCB), Color(hex: 0xF4D4CB), Color(hex: 0xFAF0E4)]
        }
    }

    /// 主页按参考图从上到下渐变，其他页面沿对角线渐变。
    var direction: (start: UnitPoint, end: UnitPoint) {
        switch self {
        case .home: (.top, .bottom)
        case .training, .complete: (.topLeading, .bottomTrailing)
        }
    }

    /// 叠加在某个角落的柔和光晕。
    var glow: (color: Color, center: UnitPoint, radius: CGFloat)? {
        switch self {
        case .home: (Color(hex: 0xC7B5DF).opacity(0.8), .topTrailing, 420)
        case .training, .complete: nil
        }
    }

    /// 顶部放白色文字的主题，在最浅的色停处加一层很淡的深色蒙层保证可读性。
    var topScrimOpacity: Double {
        switch self {
        case .home: 0.04
        case .training: 0.10
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
    /// 滚动内容在状态栏下方淡出，背景渐变保持完整，避免文字和时间重叠。
    func fadesUnderStatusBar() -> some View {
        mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: ControlSpacing.space3)
                Rectangle()
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview("Themes") {
    HStack(spacing: 0) {
        ControlGradientBackground(theme: .home)
        ControlGradientBackground(theme: .training)
        ControlGradientBackground(theme: .complete)
    }
}
