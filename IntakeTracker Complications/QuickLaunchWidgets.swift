import WidgetKit
import SwiftUI

private struct QuickLaunchEntry: TimelineEntry {
    let date: Date
}

private struct QuickLaunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLaunchEntry { QuickLaunchEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (QuickLaunchEntry) -> Void) {
        completion(QuickLaunchEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLaunchEntry>) -> Void) {
        completion(Timeline(entries: [QuickLaunchEntry(date: Date())], policy: .never))
    }
}

private struct QuickLaunchView: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}

struct WaterQuickLaunchWidget: Widget {
    let kind = "WaterQuickLaunchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLaunchProvider()) { _ in
            QuickLaunchView(title: "Water", systemImage: "drop.fill")
                .widgetURL(URL(string: "intaketracker://quicklog/water?glasses=1")!)
        }
        .configurationDisplayName("Log Water")
        .description("Open the app to quickly log water.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct CaffeineQuickLaunchWidget: Widget {
    let kind = "CaffeineQuickLaunchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLaunchProvider()) { _ in
            QuickLaunchView(title: "Caffeine", systemImage: "cup.and.saucer.fill")
                .widgetURL(URL(string: "intaketracker://quicklog/caffeine?mg=95&note=Coffee")!)
        }
        .configurationDisplayName("Log Caffeine")
        .description("Open the app to quickly log caffeine.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct FullnessQuickLaunchWidget: Widget {
    let kind = "FullnessQuickLaunchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLaunchProvider()) { _ in
            QuickLaunchView(title: "Meal", systemImage: "fork.knife")
                .widgetURL(URL(string: "intaketracker://quicklog/fullness?level=3")!)
        }
        .configurationDisplayName("Log Fullness")
        .description("Open the app to quickly log meal fullness.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

