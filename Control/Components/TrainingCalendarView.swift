import SwiftUI

/// 训练连续性日历：每天一个圆点，有完成记录的日期亮绿，今天单独描边，未来日期更淡。
/// 可前后切换月份，用于深色背景。
struct TrainingCalendarView: View {
    let calendar: Calendar
    let hasSession: (Date) -> Bool
    var today: Date = .now

    @State private var displayedMonth: Date
    @ScaledMetric(relativeTo: .subheadline) private var dotSize: CGFloat = 14
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(calendar: Calendar, today: Date = .now, hasSession: @escaping (Date) -> Bool) {
        self.calendar = calendar
        self.today = today
        self.hasSession = hasSession
        _displayedMonth = State(initialValue: calendar.dateInterval(of: .month, for: today)?.start ?? today)
    }

    private var locale: Locale { calendar.locale ?? Locale(identifier: "en_US") }

    private var isCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month)
    }

    /// 当月每一天；前面用 nil 补齐到一周的第一天。
    private var cells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let days = (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
        return Array(repeating: nil, count: leading) + days
    }

    private var weekdaySymbols: [String] {
        let symbols = dynamicTypeSize >= .xxLarge
            ? calendar.veryShortStandaloneWeekdaySymbols
            : calendar.shortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private var trainedDaysInMonth: Int {
        cells.compactMap { $0 }.filter(hasSession).count
    }

    var body: some View {
        VStack(spacing: ControlSpacing.space3) {
            header

            let columns = Array(repeating: GridItem(.flexible(), spacing: ControlSpacing.space1), count: 7)
            LazyVGrid(columns: columns, spacing: ControlSpacing.space2) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(ControlTypography.caption.weight(.semibold))
                        .foregroundStyle(ControlColors.inkOnDarkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityHidden(true)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: cellHeight).accessibilityHidden(true)
                    }
                }
            }
        }
    }

    private var cellHeight: CGFloat { min(dotSize, 22) + 14 }

    private var header: some View {
        HStack {
            monthButton(systemImage: "chevron.left", label: "Previous month", offset: -1)
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.abbreviated).year().locale(locale)))
                .font(ControlTypography.cardTitle)
                .foregroundStyle(ControlColors.inkOnDark)
                .accessibilityLabel(displayedMonth.formatted(.dateTime.month(.wide).year().locale(locale)))
                .accessibilityValue(trainedDaysInMonth == 1 ? "1 training day" : "\(trainedDaysInMonth) training days")
                .accessibilityIdentifier("calendarMonthTitle")
            Spacer()
            monthButton(systemImage: "chevron.right", label: "Next month", offset: 1)
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.3 : 1)
        }
    }

    private func monthButton(systemImage: String, label: String, offset: Int) -> some View {
        Button {
            if let month = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
                displayedMonth = month
            }
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(ControlColors.inkOnDark)
                .frame(width: ControlSpacing.hitTargetMin, height: ControlSpacing.hitTargetMin)
        }
        .accessibilityLabel(label)
    }

    private func dayCell(_ day: Date) -> some View {
        let trained = hasSession(day)
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let isFuture = day > today && !isToday
        let size = min(dotSize, 22)

        return Circle()
            .fill(trained ? ControlColors.brandMint : Color.white.opacity(isFuture ? 0.08 : 0.22))
            .frame(width: size, height: size)
            .shadow(color: trained ? ControlColors.brandMint.opacity(0.7) : .clear, radius: 5)
            .overlay {
                if isToday {
                    Circle().strokeBorder(Color.white, lineWidth: 1.5).padding(-4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: cellHeight)
            .accessibilityElement()
            .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(locale)))
            .accessibilityValue([trained ? "Trained" : "No session", isToday ? "Today" : nil]
                .compactMap { $0 }.joined(separator: ", "))
    }
}

#Preview("TrainingCalendarView") {
    ZStack {
        ControlGradientBackground(theme: .progress)
        TrainingCalendarView(calendar: .controlDefault) { date in
            Calendar.controlDefault.component(.day, from: date) % 3 == 0
        }
        .padding(ControlSpacing.screenHorizontal)
    }
}
