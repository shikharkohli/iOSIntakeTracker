import SwiftUI

struct WatchRootView: View {
    enum Page: Hashable {
        case summary
        case water
        case caffeine
        case fullness
        case weight
        case waist
    }

    @Binding var selection: Page

    var body: some View {
        TabView(selection: $selection) {
            WatchSummaryView()
                .tag(Page.summary)
            WatchWaterView()
                .tag(Page.water)
            WatchCaffeineView()
                .tag(Page.caffeine)
            WatchFullnessView()
                .tag(Page.fullness)
        }
        .tabViewStyle(.verticalPage)
    }
}
