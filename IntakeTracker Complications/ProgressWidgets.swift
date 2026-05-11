import WidgetKit
import SwiftUI

struct WaterProgressWidget: Widget {
    let kind = "WaterProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProgressProvider()) { entry in
            CircularRingContent(
                iconSystemName: "drop.fill",
                valueText: entry.total.formatted(.number.precision(.fractionLength(0...1))),
                fraction: entry.fraction,
                progressColor: .blue
            )
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/water")!)
        }
        .configurationDisplayName("Water Progress")
        .description("Water ring progress for today.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct CaffeineProgressWidget: Widget {
    let kind = "CaffeineProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaffeineProgressProvider()) { entry in
            CircularRingContent(
                iconSystemName: "cup.and.saucer.fill",
                valueText: "\(Int(entry.total.rounded()))",
                fraction: entry.fraction,
                progressColor: caffeineColor(for: entry.fraction)
            )
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Progress")
        .description("Caffeine ring progress for today.")
        .supportedFamilies([.accessoryCircular])
    }
}
