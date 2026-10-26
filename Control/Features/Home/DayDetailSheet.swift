import SwiftUI

/// 点击主页日期或本周进度圆点后弹出：这一天完成的训练记录。
struct DayDetailSheet: View {
    let day: Date
    let store: SessionStore
    let onOpenProgress: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var calendar: Calendar { store.calendar }
    private var locale: Locale { calendar.locale ?? Locale(identifier: "en_US") }
    private var sessions: [SessionSummary] { store.sessions(on: day) }
    private var isToday: Bool { calendar.isDateInToday(day) }
    private var isFuture: Bool { calendar.startOfDay(for: day) > calendar.startOfDay(for: .now) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ControlSpacing.space4) {
                    summary

                    if sessions.isEmpty {
                        Text(emptyMessage)
                            .font(ControlTypography.secondary)
                            .foregroundStyle(ControlColors.inkSecondary)
                            .padding(ControlSpacing.space4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ControlColors.surfaceLight,
                                        in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
                            .accessibilityIdentifier("dayDetailEmpty")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                                if index > 0 { Divider().overlay(ControlColors.separatorLight) }
                                SessionHistoryRow(session: session, feedback: store.feedbackBySession[session.id],
                                                  dateFormat: .dateTime.hour().minute(), locale: locale)
                                    .accessibilityIdentifier("dayDetailSessionRow")
                            }
                        }
                        .background(ControlColors.surfaceLight,
                                    in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
                    }

                    Button {
                        dismiss()
                        onOpenProgress()
                    } label: {
                        Label("View all progress", systemImage: "chart.bar.fill")
                            .font(ControlTypography.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: ControlSpacing.hitTargetMin)
                    }
                    .buttonStyle(.bordered)
                    .tint(ControlColors.brandDeep)
                    .accessibilityIdentifier("dayDetailProgressButton")
                }
                .padding(ControlSpacing.screenHorizontal)
            }
            .background(Color(hex: 0xEEF3F8))
            .navigationTitle(day.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(locale)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("dayDetailDoneButton")
                }
            }
        }
        .tint(ControlColors.brandDeep)
    }

    private var summary: some View {
        let seconds = sessions.reduce(0) { $0 + $1.activeDurationSeconds }
        let count = sessions.count
        return HStack(spacing: ControlSpacing.space3) {
            Image(systemName: count > 0 ? "checkmark.circle.fill" : (isFuture ? "calendar" : "circle.dashed"))
                .font(.title)
                .foregroundStyle(count > 0 ? ControlColors.success : ControlColors.inkSecondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(count == 1 ? "1 session" : "\(count) sessions")
                    .font(ControlTypography.cardTitle)
                    .foregroundStyle(ControlColors.inkPrimary)
                Text(isToday ? "Today · \(timeText(seconds)) practiced" : "\(timeText(seconds)) practiced")
                    .font(ControlTypography.secondary)
                    .foregroundStyle(ControlColors.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dayDetailSummary")
    }

    private var emptyMessage: String {
        if isFuture { return "This day hasn't happened yet." }
        if isToday { return "No sessions yet today. Your completed sessions will appear here." }
        return "No sessions were completed on this day."
    }

    private func timeText(_ seconds: Int) -> String {
        if seconds < 60 { return seconds == 1 ? "1 second" : "\(seconds) seconds" }
        let minutes = SessionStore.minutes(fromSeconds: seconds)
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }
}

#Preview("Day detail") {
    DayDetailSheet(day: .now, store: .previewWithSession(), onOpenProgress: {})
}
