import WidgetKit
import SwiftUI

private let appGroupID = "group.com.intaketracker.shared"

private struct ProgressRing: View {
    let fraction: Double
    let trackColor: Color
    let progressColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor.opacity(0.55), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, fraction))))
                .stroke(progressColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        // Avoid clipped stroke in small circular slots.
        .padding(2)
    }
}

private struct BatteryStyleCircularContent: View {
    let iconSystemName: String
    let valueText: String
    let fraction: Double
    let progressColor: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            // Tuned for accessoryCircular: keep a generous inner area to avoid clipping.
            let ringPadding = max(1, s * 0.045)
            let ringLineWidth = max(3, s * 0.11)

            // Keep the icon fully visible: its bottom edge should sit 1px above the
            // widget's bottom clipping boundary.
            let iconSize = max(10, s * 0.22)
            let iconBottomInset: CGFloat = 1

            ZStack {
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.55), style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                    Circle()
                        .trim(from: 0, to: CGFloat(max(0, min(1, fraction))))
                        .stroke(progressColor, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .padding(ringPadding)

                Text(valueText)
                    .font(.system(size: s * 0.46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.25)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .widgetAccentable()
                    .padding(.horizontal, max(2, s * 0.08))

                Image(systemName: iconSystemName)
                    .font(.system(size: iconSize, weight: .semibold, design: .rounded))
                    .widgetAccentable()
                    // Place icon so its *bottom edge* is exactly 1px above the bottom.
                    .position(
                        x: geo.size.width / 2,
                        y: geo.size.height - iconBottomInset - (iconSize / 2)
                    )
            }
        }
    }
}

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
            BatteryStyleCircularContent(
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
            BatteryStyleCircularContent(
                iconSystemName: "cup.and.saucer.fill",
                valueText: entry.total.formatted(.number.precision(.fractionLength(0...1))),
                fraction: entry.fraction,
                progressColor: .brown
            )
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Progress")
        .description("Caffeine ring progress for today.")
        .supportedFamilies([.accessoryCircular])
    }
}
