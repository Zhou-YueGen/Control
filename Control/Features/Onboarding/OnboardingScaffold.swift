import SwiftUI

/// 引导页共用外框：渐变背景、右上角步骤进度、标题区、可滚动内容和固定在底部的主按钮。
/// 返回按钮使用系统导航栏，保留左滑返回。
struct OnboardingScaffold<Content: View, Footer: View>: View {
    let theme: ControlTheme
    var step: Int?
    var totalSteps = 4
    let title: String
    var subtitle: String?
    var titleColor: Color = ControlColors.inkOnDark
    var subtitleColor: Color = ControlColors.inkOnDarkMuted
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ControlSpacing.space5) {
                VStack(alignment: .leading, spacing: ControlSpacing.space2) {
                    Text(title)
                        .font(ControlTypography.screenTitle)
                        .foregroundStyle(titleColor)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .font(ControlTypography.secondary)
                            .foregroundStyle(subtitleColor)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                content
            }
            .padding(.horizontal, ControlSpacing.screenHorizontal)
            .padding(.top, ControlSpacing.space2)
            .padding(.bottom, ControlSpacing.space6)
        }
        .fadesUnderStatusBar()
        .background(ControlGradientBackground(theme: theme))
        .safeAreaInset(edge: .bottom) {
            let bottom = theme.colors.last ?? .clear
            footer
                .padding(.horizontal, ControlSpacing.screenHorizontal)
                .padding(.top, ControlSpacing.space5)
                .padding(.bottom, ControlSpacing.space2)
                .background(
                    LinearGradient(stops: [.init(color: bottom.opacity(0), location: 0),
                                           .init(color: bottom.opacity(0.97), location: 0.3)],
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(false)
                )
        }
        .toolbar {
            if let step {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(step)/\(totalSteps)")
                        .font(ControlTypography.secondary.weight(.semibold).monospacedDigit())
                        .foregroundStyle(titleColor)
                        .accessibilityLabel("Step \(step) of \(totalSteps)")
                        .accessibilityIdentifier("onboardingStepIndicator")
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}
