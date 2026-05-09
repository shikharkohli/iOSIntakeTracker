import WidgetKit
import SwiftUI

@main
struct IntakeTrackerComplicationsBundle: WidgetBundle {
    var body: some Widget {
        WaterQuickLaunchWidget()
        CaffeineQuickLaunchWidget()
        FullnessQuickLaunchWidget()
        WaterProgressWidget()
        CaffeineProgressWidget()
    }
}
