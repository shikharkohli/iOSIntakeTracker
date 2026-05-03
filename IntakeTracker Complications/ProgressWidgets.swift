import WidgetKit
import SwiftUI

private let appGroupID = "group.com.intaketracker.shared"

private struct IntakeProgressEntry: TimelineEntry {
    let date: Date
    let total: Double
    let target: Double

    var fraction: Double { min(total / max(target, 0.01), 1.0) }
}

private struct WaterProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> IntakeProgressEntry {
        IntakeProgressEntry(date: Date(), total: 4, target: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (IntakeProgressEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IntakeProgressEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Date().addingTimeInterval(15 * 60))))
    }

    private func current() -> IntakeProgressEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let total = d.double(forKey: "complication.waterTotal")
        let target = { let v = d.double(forKey: "target.waterGlasses"); return v > 0 ? v : 8 }()
        return IntakeProgressEntry(date: Date(), total: total, target: target)
    }
}

private struct CaffeineProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> IntakeProgressEntry {
        IntakeProgressEntry(date: Date(), total: 200, target: 400)
    }

    func getSnapshot(in context: Context, completion: @escaping (IntakeProgressEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IntakeProgressEntry>) -> Void) {
        completion(Timeline(entries: [current()], policy: .after(Date().addingTimeInterval(15 * 60))))
    }

    private func current() -> IntakeProgressEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let total = d.double(forKey: "complication.caffeineTotal")
        let target = { let v = d.double(forKey: "target.caffeineMg"); return v > 0 ? v : 400 }()
        return IntakeProgressEntry(date: Date(), total: total, target: target)
    }
}

struct WaterProgressWidget: Widget {
    let kind = "WaterProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProgressProvider()) { entry in
            Gauge(value: entry.fraction) {
                Image(systemName: "drop.fill")
            } currentValueLabel: {
                Text("\(Int(entry.total.rounded()))")
                    .font(.system(size: 11, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.blue)
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
            Gauge(value: entry.fraction) {
                Image(systemName: "cup.and.saucer.fill")
            } currentValueLabel: {
                Text("\(Int(entry.total.rounded()))")
                    .font(.system(size: 11, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.brown)
            .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Progress")
        .description("Caffeine ring progress for today.")
        .supportedFamilies([.accessoryCircular])
    }
}

