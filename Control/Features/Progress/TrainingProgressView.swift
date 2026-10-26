import Charts
import SwiftUI

/// S07 Your Progress。所有数字、柱图和日历都来自 SessionStore 中的真实完成记录，没有记录时显示 0。
struct TrainingProgressView: View {
    let store: SessionStore

    @State private var range: ProgressRange = .week
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var calendar: Calendar { store.calendar }
    private var locale: Locale { calendar.locale ?? Locale(identifier: "en_US") }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ControlSpacing.space5) {
                Text("Your Progress")
                    .font(ControlTypography.screenTitle)
                    .foregroundStyle(ControlColors.inkOnDark)
                    .accessibilityAddTraits(.isHeader)
                rangePicker
                metrics
                chartSection
                consistencySection
                if store.totalSessions > 0 {
                    recentSessions
                }
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space2)
            .padding(.bottom, ControlSpacing.space6)
        }
        .fadesUnderStatusBar()
        .background(ControlGradientBackground(theme: .progress))
    }

    // MARK: - Range

    private var rangePicker: some View {
        let options = ProgressRange.allCases
        return HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                let isSelected = option == range
                if index > 0 {
                    let touchesSelection = isSelected || options[index - 1] == range
                    Rectangle()
                        .fill(Color.white.opacity(touchesSelection ? 0 : 0.18))
                        .frame(width: 1, height: 18)
                        .accessibilityHidden(true)
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { range = option }
                } label: {
                    Text(option.title)
                        .font(ControlTypography.secondary.weight(.semibold))
                        .foregroundStyle(isSelected ? ControlColors.inkPrimary : ControlColors.inkOnDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(isSelected ? ControlColors.brandMint : .clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.spokenTitle)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("range-\(option.title)")
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.1), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.14)))
    }

    // MARK: - Metrics

    private var metrics: some View {
        let summary = store.summary(for: range)
        return HStack(spacing: ControlSpacing.space3) {
            metricCard(value: summary.totalSessions, label: "Sessions")
                .accessibilityIdentifier("progressSessionsMetric")
            metricCard(value: summary.totalMinutes, label: "Minutes")
                .accessibilityIdentifier("progressMinutesMetric")
            metricCard(value: store.currentStreak(), label: "Day Streak", systemImage: "flame.fill")
                .accessibilityIdentifier("progressStreakMetric")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func metricCard(value: Int, label: String, systemImage: String? = nil) -> some View {
        GlassCard(style: .dark, padding: ControlSpacing.space3, cornerRadius: ControlRadius.card - 4) {
            VStack(alignment: .leading, spacing: ControlSpacing.space1) {
                HStack(spacing: ControlSpacing.space1) {
                    Text("\(value)")
                        .font(ControlTypography.metricNumber)
                        .foregroundStyle(ControlColors.inkOnDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                }
                Text(label)
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkOnDarkMuted)
                    .lineLimit(label.contains(" ") ? 2 : 1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(range.spokenTitle)")
        .accessibilityValue("\(value)")
    }

    // MARK: - Chart

    private var chartSection: some View {
        let bars = store.chartBars(for: range)
        let summary = store.summary(for: range)
        let maxMinutes = bars.map(\.minutes).max() ?? 0

        return VStack(alignment: .leading, spacing: ControlSpacing.space3) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle(range.chartTitle)
                Spacer()
                Text("minutes")
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkOnDarkMuted)
            }

            GlassCard(style: .dark) {
                Chart(bars) { bar in
                    BarMark(
                        x: .value("Date", bar.date, unit: range.barUnit),
                        y: .value("Minutes", bar.minutes)
                    )
                    .foregroundStyle(LinearGradient(colors: [ControlColors.brandMint, ControlColors.brandMid.opacity(0.85)],
                                                    startPoint: .top, endPoint: .bottom))
                    .cornerRadius(range == .week ? 6 : 3)
                }
                .chartYScale(domain: 0...(maxMinutes > 0 ? maxMinutes * 1.15 : 30))
                .chartXAxis { xAxis }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel().foregroundStyle(ControlColors.inkOnDarkMuted)
                    }
                }
                .environment(\.calendar, calendar)
                .frame(height: 180)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(range.chartTitle) chart")
                .accessibilityValue(chartSummary(summary))
                .accessibilityIdentifier("progressChart")
            }
        }
    }

    private var xAxis: some AxisContent {
        let narrow = dynamicTypeSize >= .xxLarge
        let values: AxisMarkValues
        let format: Date.FormatStyle
        switch range {
        case .week:
            values = .stride(by: .day)
            format = .dateTime.weekday(narrow ? .narrow : .abbreviated)
        case .month:
            values = .stride(by: .day, count: 7)
            format = .dateTime.month(.abbreviated).day()
        case .quarter:
            values = .stride(by: .month)
            format = .dateTime.month(.abbreviated)
        case .year:
            values = .stride(by: .month)
            format = .dateTime.month(.narrow)
        }
        return AxisMarks(values: values) { _ in
            AxisValueLabel(format: format.locale(locale), centered: range == .week || range == .year)
                .foregroundStyle(ControlColors.inkOnDarkMuted)
        }
    }

    private func chartSummary(_ summary: SessionStore.RangeSummary) -> String {
        let sessions = summary.totalSessions == 1 ? "1 session" : "\(summary.totalSessions) sessions"
        let minutes = summary.totalMinutes == 1 ? "1 minute" : "\(summary.totalMinutes) minutes"
        let days = summary.trainingDays == 1 ? "1 training day" : "\(summary.trainingDays) training days"
        return "\(sessions), \(minutes), \(days) in \(range.spokenTitle)"
    }

    // MARK: - Training consistency

    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space3) {
            sectionTitle("Training Consistency")
            GlassCard(style: .dark) {
                TrainingCalendarView(calendar: calendar, hasSession: store.hasSession(on:))
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(ControlTypography.sectionTitle)
            .foregroundStyle(ControlColors.inkOnDark)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Recent sessions

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space3) {
            sectionTitle("Completed Sessions")

            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(store.recentSessions.prefix(20).enumerated()), id: \.element.id) { index, session in
                        if index > 0 { Divider().overlay(ControlColors.separatorLight) }
                        sessionRow(session)
                    }
                }
            }

            if store.totalSessions > 20 {
                Text("Showing the 20 most recent sessions.")
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkOnDarkMuted)
            }
        }
    }

    private func sessionRow(_ session: SessionSummary) -> some View {
        SessionHistoryRow(session: session, feedback: store.feedbackBySession[session.id], locale: locale)
            .accessibilityIdentifier("recentSessionRow")
    }
}

#Preview("Progress · Empty") {
    TrainingProgressView(store: SessionStore())
}

#Preview("Progress · With session") {
    TrainingProgressView(store: .previewWithSession())
}
