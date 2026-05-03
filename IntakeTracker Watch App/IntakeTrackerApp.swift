import SwiftUI
import WidgetKit

@main
struct IntakeTrackerWatchApp: App {
    @StateObject private var store = IntakeStore.shared

    init() {
        _ = SyncService.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(store)
                .onOpenURL { url in
                    QuickLogDeepLinkHandler.handle(url: url, store: store)
                }
                .onReceive(store.$entries) { _ in
                    // Reload complication timelines whenever tracked data changes
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
