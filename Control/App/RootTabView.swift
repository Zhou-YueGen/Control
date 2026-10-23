import SwiftUI

/// App 根视图：原生 TabView 五个 Tab；训练流程全屏覆盖在上面，不显示 Tab。
struct RootTabView: View {
    @Bindable var router: AppRouter

    var body: some View {
        let gate = router.trainingGate()

        TabView(selection: $router.selectedTab) {
            HomeView(store: router.store, template: router.template, gate: gate,
                     onStartTraining: { router.startTraining() })
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppRouter.Tab.home)

            BlankTabView()
                .tabItem { Label("Learn", systemImage: "book.closed") }
                .tag(AppRouter.Tab.learn)

            TrainEntryView(template: router.template, gate: gate,
                           onStart: { router.startTraining() })
                .tabItem { Label("Train", systemImage: "play.circle") }
                .tag(AppRouter.Tab.train)

            BlankTabView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(AppRouter.Tab.progress)

            BlankTabView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppRouter.Tab.settings)
        }
        .tint(ControlColors.brandDeep)
        .fullScreenCover(isPresented: Binding(
            get: { router.isTrainingFlowPresented },
            set: { isPresented in if !isPresented { router.exitTraining() } }
        )) {
            trainingFlow
        }
    }

    @ViewBuilder
    private var trainingFlow: some View {
        switch router.trainingStep {
        case .training(let sessionID):
            if let template = router.template {
                TrainingView(
                    template: template,
                    store: router.store,
                    sessionID: sessionID,
                    onCompleted: router.finishTraining(with:),
                    onExit: router.exitTraining
                )
                .id(sessionID)
            }
        case .sessionComplete(let summary):
            SessionCompleteView(summary: summary, onSave: router.saveAndContinue(feedback:))
                .transition(.opacity)
        case nil:
            EmptyView()
        }
    }
}

#Preview("Root") {
    RootTabView(router: AppRouter())
}
