import SwiftUI

/// 语义色板（DESIGN.md 2.1）。页面只使用这里的颜色，不直接写 HEX。
enum ControlColors {
    /// 浅背景上的标题/正文
    static let inkPrimary = Color(hex: 0x0C1F35)
    /// 浅背景上的次要说明
    static let inkSecondary = Color(hex: 0x40556B)
    /// 深色背景标题/正文
    static let inkOnDark = Color.white
    /// 深色背景次要说明
    static let inkOnDarkMuted = Color(hex: 0xDCEAF3)

    /// 主按钮、浅色背景上的强调元素
    static let brandDeep = Color(hex: 0x006D67)
    /// 品牌图标、图形与进度
    static let brandMid = Color(hex: 0x0D9182)
    /// 深色背景高亮、选中标签
    static let brandMint = Color(hex: 0x5BE0BF)
    /// 选中卡片浅青绿底
    static let tealTint = Color(hex: 0xD8F6EF)

    static let ocean = Color(hex: 0x153E76)
    static let sky = Color(hex: 0x69ADD0)
    static let lavender = Color(hex: 0x9C8DD8)
    static let peach = Color(hex: 0xF9E4D4)

    /// 浅主题卡片基底
    static let surfaceLight = Color.white
    /// 深主题非透明备用卡片
    static let surfaceDark = Color(hex: 0x122C4C)
    /// 浅背景分隔线
    static let separatorLight = Color(hex: 0xD8E5EB)

    /// 错误、风险与停止提示（必须配文字）
    static let danger = Color(hex: 0xA52848)
    /// 风险通知信息底色
    static let warningSurface = Color(hex: 0xFFF2E9)
    /// 已完成状态（配符号/文字）
    static let success = Color(hex: 0x087A6B)
    /// 禁用（附原因说明）
    static let disabled = Color(hex: 0xA5B8C1)
}

extension Color {
    /// 用 0xRRGGBB 创建颜色，例如 `Color(hex: 0x006D67)`。
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
