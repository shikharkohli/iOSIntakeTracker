import WidgetKit
import SwiftUI

private let appGroupID = "group.com.intaketracker.shared"

// MARK: - Entry

private struct RectangularEntry: TimelineEntry {
    let date: Date
    let total: Double
    let target: Double
    let secondary: String
    let relevance: TimelineEntryRelevance?

    var fraction: Double { min(max(0, total / max(target, 0.01)), 1.0) }
}

// MARK: - Providers

private struct WaterRectangularProvider: TimelineProvider {
    func placeholder(in context: Context) -> RectangularEntry {
        RectangularEntry(date: Date(), total: 4, target: 8, secondary: "Halfway there", relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RectangularEntry) -> Void) {
        completion(current(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RectangularEntry>) -> Void) {
        let now = Date()
        completion(Timeline(entries: [current(at: now)], policy: .after(now.addingTimeInterval(15 * 60))))
    }

    private func current(at date: Date) -> RectangularEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let todayStart = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        let storedDayStart = d.double(forKey: "complication.dayStart")
        let total = (storedDayStart == todayStart) ? d.double(forKey: "complication.waterTotal") : 0
        let target = { let v = d.double(forKey: "target.waterGlasses"); return v > 0 ? v : 8 }()
        let lastTs = d.double(forKey: "complication.lastWaterLogged")
        let hoursSince = lastTs > 0 ? (date.timeIntervalSince1970 - lastTs) / 3600.0 : 24
        let behindGoal = total < target
        // Higher relevance when behind goal AND it's been > 2h since last log.
        let score: Float = behindGoal ? Float(min(1.0, hoursSince / 4.0)) : 0.1
        let remaining = max(0, target - total)
        let secondary: String = remaining > 0
            ? "\(Formatting.glasses(remaining)) left"
            : "Goal hit"
        return RectangularEntry(
            date: date,
            total: total,
            target: target,
            secondary: secondary,
            relevance: TimelineEntryRelevance(score: score)
        )
    }
}

private struct CaffeineRectangularProvider: TimelineProvider {
    func placeholder(in context: Context) -> RectangularEntry {
        RectangularEntry(date: Date(), total: 120, target: 400, secondary: "Cutoff 6 PM", relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RectangularEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RectangularEntry>) -> Void) {
        let now = Date()
        let step: TimeInterval = 5 * 60
        let horizon = 12
        let entries = (0..<horizon).map { i in
            entry(at: now.addingTimeInterval(TimeInterval(i) * step))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(TimeInterval(horizon) * step))))
    }

    private func entry(at date: Date) -> RectangularEntry {
        let d = UserDefaults(suiteName: appGroupID) ?? .standard
        let storedLoad = d.double(forKey: "complication.caffeineBodyLoad")
        let storedAt = d.double(forKey: "complication.caffeineBodyLoadAt")
        let halfLife = { let v = d.double(forKey: "complication.caffeineHalfLifeHours"); return v > 0 ? v : CaffeineKinetics.defaultHalfLifeHours }()
        let target = { let v = d.double(forKey: "target.caffeineMg"); return v > 0 ? v : 400 }()
        let load: Double = {
            guard storedLoad > 0, storedAt > 0 else { return 0 }
            return CaffeineKinetics.remainingDose(
                originalDoseMg: storedLoad,
                since: Date(timeIntervalSince1970: storedAt),
                now: date,
                halfLifeHours: halfLife
            )
        }()

        // Relevance: higher as evening approaches AND load is non-trivial.
        let hour = Calendar.current.component(.hour, from: date)
        let nearCutoff = hour >= 14 && hour <= 22
        let loadFactor = min(1.0, load / 50.0)
        let timeFactor: Double = nearCutoff ? min(1.0, Double(hour - 14) / 8.0 + 0.4) : 0.2
        let score = Float(loadFactor * timeFactor)

        let secondary: String
        if load < 1 {
            secondary = "Clear · sleep ready"
        } else if hour >= 18 {
            secondary = "Past 6 PM cutoff"
        } else {
            let hoursToCutoff = 18 - hour
            secondary = "\(hoursToCutoff)h to cutoff"
        }

        return RectangularEntry(
            date: date,
            total: load,
            target: target,
            secondary: secondary,
            relevance: TimelineEntryRelevance(score: score)
        )
    }
}

// MARK: - Views

private struct RectangularContent: View {
    let title: String
    let iconSystemName: String
    let tint: Color
    let valueText: String
    let secondary: String
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: iconSystemName)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(tint)
            .widgetAccentable()

            Text(valueText)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            ProgressView(value: max(0, min(1, fraction)))
                .progressViewStyle(.linear)
                .tint(tint)

            Text(secondary)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Widgets

struct WaterRectangularWidget: Widget {
    let kind = "WaterRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterRectangularProvider()) { entry in
            RectangularContent(
                title: "Water",
                iconSystemName: "drop.fill",
                tint: .blue,
                valueText: "\(entry.total.formatted(.number.precision(.fractionLength(0...1)))) / \(entry.target.formatted(.number.precision(.fractionLength(0))))",
                secondary: entry.secondary,
                fraction: entry.fraction
            )
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/water")!)
        }
        .configurationDisplayName("Water Tile")
        .description("Water progress + remaining glasses. Surfaces in Smart Stack.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct CaffeineRectangularWidget: Widget {
    let kind = "CaffeineRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaffeineRectangularProvider()) { entry in
            RectangularContent(
                title: "Caffeine in body",
                iconSystemName: "cup.and.saucer.fill",
                tint: .brown,
                valueText: "\(Int(entry.total.rounded())) mg",
                secondary: entry.secondary,
                fraction: min(entry.total / max(entry.target, 0.01), 1.0)
            )
            .containerBackground(for: .widget) { }
            .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine Tile")
        .description("Live caffeine body load + sleep cutoff. Surfaces in Smart Stack.")
        .supportedFamilies([.accessoryRectangular])
    }
}
