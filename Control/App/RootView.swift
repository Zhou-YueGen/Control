import SwiftUI

/// 未完成首次引导时显示引导流程，完成后（包括教育模式）显示五个 Tab 的主界面。
struct RootView: View {
    let router: AppRouter

    var body: some View {
        ZStack {
            if router.preferences.onboardingCompleted {
                RootTabView(router: router)
                    .transition(.opacity)
            } else {
                OnboardingFlowView(router: router)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: router.preferences.onboardingCompleted)
    }
}

#Preview("Root · New user") {
    RootView(router: AppRouter())
}

#Preview("Root · Onboarded") {
    RootView(router: .previewOnboarded())
}
