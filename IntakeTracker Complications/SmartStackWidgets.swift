import WidgetKit
import SwiftUI

private let smartStackAppGroupID = "group.com.intaketracker.shared"
private let hydrationCadenceHours: Double = 2.0

private struct SmartStackEntry: TimelineEntry {
    let date: Date
    let caffeineMg: Double
    let hoursUntilHydration: Double
    let relevance: TimelineEntryRelevance?
}

private struct SmartStackProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmartStackEntry {
        SmartStackEntry(date: Date(), caffeineMg: 87, hoursUntilHydration: 1.2, relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmartStackEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmartStackEntry>) -> Void) {
        let now = Date()
        let step: TimeInterval = 5 * 60
        let horizon = 12
        let entries = (0..<horizon).map { i in
            entry(at: now.addingTimeInterval(TimeInterval(i) * step))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(TimeInterval(horizon) * step))))
    }

    private func entry(at date: Date) -> SmartStackEntry {
        let d = UserDefaults(suiteName: smartStackAppGroupID) ?? .standard
        let storedLoad = d.double(forKey: "complication.caffeineBodyLoad")
        let storedAt = d.double(forKey: "complication.caffeineBodyLoadAt")
        let halfLife = { let v = d.double(forKey: "complication.caffeineHalfLifeHours"); return v > 0 ? v : CaffeineKinetics.defaultHalfLifeHours }()
        let caffeine: Double = {
            guard storedLoad > 0, storedAt > 0 else { return 0 }
            return CaffeineKinetics.remainingDose(
                originalDoseMg: storedLoad,
                since: Date(timeIntervalSince1970: storedAt),
                now: date,
                halfLifeHours: halfLife
            )
        }()

        let lastWaterTs = d.double(forKey: "complication.lastWaterLogged")
        let hoursSinceWater = lastWaterTs > 0 ? (date.timeIntervalSince1970 - lastWaterTs) / 3600.0 : hydrationCadenceHours
        let hoursUntil = max(0, hydrationCadenceHours - hoursSinceWater)

        let overdueWeight = min(1.0, max(0, hoursSinceWater - hydrationCadenceHours) / 2.0)
        let caffeineWeight = min(1.0, caffeine / 100.0)
        let score = Float(max(overdueWeight, caffeineWeight * 0.5))

        return SmartStackEntry(
            date: date,
            caffeineMg: caffeine,
            hoursUntilHydration: hoursUntil,
            relevance: TimelineEntryRelevance(score: score)
        )
    }
}

private struct SmartStackContent: View {
    let entry: SmartStackEntry

    private var hydrationText: String {
        if entry.hoursUntilHydration <= 0 {
            return "Now"
        }
        if entry.hoursUntilHydration < 1 {
            let minutes = Int((entry.hoursUntilHydration * 60).rounded())
            return "\(minutes)m"
        }
        return String(format: "%.1fh", entry.hoursUntilHydration)
    }

    var body: some View {
        HStack(spacing: 10) {
            metricCell(
                glyph: "cup.and.saucer.fill",
                tint: .brown,
                value: "\(Int(entry.caffeineMg.rounded()))",
                unit: "mg",
                caption: "Caffeine"
            )
            Divider()
            metricCell(
                glyph: "drop.fill",
                tint: .blue,
                value: hydrationText,
                unit: "",
                caption: "Hydrate"
            )
        }
    }

    private func metricCell(glyph: String, tint: Color, value: String, unit: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: glyph)
                    .font(.system(size: 10, weight: .semibold))
                Text(caption)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(tint)
            .widgetAccentable()

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SmartStackWidget: Widget {
    let kind = "SmartStackWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmartStackProvider()) { entry in
            SmartStackContent(entry: entry)
                .containerBackground(for: .widget) { }
                .widgetURL(URL(string: "intaketracker://open/caffeine")!)
        }
        .configurationDisplayName("Caffeine + Hydration")
        .description("Live caffeine body load and time to next hydration. Smart Stack tile.")
        .supportedFamilies([.accessoryRectangular])
    }
}
