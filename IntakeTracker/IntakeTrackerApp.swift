import SwiftUI

@main
struct IntakeTrackerApp: App {
    @StateObject private var store = IntakeStore.shared

    init() {
        _ = SyncService.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
