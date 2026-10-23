import SwiftUI

@main
struct ControlApp: App {
    @State private var router = AppRouter(template: ControlApp.launchTemplate)

    var body: some Scene {
        WindowGroup {
            RootTabView(router: router)
                .preferredColorScheme(.light)
        }
    }

    /// UI 自动化测试传入 `-UITestFastTraining` 时使用极短的演示节奏。
    private static var launchTemplate: TrainingTemplate {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestFastTraining") {
            return .uiTestFast
        }
        #endif
        return .demoStandard
    }
}
