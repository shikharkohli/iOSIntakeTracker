import SwiftUI

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
        }
    }
}
