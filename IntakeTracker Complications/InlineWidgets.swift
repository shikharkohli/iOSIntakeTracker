import WidgetKit
import SwiftUI

struct WaterInlineWidget: Widget {
    let kind = "WaterInlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProgressProvider()) { entry in
            let remaining = max(0, entry.target - entry.total)
            Label {
                if remaining > 0 {
                    Text("\(entry.total.formatted(.number.precision(.fractionLength(0...1)))) / \(Int(entry.target)) glasses")
                } else {
                    Text("Water goal hit")
                }
            } icon: {
                Image(systemName: "drop.fill")
            }
            .widgetAccentable()
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/water")!)
        }
        .configurationDisplayName("Water Inline")
        .description("Compact water status line.")
        .supportedFamilies([.accessoryInline])
    }
}

struct CaffeineInlineWidget: Widget {
    let kind = "CaffeineInlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaffeineProgressProvider()) { entry in
            Label {
                Text("\(Int(entry.total.rounded())) mg in body")
            } icon: {
                Image(systemName: "cup.and.saucer.fill")
            }
            .widgetAccentable()
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Inline")
        .description("Compact caffeine body load.")
        .supportedFamilies([.accessoryInline])
    }
}
