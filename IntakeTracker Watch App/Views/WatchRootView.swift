import SwiftUI

struct WatchRootView: View {
    var body: some View {
        TabView {
            WatchWaterView()
            WatchCaffeineView()
            WatchFullnessView()
            WatchWeightView()
            WatchWaistView()
        }
        .tabViewStyle(.verticalPage)
    }
}
