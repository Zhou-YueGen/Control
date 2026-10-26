import SwiftUI

/// 课程详情：配图、分段正文、要点小结，以及同一分类中的下一课。
struct LessonDetailView: View {
    let lesson: LearnLesson
    let onOpenNext: (LearnLesson) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ControlSpacing.space5) {
                LessonArt(art: lesson.art)
                    .frame(height: 210)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.7)))

                GlassCard {
                    VStack(alignment: .leading, spacing: ControlSpacing.space5) {
                        VStack(alignment: .leading, spacing: ControlSpacing.space2) {
                            Label("\(lesson.category.title) · \(lesson.minutes) min read", systemImage: "clock")
                                .font(ControlTypography.caption.weight(.semibold))
                                .foregroundStyle(ControlColors.brandDeep)
                            Text(lesson.title)
                                .font(ControlTypography.screenTitle)
                                .foregroundStyle(ControlColors.inkPrimary)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("lessonDetailTitle")
                            Text(lesson.summary)
                                .font(ControlTypography.body)
                                .foregroundStyle(ControlColors.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Divider().overlay(ControlColors.separatorLight)
                        ForEach(lesson.sections, id: \.heading) { section in
                            VStack(alignment: .leading, spacing: ControlSpacing.space1) {
                                Text(section.heading)
                                    .font(ControlTypography.cardTitle)
                                    .foregroundStyle(ControlColors.inkPrimary)
                                    .accessibilityAddTraits(.isHeader)
                                Text(section.body)
                                    .font(ControlTypography.body)
                                    .foregroundStyle(ControlColors.inkSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                GlassCard(style: .tinted) {
                    VStack(alignment: .leading, spacing: ControlSpacing.space3) {
                        Label("Remember", systemImage: "lightbulb.fill")
                            .font(ControlTypography.cardTitle)
                            .foregroundStyle(ControlColors.brandDeep)
                        ForEach(lesson.keyPoints, id: \.self) { point in
                            HStack(alignment: .firstTextBaseline, spacing: ControlSpacing.space2) {
                                Image(systemName: "checkmark")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(ControlColors.success)
                                    .accessibilityHidden(true)
                                Text(point)
                                    .font(ControlTypography.secondary)
                                    .foregroundStyle(ControlColors.inkPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("lessonKeyPoints")

                Label("Stop if you feel pain or discomfort, and talk to a professional if you're unsure.",
                      systemImage: "exclamationmark.circle")
                    .font(ControlTypography.secondary)
                    .foregroundStyle(ControlColors.danger)
                    .padding(ControlSpacing.space4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ControlColors.warningSurface,
                                in: RoundedRectangle(cornerRadius: ControlRadius.small, style: .continuous))

                if let next = lesson.next {
                    Button {
                        onOpenNext(next)
                    } label: {
                        HStack(spacing: ControlSpacing.space3) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Next lesson")
                                    .font(ControlTypography.caption)
                                    .foregroundStyle(ControlColors.inkSecondary)
                                Text(next.numberedTitle)
                                    .font(ControlTypography.body.weight(.semibold))
                                    .foregroundStyle(ControlColors.inkPrimary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(ControlColors.brandMid)
                        }
                        .padding(ControlSpacing.space4)
                        .background(ControlColors.surfaceLight.opacity(0.93),
                                    in: RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("lessonNextButton")
                }

                Text("Draft educational content · pending clinical review")
                    .font(ControlTypography.caption)
                    .foregroundStyle(ControlColors.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space2)
            .padding(.bottom, ControlSpacing.space6)
        }
        .fadesUnderStatusBar()
        .background(ControlGradientBackground(theme: .learn))
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Lesson detail") {
    NavigationStack {
        LessonDetailView(lesson: LearnLibrary.whereIsPelvicFloor, onOpenNext: { _ in })
    }
}
