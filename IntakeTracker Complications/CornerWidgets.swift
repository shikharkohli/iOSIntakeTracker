import WidgetKit
import SwiftUI

struct WaterCornerWidget: Widget {
    let kind = "WaterCornerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProgressProvider()) { entry in
            ZStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .widgetAccentable()
            }
            .widgetLabel {
                Gauge(value: entry.fraction) {
                    Text("Water")
                } currentValueLabel: {
                    Text(entry.total.formatted(.number.precision(.fractionLength(0...1))))
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(Int(entry.target))")
                }
                .tint(.blue)
            }
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/water")!)
        }
        .configurationDisplayName("Water Corner")
        .description("Water progress in watch face corner.")
        .supportedFamilies([.accessoryCorner])
    }
}

struct CaffeineCornerWidget: Widget {
    let kind = "CaffeineCornerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaffeineProgressProvider()) { entry in
            ZStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 14, weight: .bold))
                    .widgetAccentable()
            }
            .widgetLabel {
                Gauge(value: entry.fraction) {
                    Text("Caffeine")
                } currentValueLabel: {
                    Text("\(Int(entry.total.rounded()))")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(Int(entry.target))")
                }
                .tint(caffeineColor(for: entry.fraction))
            }
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Corner")
        .description("Caffeine body load in watch face corner.")
        .supportedFamilies([.accessoryCorner])
    }
}
