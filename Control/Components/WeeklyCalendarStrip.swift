import SwiftUI

/// 本周日期条：星期 + 日期，今天用深青绿色块标出，有真实完成记录的日子下方显示小圆点。
/// 用在渐变背景的深色区域，文字为白色。
struct WeeklyCalendarStrip: View {
    let days: [Date]
    let calendar: Calendar
    let hasSession: (Date) -> Bool

    var body: some View {
        HStack(spacing: ControlSpacing.space1) {
            ForEach(days, id: \.self) { day in
                dayCell(day)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let trained = hasSession(day)

        return VStack(spacing: ControlSpacing.space1) {
            Text(day.formatted(.dateTime.weekday(.abbreviated).locale(calendar.locale ?? .current)))
                .font(ControlTypography.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(day.formatted(.dateTime.day().locale(calendar.locale ?? .current)))
                .font(ControlTypography.cardTitle.monospacedDigit())
            Circle()
                .fill(trained ? ControlColors.brandMint : .clear)
                .frame(width: 5, height: 5)
        }
        .foregroundStyle(isToday ? Color.white : ControlColors.inkOnDarkMuted)
        .padding(.vertical, ControlSpacing.space2)
        .frame(maxWidth: .infinity)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: ControlRadius.small, style: .continuous)
                    .fill(LinearGradient(colors: [ControlColors.brandMid, ControlColors.brandDeep],
                                         startPoint: .top, endPoint: .bottom))
                    .shadow(color: ControlColors.brandDeep.opacity(0.35), radius: 8, y: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month(.wide).day()
            .locale(calendar.locale ?? .current)) + (isToday ? ", today" : ""))
        .accessibilityValue(trained ? "Session completed" : "No session")
    }
}

#Preview("WeeklyCalendarStrip") {
    let store = SessionStore.previewWithSession()
    return ZStack {
        ControlGradientBackground(theme: .home)
        WeeklyCalendarStrip(days: store.week(containing: .now), calendar: store.calendar,
                            hasSession: store.hasSession(on:))
            .padding(ControlSpacing.screenHorizontal)
    }
}
