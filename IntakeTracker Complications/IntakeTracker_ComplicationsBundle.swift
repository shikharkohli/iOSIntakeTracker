import WidgetKit
import SwiftUI

@main
struct IntakeTrackerComplicationsBundle: WidgetBundle {
    var body: some Widget {
        WaterProgressWidget()
        CaffeineProgressWidget()
        WaterRectangularWidget()
        CaffeineRectangularWidget()
        WaterCornerWidget()
        CaffeineCornerWidget()
        WaterInlineWidget()
        CaffeineInlineWidget()
    }
}
