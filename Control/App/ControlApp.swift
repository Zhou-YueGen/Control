import SwiftData
import SwiftUI

@main
struct ControlApp: App {
    private static let container = makeContainer()

    @State private var router = AppRouter(
        store: SessionStore(context: ControlApp.container.mainContext),
        preferences: ControlApp.launchPreferences,
        template: ControlApp.launchTemplate
    )

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
                .preferredColorScheme(.light)
        }
    }

    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    /// UI 测试使用独立的存储空间，不影响开发时手动使用的数据：
    /// `-UITestFreshInstall` 清空后从 Welcome 开始；`-UITestOnboardingDone` 清空后预置引导已完成；
    /// `-UITestKeepStore` 沿用上次测试留下的数据，用于验证重启后状态仍然保留。
    private static var usesUITestStore: Bool {
        #if DEBUG
        ["-UITestFreshInstall", "-UITestOnboardingDone", "-UITestKeepStore"].contains(where: arguments.contains)
        #else
        false
        #endif
    }

    private static var resetsUITestStore: Bool {
        usesUITestStore && !arguments.contains("-UITestKeepStore")
    }

    /// UI 自动化测试传入 `-UITestFastTraining` 时使用极短的演示节奏。
    private static var launchTemplate: TrainingTemplate {
        #if DEBUG
        if arguments.contains("-UITestFastTraining") {
            return .uiTestFast
        }
        #endif
        return .demoStandard
    }

    private static var launchPreferences: PreferencesStore {
        let suite = "ControlUITests"
        guard usesUITestStore, let defaults = UserDefaults(suiteName: suite) else { return PreferencesStore() }
        if resetsUITestStore { defaults.removePersistentDomain(forName: suite) }
        let preferences = PreferencesStore(defaults: defaults)
        if arguments.contains("-UITestOnboardingDone") { preferences.markOnboardingDoneForTesting() }
        return preferences
    }

    /// 训练记录数据库。打不开时退回内存数据库，保证 App 仍可使用。
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([StoredSession.self])
        let configuration: ModelConfiguration
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if usesUITestStore {
            let url = directory.appending(path: "ControlUITests.store")
            if resetsUITestStore {
                for suffix in ["", "-shm", "-wal"] {
                    try? FileManager.default.removeItem(at: URL(filePath: url.path(percentEncoded: false) + suffix))
                }
            }
            configuration = ModelConfiguration(schema: schema, url: url)
        } else {
            configuration = ModelConfiguration(schema: schema)
        }

        if let container = try? ModelContainer(for: schema, configurations: configuration) {
            return container
        }
        return .controlInMemory()
    }
}
