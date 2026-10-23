import SwiftUI

/// 字体层级（DESIGN.md 2.3）。全部基于系统 Text Style，会随 Dynamic Type 缩放。
enum ControlTypography {
    /// Welcome 品牌名称
    static let brandTitle = Font.system(.largeTitle, weight: .bold)
    /// 一级标题
    static let screenTitle = Font.system(.title, weight: .bold)
    /// 页面分区标题
    static let sectionTitle = Font.system(.title3, weight: .semibold)
    /// 训练卡/课程名
    static let cardTitle = Font.system(.headline, weight: .semibold)
    /// 正文、操作解释
    static let body = Font.system(.body)
    /// 次要文字
    static let secondary = Font.system(.subheadline)
    /// 图表辅助标注，不放关键医疗提示
    static let caption = Font.system(.caption, weight: .medium)
    /// 指标数字
    static let metricNumber = Font.system(.title, design: .rounded, weight: .bold).monospacedDigit()
    /// 按钮文字
    static let button = Font.system(.headline, weight: .semibold)

    /// 训练秒数。固定字号，避免辅助功能大字号撑破圆环。
    static func timerNumber(size: CGFloat = 72) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }
}
