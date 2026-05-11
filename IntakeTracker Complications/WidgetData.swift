import WidgetKit
import SwiftUI

let widgetsAppGroupID = "group.com.intaketracker.shared"

struct IntakeProgressEntry: TimelineEntry {
    let date: Date
    let total: Double
    let target: Double

    var fraction: Double { min(total / max(target, 0.01), 1.0) }
}

struct WaterProgressProvider: TimelineProvider {
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
        let d = UserDefaults(suiteName: widgetsAppGroupID) ?? .standard
        let todayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let storedDayStart = d.double(forKey: "complication.dayStart")
        let total = (storedDayStart == todayStart) ? d.double(forKey: "complication.waterTotal") : 0
        let target = { let v = d.double(forKey: "target.waterGlasses"); return v > 0 ? v : 8 }()
        return IntakeProgressEntry(date: Date(), total: total, target: target)
    }
}

struct CaffeineProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> IntakeProgressEntry {
        IntakeProgressEntry(date: Date(), total: 200, target: 400)
    }

    func getSnapshot(in context: Context, completion: @escaping (IntakeProgressEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IntakeProgressEntry>) -> Void) {
        let now = Date()
        let step: TimeInterval = 5 * 60
        let horizon = 12
        let entries = (0..<horizon).map { i in
            entry(at: now.addingTimeInterval(TimeInterval(i) * step))
        }
        let refreshAt = now.addingTimeInterval(TimeInterval(horizon) * step)
        completion(Timeline(entries: entries, policy: .after(refreshAt)))
    }

    private func entry(at date: Date) -> IntakeProgressEntry {
        let d = UserDefaults(suiteName: widgetsAppGroupID) ?? .standard
        let storedLoad = d.double(forKey: "complication.caffeineBodyLoad")
        let storedAt = d.double(forKey: "complication.caffeineBodyLoadAt")
        let halfLife = { let v = d.double(forKey: "complication.caffeineHalfLifeHours"); return v > 0 ? v : CaffeineKinetics.defaultHalfLifeHours }()
        let target = { let v = d.double(forKey: "target.caffeineMg"); return v > 0 ? v : 400 }()
        let total: Double = {
            guard storedLoad > 0, storedAt > 0 else { return 0 }
            return CaffeineKinetics.remainingDose(
                originalDoseMg: storedLoad,
                since: Date(timeIntervalSince1970: storedAt),
                now: date,
                halfLifeHours: halfLife
            )
        }()
        return IntakeProgressEntry(date: date, total: total, target: target)
    }
}

func caffeineColor(for ratio: Double) -> Color {
    let t = max(0, min(1, ratio))
    let green = SIMD3<Double>(0.20, 0.78, 0.35)
    let yellow = SIMD3<Double>(0.98, 0.85, 0.20)
    let orange = SIMD3<Double>(0.96, 0.54, 0.17)
    let red = SIMD3<Double>(0.88, 0.20, 0.20)

    let color: SIMD3<Double>
    if t <= 0.5 {
        color = simdMix(green, yellow, t / 0.5)
    } else if t <= 0.8 {
        color = simdMix(yellow, orange, (t - 0.5) / 0.3)
    } else {
        color = simdMix(orange, red, (t - 0.8) / 0.2)
    }
    return Color(red: color.x, green: color.y, blue: color.z)
}

private func simdMix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ t: Double) -> SIMD3<Double> {
    a + (b - a) * SIMD3<Double>(repeating: t)
}

/// Shared circular ring content for `.accessoryCircular`.
struct CircularRingContent: View {
    let iconSystemName: String
    let valueText: String
    let fraction: Double
    let progressColor: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let ringPadding = max(1, s * 0.045)
            let ringLineWidth = max(3, s * 0.11)
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
                    .position(
                        x: geo.size.width / 2,
                        y: geo.size.height - iconBottomInset - (iconSize / 2)
                    )
            }
        }
    }
}
