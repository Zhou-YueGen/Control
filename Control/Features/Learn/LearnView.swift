import SwiftUI

/// Learn Tab：三个分类，每个分类一篇带配图的置顶课程和一组编号课程，点击进入课程详情。
struct LearnView: View {
    @State private var category: LearnCategory = .basics
    @State private var path: [LearnLesson] = []
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: ControlSpacing.space5) {
                    header
                    categoryPicker
                    featuredCard(category.featured)
                    VStack(spacing: ControlSpacing.space3) {
                        ForEach(category.lessons) { lesson in
                            lessonRow(lesson)
                        }
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
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LearnLesson.self) { lesson in
                LessonDetailView(lesson: lesson) { next in path.append(next) }
            }
        }
        .tint(ControlColors.brandDeep)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: ControlSpacing.space1) {
                Text("Learn")
                    .font(ControlTypography.screenTitle)
                    .foregroundStyle(ControlColors.inkOnDark)
                    .accessibilityAddTraits(.isHeader)
                Text("Learn the basics. Train correctly. Practice safely.")
                    .font(ControlTypography.secondary)
                    .foregroundStyle(ControlColors.inkOnDarkMuted)
            }
            Spacer(minLength: ControlSpacing.space2)
            Image(systemName: "leaf.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [ControlColors.brandMint, ControlColors.brandMid],
                                                startPoint: .top, endPoint: .bottom))
                .accessibilityHidden(true)
        }
    }

    private var categoryPicker: some View {
        HStack(spacing: 0) {
            ForEach(LearnCategory.allCases) { option in
                let isSelected = option == category
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { category = option }
                } label: {
                    Text(dynamicTypeSize >= .xxLarge ? option.shortTitle : option.title)
                        .font(ControlTypography.secondary.weight(.semibold))
                        .foregroundStyle(isSelected ? ControlColors.brandDeep : ControlColors.inkOnDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: dynamicTypeSize < .xxLarge, vertical: false)
                        .padding(.horizontal, ControlSpacing.space3)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if isSelected {
                                Capsule().fill(Color.white).shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("learnTab-\(option.rawValue)")
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.22), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35)))
    }

    // MARK: - Featured lesson

    private func featuredCard(_ lesson: LearnLesson) -> some View {
        Button {
            path.append(lesson)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                LessonArt(art: lesson.art)
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .topLeading) {
                        durationPill(lesson.minutes)
                            .padding(ControlSpacing.space3)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "play.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(
                                LinearGradient(colors: [ControlColors.brandMid, Color(hex: 0x3FC8B4)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: Circle()
                            )
                            .shadow(color: ControlColors.brandDeep.opacity(0.3), radius: 8, y: 4)
                            .padding(ControlSpacing.space4)
                    }

                VStack(alignment: .leading, spacing: ControlSpacing.space2) {
                    Text(lesson.title)
                        .font(ControlTypography.sectionTitle.weight(.bold))
                        .foregroundStyle(ControlColors.inkPrimary)
                    Text(lesson.summary)
                        .font(ControlTypography.secondary)
                        .foregroundStyle(ControlColors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                .padding(ControlSpacing.space4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(ControlColors.surfaceLight.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ControlRadius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.7)))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lesson.title)
        .accessibilityValue("\(lesson.minutes) minute read")
        .accessibilityHint(lesson.summary)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("learnFeaturedCard")
    }

    private func durationPill(_ minutes: Int) -> some View {
        Label("\(minutes) min", systemImage: "clock")
            .font(ControlTypography.caption)
            .foregroundStyle(ControlColors.inkSecondary)
            .padding(.horizontal, ControlSpacing.space2)
            .padding(.vertical, ControlSpacing.space1)
            .background(Color.white.opacity(0.7), in: Capsule())
    }

    // MARK: - Lesson rows

    private func durationLabel(_ minutes: Int) -> some View {
        Label("\(minutes) min", systemImage: "clock")
            .font(ControlTypography.caption)
            .foregroundStyle(ControlColors.inkSecondary)
            .lineLimit(1)
            .fixedSize()
    }

    private func lessonRow(_ lesson: LearnLesson) -> some View {
        Button {
            path.append(lesson)
        } label: {
            HStack(spacing: ControlSpacing.space3) {
                Image(systemName: lesson.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ControlColors.brandDeep)
                    .frame(width: 44, height: 44)
                    .background(ControlColors.tealTint, in: RoundedRectangle(cornerRadius: ControlRadius.small,
                                                                             style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(lesson.numberedTitle)
                        .font(ControlTypography.secondary.weight(.semibold))
                        .foregroundStyle(ControlColors.inkPrimary)
                    Text(lesson.summary)
                        .font(ControlTypography.caption)
                        .foregroundStyle(ControlColors.inkSecondary)
                    if dynamicTypeSize >= .xxLarge {
                        durationLabel(lesson.minutes)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: ControlSpacing.space1)
                if dynamicTypeSize < .xxLarge {
                    durationLabel(lesson.minutes)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ControlColors.inkSecondary)
            }
            .padding(ControlSpacing.space3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ControlColors.surfaceLight.opacity(0.93),
                        in: RoundedRectangle(cornerRadius: ControlRadius.card - 4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ControlRadius.card - 4, style: .continuous)
                .strokeBorder(Color.white.opacity(0.7)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lesson.numberedTitle)
        .accessibilityValue("\(lesson.minutes) minute read")
        .accessibilityHint(lesson.summary)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("learnLesson-\(lesson.id)")
    }
}

#Preview("Learn") {
    LearnView()
}
