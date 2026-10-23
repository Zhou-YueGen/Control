import SwiftUI

/// 间距与尺寸（DESIGN.md 2.4）。
enum ControlSpacing {
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 20
    static let space6: CGFloat = 24
    static let space8: CGFloat = 32

    /// 屏幕左右留白
    static let screenHorizontal: CGFloat = space5
    /// 底部主按钮高度
    static let buttonMinHeight: CGFloat = 54
    /// 所有交互元素的最小点击区
    static let hitTargetMin: CGFloat = 44
}

/// 圆角（DESIGN.md 2.4）。胶囊按钮直接使用 `Capsule()`。
enum ControlRadius {
    /// 单行设置项/标签
    static let small: CGFloat = 12
    /// 大多数内容卡
    static let card: CGFloat = 20
    /// 主要训练/欢迎组件
    static let hero: CGFloat = 28
}
