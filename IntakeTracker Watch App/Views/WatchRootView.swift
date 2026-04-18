import SwiftUI

struct WatchRootView: View {
    var body: some View {
        TabView {
            WatchSummaryView()
            WatchWaterView()
            WatchCaffeineView()
            WatchFullnessView()
            WatchWeightView()
            WatchWaistView()
        }
        .tabViewStyle(.verticalPage)
    }
}
