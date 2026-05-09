import SwiftUI
import WidgetKit

@main
struct IntakeTrackerWatchApp: App {
    @StateObject private var store = IntakeStore.shared
    @State private var selection: WatchRootView.Page = .summary

    init() {
        _ = SyncService.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView(selection: $selection)
                .environmentObject(store)
                .onOpenURL { url in
                    if let page = WatchDeepLinkRouter.route(url: url) {
                        selection = page
                    }
                }
                .onReceive(store.$entries) { _ in
                    // Reload complication timelines whenever tracked data changes
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
