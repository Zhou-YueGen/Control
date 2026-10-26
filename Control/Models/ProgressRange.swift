import Foundation

/// Progress 页顶部的时间范围。
enum ProgressRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case quarter = "3M"
    case year = "1Y"

    var id: String { rawValue }
    var title: String { rawValue }

    var chartTitle: String {
        switch self {
        case .week: "This Week"
        case .month: "Last 30 Days"
        case .quarter: "Last 3 Months"
        case .year: "Last 12 Months"
        }
    }

    var spokenTitle: String {
        switch self {
        case .week: "this week"
        case .month: "the last 30 days"
        case .quarter: "the last 3 months"
        case .year: "the last 12 months"
        }
    }

    /// 柱状图每根柱子代表的时间长度。
    var barUnit: Calendar.Component {
        switch self {
        case .week, .month: .day
        case .quarter: .weekOfYear
        case .year: .month
        }
    }
}
