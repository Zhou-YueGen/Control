import SwiftUI

/// 每天打开 App 看到的主页（参考图第 4 屏）。所有数字都来自 SessionStore 中的真实记录。
struct HomeView: View {
    let store: SessionStore
    let template: TrainingTemplate?
    let gate: AppRouter.GateResult
    let onStartTraining: () -> Void
    var onOpenProgress: () -> Void = {}

    @State private var selectedDay: SelectedDay?

    private struct SelectedDay: Identifiable, Equatable {
        let date: Date
        var id: String { SessionStore.dayKey(for: date, calendar: .controlDefault) }
    }

    private var calendar: Calendar { store.calendar }
    private var locale: Locale { calendar.locale ?? Locale(identifier: "en_US") }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ControlSpacing.space6) {
                header
                WeeklyCalendarStrip(days: store.week(containing: .now), calendar: calendar,
                                    hasSession: store.hasSession(on:),
                                    onSelect: { selectedDay = SelectedDay(date: $0) })
                TodaySessionCard(template: template, gate: gate,
                                 completedToday: store.sessionsCount(on: .now),
                                 onStart: onStartTraining)
                weeklyProgress
                summaryCards
                encouragement
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space2)
            .padding(.bottom, ControlSpacing.space6)
        }
        .fadesUnderStatusBar()
        .background(ControlGradientBackground(theme: .home))
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day.date, store: store, onOpenProgress: onOpenProgress)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: ControlSpacing.space1) {
            Text(Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().locale(locale)))
                .font(ControlTypography.secondary.weight(.medium))
                .foregroundStyle(ControlColors.inkOnDarkMuted)

            HStack(spacing: ControlSpacing.space2) {
                Text(greeting.text)
                    .font(ControlTypography.screenTitle)
                    .foregroundStyle(ControlColors.inkOnDark)
                Image(systemName: greeting.symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.title2)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Text("A few calm minutes of guided practice.")
                .font(ControlTypography.secondary)
                .foregroundStyle(ControlColors.inkOnDarkMuted)
        }
        .shadow(color: .black.opacity(0.12), radius: 6, y: 1)
    }

    private var greeting: (text: String, symbol: String) {
        switch calendar.component(.hour, from: .now) {
        case 5..<12: ("Good morning", "sun.max.fill")
        case 12..<18: ("Good afternoon", "sun.haze.fill")
        default: ("Good evening", "moon.stars.fill")
        }
    }

    // MARK: - Weekly Progress

    private var weeklyProgress: some View {
        let days = store.week(containing: .now)
        let trainedCount = store.trainingDaysCount(inWeekContaining: .now)

        return GlassCard {
            VStack(alignment: .leading, spacing: ControlSpacing.space3) {
                HStack(alignment: .center, spacing: ControlSpacing.space2) {
                    Button(action: onOpenProgress) {
                        Text("Weekly Progress")
                            .font(ControlTypography.cardTitle)
                            .foregroundStyle(ControlColors.inkPrimary)
                            .frame(maxWidth: .infinity, minHeight: ControlSpacing.hitTargetMin, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens your progress")
                    .accessibilityIdentifier("weeklyProgressHeader")

                    Text("\(trainedCount) / 7 days")
                        .font(ControlTypography.secondary.monospacedDigit())
                        .foregroundStyle(ControlColors.inkSecondary)
                        .padding(.vertical, ControlSpacing.space3)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onOpenProgress)
                        .accessibilityIdentifier("weeklyProgressCount")

                    Button(action: onOpenProgress) {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(ControlColors.inkSecondary)
                            .frame(width: ControlSpacing.hitTargetMin, height: ControlSpacing.hitTargetMin)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open progress")
                }

                ZStack {
                    Rectangle()
                        .fill(ControlColors.separatorLight)
                        .frame(height: 2)
                        .padding(.horizontal, ControlSpacing.space5)
                        .offset(y: -9)
                        .allowsHitTesting(false)
                    HStack(spacing: 0) {
                        ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                            progressDot(day)
                                .frame(maxWidth: .infinity, minHeight: ControlSpacing.hitTargetMin)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedDay = SelectedDay(date: day) }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("weeklyDot-\(index)")
                        }
                    }
                }

                if trainedCount == 0 {
                    Text("No sessions yet. Your first session starts here.")
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkSecondary)
                }
            }
        }
    }

    private func progressDot(_ day: Date) -> some View {
        let trained = store.hasSession(on: day)
        let isToday = calendar.isDateInToday(day)

        return VStack(spacing: ControlSpacing.space1) {
            ZStack {
                if trained {
                    Circle().fill(ControlColors.brandDeep)
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Circle().fill(ControlColors.surfaceLight)
                    Circle().strokeBorder(isToday ? ControlColors.brandMid : ControlColors.separatorLight,
                                          lineWidth: isToday ? 2 : 1.5)
                }
            }
            .frame(width: 24, height: 24)

            Text(day.formatted(.dateTime.weekday(.abbreviated).locale(locale)))
                .font(ControlTypography.caption)
                .foregroundStyle(isToday ? ControlColors.inkPrimary : ControlColors.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).locale(locale)))
        .accessibilityValue(trained ? "Session completed" : "No session")
        .accessibilityHint("Shows sessions for this day")
    }

    // MARK: - Summary

    private var summaryCards: some View {
        HStack(spacing: ControlSpacing.space3) {
            MetricCard(value: "\(store.totalSessions)", label: "Total Sessions")
                .accessibilityIdentifier("totalSessionsMetric")
            MetricCard(value: "\(store.currentStreak())", label: "Day Streak",
                       systemImage: "flame.fill", iconColor: .orange)
            MetricCard(value: "\(store.totalMinutes)", label: "Total Minutes",
                       systemImage: "chart.bar.fill")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var encouragement: some View {
        GlassCard(style: .tinted) {
            HStack(alignment: .top, spacing: ControlSpacing.space3) {
                Image(systemName: "quote.opening")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ControlColors.brandDeep)
                    .accessibilityHidden(true)
                Text("Small steps every day create a lasting habit.")
                    .font(ControlTypography.secondary.weight(.medium))
                    .foregroundStyle(ControlColors.inkPrimary)
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview("Home · With tab bar") {
    RootTabView(router: .previewOnboarded())
}

#Preview("Home · New user") {
    HomeView(store: SessionStore(), template: .demoStandard, gate: .allowed, onStartTraining: {})
}

#Preview("Home · One session") {
    HomeView(store: .previewWithSession(), template: .demoStandard, gate: .allowed, onStartTraining: {})
}

#Preview("Home · Training hold") {
    HomeView(store: SessionStore(), template: .demoStandard,
             gate: .blocked(reason: "Please stop training and seek professional guidance if symptoms persist."),
             onStartTraining: {})
}
